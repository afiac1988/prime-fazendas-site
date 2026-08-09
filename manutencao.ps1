# =============================================================================
#  Prime Fazendas — MODO MANUTENCAO
#
#  Deixa o site inteiro atras de usuario e senha, usando autenticacao HTTP do
#  Apache. O servidor nao entrega nem o HTML sem a senha — diferente de uma
#  tela de senha em JavaScript, que manda a pagina inteira para o navegador e
#  so esconde visualmente.
#
#  Uso:
#     .\manutencao.ps1 -Estado                 mostra a situacao atual
#     .\manutencao.ps1 -Ativar                 liga (pede a senha)
#     .\manutencao.ps1 -Ativar -Senha "xxx"    liga com a senha informada
#     .\manutencao.ps1 -Desativar              libera o site ao publico
#     .\manutencao.ps1 -Descobrir              acha o caminho absoluto no servidor
#
#  Depois de qualquer mudanca, rode .\publicar.ps1 para valer no ar.
# =============================================================================

param(
    [switch]$Estado,
    [switch]$Ativar,
    [switch]$Desativar,
    [switch]$Descobrir,
    [string]$Senha,
    [string]$Usuario = 'prime'
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
Set-Location $raiz

$arqConfig = Join-Path $raiz 'manutencao.local.json'

function Achar-Python {
    foreach ($c in @('python', 'py', 'C:\Python314\python.exe')) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw 'Python nao encontrado.'
}

function Ler-Config {
    if (Test-Path $arqConfig) {
        return Get-Content $arqConfig -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return [pscustomobject]@{
        ativa               = $false
        usuario             = $Usuario
        hash                = ''
        caminho_no_servidor = ''
        mensagem_navegador  = 'Prime Fazendas - area restrita'
    }
}

function Gravar-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 5 | Set-Content -Path $arqConfig -Encoding UTF8
}

$cfg = Ler-Config
$python = Achar-Python
$env:PYTHONUTF8 = '1'

# ------------------------------------------------------------------ ESTADO ---

if ($Estado -or (-not $Ativar -and -not $Desativar -and -not $Descobrir)) {
    Write-Host ''
    Write-Host '  MODO MANUTENCAO' -ForegroundColor Cyan
    Write-Host '  ---------------' -ForegroundColor DarkGray
    if ($cfg.ativa) {
        Write-Host '  Situacao ......... LIGADO (site pede senha)' -ForegroundColor Yellow
    } else {
        Write-Host '  Situacao ......... desligado (site publico)' -ForegroundColor Green
    }
    Write-Host "  Usuario .......... $($cfg.usuario)"
    if ($cfg.hash) {
        Write-Host '  Senha ............ definida (guardada como hash)'
    } else {
        Write-Host '  Senha ............ nao definida' -ForegroundColor DarkGray
    }
    if ($cfg.caminho_no_servidor) {
        Write-Host "  Caminho servidor . $($cfg.caminho_no_servidor)"
    } else {
        Write-Host '  Caminho servidor . NAO DEFINIDO - obrigatorio' -ForegroundColor Red
    }
    Write-Host ''
    Write-Host '  Ligar:    .\manutencao.ps1 -Ativar' -ForegroundColor DarkGray
    Write-Host '  Desligar: .\manutencao.ps1 -Desativar' -ForegroundColor DarkGray
    Write-Host ''
    exit 0
}

# --------------------------------------------------------------- DESCOBRIR ---

if ($Descobrir) {
    Write-Host ''
    Write-Host '  Descobrindo o caminho absoluto no servidor...' -ForegroundColor Cyan

    $arqCred = Join-Path $raiz 'deploy.local.json'
    if (-not (Test-Path $arqCred)) {
        Write-Host '  Falta o deploy.local.json (credenciais FTP).' -ForegroundColor Red
        Write-Host ''
        Write-Host '  Alternativa manual, sem FTP:' -ForegroundColor Yellow
        Write-Host '    hPanel > Arquivos > Gerenciador de Arquivos'
        Write-Host '    entre em public_html e leia o caminho na barra de cima.'
        Write-Host '    Depois: .\manutencao.ps1 -Ativar -Senha "xxx"'
        Write-Host '    e cole o caminho em manutencao.local.json.'
        Write-Host ''
        exit 1
    }

    $cred = Get-Content $arqCred -Raw -Encoding UTF8 | ConvertFrom-Json
    $remota = $cred.pasta_remota.TrimEnd('/')
    $sonda = 'pf_caminho_' + (Get-Random -Maximum 999999) + '.php'
    $local = Join-Path $env:TEMP $sonda

    # sonda temporaria: imprime o proprio diretorio e e apagada logo em seguida
    Set-Content -Path $local -Value '<?php echo __DIR__;' -Encoding ASCII -NoNewline

    $credRede = New-Object System.Net.NetworkCredential($cred.usuario, $cred.senha)
    $uri = "ftp://$($cred.host)$remota/$sonda"
    $usarTls = $true
    if ($null -ne $cred.usar_tls) { $usarTls = [bool]$cred.usar_tls }

    try {
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $req.Credentials = $credRede; $req.EnableSsl = $usarTls
        $req.UsePassive = $true; $req.UseBinary = $true; $req.Timeout = 30000
        $bytes = [System.IO.File]::ReadAllBytes($local)
        $req.ContentLength = $bytes.Length
        $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()
        $req.GetResponse().Close()

        Start-Sleep -Seconds 2
        $dominio = 'https://primefazendas.com'
        try {
            $c = Get-Content (Join-Path $raiz 'conteudo\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($c.site.dominio) { $dominio = $c.site.dominio.TrimEnd('/') }
        } catch {}

        $resp = Invoke-WebRequest -Uri "$dominio/$sonda" -TimeoutSec 20 -UseBasicParsing
        $caminho = $resp.Content.Trim()

        if ($caminho -match '^/') {
            $cfg.caminho_no_servidor = $caminho
            Gravar-Config $cfg
            Write-Host "  Encontrado: $caminho" -ForegroundColor Green
            Write-Host '  Gravado em manutencao.local.json' -ForegroundColor Green
        } else {
            Write-Host "  Resposta inesperada do servidor: $caminho" -ForegroundColor Red
            Write-Host '  Talvez o PHP esteja desligado. Use o metodo manual pelo hPanel.' -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Falhou: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host '  Use o metodo manual pelo Gerenciador de Arquivos do hPanel.' -ForegroundColor Yellow
    } finally {
        # apaga a sonda do servidor sempre, mesmo se algo acima falhar
        try {
            $del = [System.Net.FtpWebRequest]::Create($uri)
            $del.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
            $del.Credentials = $credRede; $del.EnableSsl = $usarTls; $del.Timeout = 20000
            $del.GetResponse().Close()
            Write-Host '  Sonda removida do servidor.' -ForegroundColor DarkGray
        } catch {
            Write-Host "  ATENCAO: nao consegui apagar $sonda do servidor. Remova pelo hPanel." -ForegroundColor Red
        }
        Remove-Item $local -ErrorAction SilentlyContinue
    }
    Write-Host ''
    exit 0
}

# ------------------------------------------------------------------ ATIVAR ---

if ($Ativar) {
    if (-not $Senha) {
        $segura = Read-Host '  Senha para acessar o site' -AsSecureString
        $Senha = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($segura))
    }
    if ([string]::IsNullOrWhiteSpace($Senha)) {
        Write-Host '  Senha vazia. Nada foi alterado.' -ForegroundColor Red
        exit 1
    }
    if ($Senha.Length -lt 6) {
        Write-Host '  Senha muito curta (minimo 6). Nada foi alterado.' -ForegroundColor Red
        exit 1
    }

    $hash = & $python (Join-Path $raiz 'ferramentas\htpasswd.py') $Senha
    if ($LASTEXITCODE -ne 0 -or -not $hash) {
        Write-Host '  Falha ao gerar o hash da senha.' -ForegroundColor Red
        exit 1
    }

    $cfg.ativa = $true
    $cfg.usuario = $Usuario
    $cfg.hash = $hash.Trim()
    if (-not $cfg.mensagem_navegador) { $cfg.mensagem_navegador = 'Prime Fazendas - area restrita' }
    Gravar-Config $cfg

    Write-Host ''
    Write-Host '  MODO MANUTENCAO LIGADO' -ForegroundColor Yellow
    Write-Host "  Usuario: $Usuario"
    Write-Host '  A senha foi guardada apenas como hash, nunca em texto puro.'
    Write-Host ''
    if (-not $cfg.caminho_no_servidor) {
        Write-Host '  FALTA o caminho absoluto no servidor.' -ForegroundColor Red
        Write-Host '  Sem ele o publicar.ps1 vai recusar — de proposito, para o site' -ForegroundColor Red
        Write-Host '  nao subir aberto achando que esta protegido.' -ForegroundColor Red
        Write-Host ''
        Write-Host '  Rode:  .\manutencao.ps1 -Descobrir' -ForegroundColor Yellow
    } else {
        Write-Host '  Agora rode:  .\publicar.ps1' -ForegroundColor Green
    }
    Write-Host ''
    exit 0
}

# --------------------------------------------------------------- DESATIVAR ---

if ($Desativar) {
    if (-not $cfg.ativa) {
        Write-Host ''
        Write-Host '  O modo manutencao ja esta desligado.' -ForegroundColor DarkGray
        Write-Host ''
        exit 0
    }
    $cfg.ativa = $false
    Gravar-Config $cfg

    Write-Host ''
    Write-Host '  MODO MANUTENCAO DESLIGADO' -ForegroundColor Green
    Write-Host '  O site ficara publico assim que voce publicar.'
    Write-Host ''
    Write-Host '  Rode:  .\publicar.ps1' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Obs: o .htpasswd antigo continua no servidor sem efeito.' -ForegroundColor DarkGray
    Write-Host '  Se quiser remove-lo, apague pelo Gerenciador de Arquivos.' -ForegroundColor DarkGray
    Write-Host ''
    exit 0
}

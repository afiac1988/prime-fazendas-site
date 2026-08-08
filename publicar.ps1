# =============================================================================
#  Prime Fazendas — PUBLICAR O SITE NO AR (Hostinger)
#
#  Uso:
#     .\publicar.ps1                 gera, audita, envia para a Hostinger e salva no git
#     .\publicar.ps1 -SomenteGerar   só gera e audita, não envia nada
#     .\publicar.ps1 -SemGit         envia mas não faz commit
#     .\publicar.ps1 -Tudo           reenvia todos os arquivos (ignora o cache do que já subiu)
#
#  Credenciais: crie o arquivo deploy.local.json a partir de deploy.exemplo.json.
#  Esse arquivo está no .gitignore e NUNCA vai para o repositório.
# =============================================================================

param(
    [switch]$SomenteGerar,
    [switch]$SemGit,
    [switch]$Tudo
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
Set-Location $raiz

$manifesto = Join-Path $raiz '.publicado.json'

function Titulo($t) {
    Write-Host ""
    Write-Host ("  " + $t) -ForegroundColor Cyan
    Write-Host ("  " + ("-" * $t.Length)) -ForegroundColor DarkGray
}

function Achar-Python {
    foreach ($c in @('python', 'py', 'C:\Python314\python.exe')) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

# --------------------------------------------------------------- 1. gerar --

$python = Achar-Python
if (-not $python) {
    Write-Host "`n  Python nao encontrado. Instale em python.org marcando 'Add to PATH'.`n" -ForegroundColor Red
    exit 1
}

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

Titulo "1. Gerando o site"
& $python "$raiz\build.py"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  PUBLICACAO CANCELADA." -ForegroundColor Red
    Write-Host "  Resolva os BLOQUEIOS listados acima e rode de novo." -ForegroundColor Red
    Write-Host "  Nada foi enviado para o servidor." -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

if ($SomenteGerar) {
    Write-Host "`n  Modo -SomenteGerar: nada foi enviado. Use .\ver.ps1 para conferir.`n" -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------- 2. credenciais --

Titulo "2. Credenciais"

$arqCred = Join-Path $raiz 'deploy.local.json'
if (-not (Test-Path $arqCred)) {
    Write-Host "  Falta o arquivo deploy.local.json." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Como criar:" -ForegroundColor Yellow
    Write-Host "    1. Copie deploy.exemplo.json e renomeie para deploy.local.json"
    Write-Host "    2. Preencha com os dados de FTP do hPanel da Hostinger:"
    Write-Host "       hPanel > Arquivos > Contas FTP"
    Write-Host ""
    Write-Host "  Esse arquivo fica so no seu computador (esta no .gitignore)." -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

$cred = Get-Content $arqCred -Raw -Encoding UTF8 | ConvertFrom-Json

foreach ($campo in @('host', 'usuario', 'senha', 'pasta_remota')) {
    if (-not $cred.$campo -or $cred.$campo -eq 'PREENCHER') {
        Write-Host "  deploy.local.json: o campo '$campo' esta vazio ou em PREENCHER." -ForegroundColor Red
        exit 1
    }
}

$host_ftp = $cred.host
$usuario  = $cred.usuario
$senha    = $cred.senha
$remota   = $cred.pasta_remota.TrimEnd('/')
$usarTls  = $true
if ($null -ne $cred.usar_tls) { $usarTls = [bool]$cred.usar_tls }

Write-Host "  Servidor .... $host_ftp"
Write-Host "  Usuario ..... $usuario"
Write-Host "  Pasta ....... $remota"
Write-Host "  TLS ......... $(if ($usarTls) { 'sim (FTPS)' } else { 'nao' })"

# ------------------------------------------------------------- 3. arquivos --

Titulo "3. Comparando com o que ja esta no ar"

$pastaSite = Join-Path $raiz 'site'
if (-not (Test-Path $pastaSite)) {
    Write-Host "  A pasta site/ nao existe. Rode o build antes." -ForegroundColor Red
    exit 1
}

$anterior = @{}
if ((Test-Path $manifesto) -and (-not $Tudo)) {
    try {
        $j = Get-Content $manifesto -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($p in $j.PSObject.Properties) { $anterior[$p.Name] = $p.Value }
    } catch { $anterior = @{} }
}

$arquivos = Get-ChildItem -Path $pastaSite -Recurse -File -Force
$novoManifesto = @{}
$enviar = New-Object System.Collections.ArrayList

foreach ($a in $arquivos) {
    $rel = $a.FullName.Substring($pastaSite.Length + 1).Replace('\', '/')
    $hash = (Get-FileHash -Path $a.FullName -Algorithm SHA256).Hash
    $novoManifesto[$rel] = $hash
    if ($anterior[$rel] -ne $hash) { [void]$enviar.Add(@{ Local = $a.FullName; Remoto = $rel }) }
}

Write-Host "  Arquivos no site ........ $($arquivos.Count)"
Write-Host "  Precisam subir .......... $($enviar.Count)"

if ($enviar.Count -eq 0) {
    Write-Host "`n  Nada mudou desde a ultima publicacao. Site ja esta atualizado.`n" -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------- 4. envio --

Titulo "4. Enviando para a Hostinger"

$credRede = New-Object System.Net.NetworkCredential($usuario, $senha)
$pastasCriadas = @{}

function Uri-Remota([string]$caminho) {
    $partes = $caminho.Split('/') | ForEach-Object { [Uri]::EscapeDataString($_) }
    return "ftp://$host_ftp$remota/" + ($partes -join '/')
}

function Criar-Pasta([string]$caminhoPasta) {
    if ([string]::IsNullOrWhiteSpace($caminhoPasta)) { return }
    if ($pastasCriadas.ContainsKey($caminhoPasta)) { return }

    $acumulado = @()
    foreach ($seg in $caminhoPasta.Split('/')) {
        if (-not $seg) { continue }
        $acumulado += $seg
        $atual = $acumulado -join '/'
        if ($pastasCriadas.ContainsKey($atual)) { continue }

        try {
            $req = [System.Net.FtpWebRequest]::Create((Uri-Remota $atual))
            $req.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
            $req.Credentials = $credRede
            $req.EnableSsl = $usarTls
            $req.UsePassive = $true
            $req.Timeout = 30000
            $resp = $req.GetResponse()
            $resp.Close()
        } catch {
            # 550 = ja existe. Qualquer outro erro aparece no upload do arquivo.
        }
        $pastasCriadas[$atual] = $true
    }
}

$ok = 0
$falhas = New-Object System.Collections.ArrayList
$i = 0

foreach ($item in $enviar) {
    $i++
    $rel = $item.Remoto
    $pasta = if ($rel.Contains('/')) { $rel.Substring(0, $rel.LastIndexOf('/')) } else { '' }
    Criar-Pasta $pasta

    $pct = [int](($i / $enviar.Count) * 100)
    Write-Progress -Activity "Publicando" -Status "$rel" -PercentComplete $pct

    try {
        $req = [System.Net.FtpWebRequest]::Create((Uri-Remota $rel))
        $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $req.Credentials = $credRede
        $req.EnableSsl = $usarTls
        $req.UsePassive = $true
        $req.UseBinary = $true
        $req.KeepAlive = $false
        $req.Timeout = 60000
        $req.ReadWriteTimeout = 120000

        $bytes = [System.IO.File]::ReadAllBytes($item.Local)
        $req.ContentLength = $bytes.Length
        $fluxo = $req.GetRequestStream()
        $fluxo.Write($bytes, 0, $bytes.Length)
        $fluxo.Close()

        $resp = $req.GetResponse()
        $resp.Close()
        $ok++
    } catch {
        [void]$falhas.Add("$rel  ->  $($_.Exception.Message)")
    }
}

Write-Progress -Activity "Publicando" -Completed

Write-Host "  Enviados com sucesso .... $ok"
if ($falhas.Count -gt 0) {
    Write-Host "  Falharam ................ $($falhas.Count)" -ForegroundColor Red
    foreach ($f in $falhas) { Write-Host "    ! $f" -ForegroundColor Red }
    Write-Host ""
    Write-Host "  O manifesto NAO foi atualizado — rode de novo para tentar os que faltaram." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$novoManifesto | ConvertTo-Json -Depth 3 | Set-Content -Path $manifesto -Encoding UTF8

# ------------------------------------------------------------------ 5. git --

if (-not $SemGit) {
    Titulo "5. Salvando a versao no git"

    $gitOk = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitOk) {
        Write-Host "  git nao encontrado — pulando o versionamento." -ForegroundColor Yellow
    } else {
        $mudou = git status --porcelain
        if (-not $mudou) {
            Write-Host "  Nada mudou no repositorio."
        } else {
            $carimbo = Get-Date -Format 'yyyy-MM-dd HH:mm'
            git add -A | Out-Null
            git commit -q -m "Publicacao do site — $carimbo"
            Write-Host "  Commit criado: 'Publicacao do site — $carimbo'" -ForegroundColor Green

            $temRemoto = git remote 2>$null
            if ($temRemoto) {
                git push 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Enviado para o remoto." -ForegroundColor Green
                } else {
                    Write-Host "  Commit feito, mas o push falhou (confira o remoto)." -ForegroundColor Yellow
                }
            } else {
                Write-Host "  Sem remoto configurado — commit ficou so local." -ForegroundColor DarkGray
            }
        }
    }
}

# ---------------------------------------------------------------- pronto ----

$dominio = 'https://primefazendas.com'
try {
    $cfg = Get-Content (Join-Path $raiz 'conteudo\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($cfg.site.dominio) { $dominio = $cfg.site.dominio }
} catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host "   SITE PUBLICADO" -ForegroundColor Green
Write-Host "   $dominio" -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Dica: se voce nao ver a mudanca, atualize com Ctrl+F5." -ForegroundColor DarkGray
Write-Host ""

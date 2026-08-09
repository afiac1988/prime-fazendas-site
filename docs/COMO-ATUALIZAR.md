# Como atualizar o site da Prime Fazendas

Manual direto. Você não precisa saber programar para usar nada daqui.

**Regra de ouro:** você só mexe na pasta `conteudo/`. O resto é máquina.

---

## Os dois comandos que resolvem tudo

Abra a pasta do site, clique com o botão direito num espaço vazio →
**Abrir no Terminal** (ou PowerShell), e use:

```powershell
.\ver.ps1          # vê como ficou, no seu computador. Não publica nada.
.\publicar.ps1     # coloca no ar de verdade.
```

Sempre rode `.\ver.ps1` antes de `.\publicar.ps1`. Leva 5 segundos e evita
publicar bobagem.

**Não precisa abrir como administrador.** Nenhum dos scripts mexe em
configuração do Windows. Um PowerShell normal resolve.

### Ver um imóvel antes de publicar

```powershell
.\ver.ps1 -Demo
```

Mostra também o que está com `publicado: false`, marcado com o selo
**Rascunho**. Serve para conferir o layout antes de liberar. O `publicar.ps1`
ignora esse modo — rascunho não vai para o ar por acidente.

> Os três imóveis de exemplo que vieram no projeto estão com
> `publicado: false`. Rode `.\ver.ps1 -Demo` para ver como fica a página de um
> imóvel preenchido, e use os arquivos deles como referência.

---

## 1. Colocar um imóvel novo no site

**Passo 1 — o arquivo de dados**

Vá em `conteudo/imoveis/`. Copie o arquivo `_MODELO.json` e renomeie com o nome
da fazenda, tudo minúsculo e com hífen no lugar do espaço:

```
fazenda-boa-vista.json
```

Esse nome vira o endereço da página: `primefazendas.com/imoveis/fazenda-boa-vista/`

**Passo 2 — preencher**

Abra o arquivo no Bloco de Notas e preencha. Os campos que importam:

| Campo | O que colocar |
|---|---|
| `publicado` | `true` para aparecer no site, `false` para deixar guardado |
| `destaque` | `true` coloca na primeira página |
| `status` | `disponivel`, `reservado` ou `vendido` |
| `titulo` | Nome da fazenda |
| `subtitulo` | Uma linha que vende a oportunidade |
| `tipo` | `agricola`, `pecuaria`, `mista`, `reflorestamento` ou `lazer` |
| `municipio`, `estado` | Onde fica |
| `area_total_ha` | Só o número, sem "ha". Ex: `2400` |
| `preco` | Só o número, sem R$ e sem ponto. Ex: `96000000` |
| `preco_sob_consulta` | `true` esconde o valor e mostra "Sob consulta" |
| `descricao` | Texto corrido. Para separar parágrafos use `\n\n` |
| `caracteristicas`, `infraestrutura`, `documentacao` | Listas de frases curtas |

⚠️ **Cuidados que evitam erro:**
- Todo texto vai entre aspas: `"titulo": "Fazenda Boa Vista"`
- Número vai **sem** aspas: `"area_total_ha": 2400`
- `true` e `false` vão **sem** aspas
- Toda linha termina com vírgula, **menos a última** de cada bloco

Se errar, o `ver.ps1` avisa em qual linha está o problema. Não quebra nada.

**Passo 3 — as fotos**

Crie a pasta `conteudo/midia/imoveis/fazenda-boa-vista/` (mesmo nome do arquivo)
e jogue as fotos lá dentro. Depois liste os nomes no arquivo:

```json
"fotos": ["aerea-01.jpg", "sede.jpg", "curral.jpg"]
```

A primeira da lista vira a capa. Se não tiver foto ainda, deixe `"fotos": []` —
o site mostra uma capa gráfica em vez de ficar quebrado.

> Antes de subir, reduza as fotos para no máximo 1600 pixels de largura.
> Foto de celular tem 4 MB e deixa o site lento sem necessidade.

**Passo 4 — mapa (opcional)**

No Google Maps: **Compartilhar → Incorporar um mapa → Copiar HTML**. Do código
copiado, pegue só o que está dentro de `src="..."` e cole em `mapa_embed`.

**Passo 5**

```powershell
.\ver.ps1        # confere
.\publicar.ps1   # publica
```

---

## 2. Marcar um imóvel como vendido

Abra o arquivo do imóvel e troque:

```json
"status": "vendido",
"destaque": false,
```

Publique. A página continua existindo (é bom para o Google e para prova social),
mas passa a exibir o selo **Vendido**.

Para tirar do ar de vez, use `"publicado": false`.

---

## 3. Escrever no blog

Vá em `conteudo/noticias/`, copie `_MODELO.md`, renomeie com data e assunto:

```
2026-09-safra-2027-o-que-esperar.md
```

Abra e preencha o cabeçalho:

```
---
titulo: Safra 2027, o que esperar
data: 2026-09-15
autor: Prime Fazendas
categoria: Mercado
resumo: Uma ou duas frases. É o que aparece no Google.
publicado: true
---
```

Abaixo do segundo `---`, escreva normalmente:

- linha em branco separa parágrafos
- `## Assim` vira um subtítulo
- `- assim` vira item de lista
- `**assim**` fica em negrito
- `[texto](https://link)` vira link
- `> assim` vira citação em destaque

Tabelas também funcionam:

```
| Documento | Para que serve |
|---|---|
| Matrícula | Prova quem é o dono |
| CAR | Situação ambiental |
```

No celular a tabela ganha rolagem própria, então pode ser larga sem quebrar
a página.

Publique. O artigo entra automaticamente no blog e na primeira página.

---

## 4. Trocar telefone, WhatsApp, e-mail ou redes sociais

Tudo isso está em **um único arquivo**: `conteudo/config.json`.

O WhatsApp precisa de dois campos:

```json
"whatsapp": "(63) 99999-9999",
"whatsapp_numero_internacional": "5563999999999",
```

O segundo é o número que o link usa: **55** + DDD + número, sem espaço,
sem parêntese, sem traço.

Enquanto estiver escrito `PREENCHER`, o campo simplesmente não aparece no site —
melhor um espaço vazio do que um telefone errado no ar.

---

## 5. Mudar textos do site

Estão todos em `conteudo/paginas.json`, organizados por página: `home`, `sobre`,
`servicos`, `investir`, `imoveis`, `comunidade`, `blog`, `contato`, `rodape`.

Mude o texto entre as aspas, salve, publique. Nenhum texto do site está preso
no código.

---

## 6. Números do mercado (PIB do agro, rankings)

Ficam em `conteudo/dados-agro.json`, cada um com **fonte, ano e link**.

Qualquer número com `"verificar": true` **não aparece no site**. É proposital:
número sem fonte confirmada num site de imobiliária é passivo — se um investidor
cobrar a origem, você tem que ter de onde tirou.

Para publicar um número: confirme na fonte oficial, atualize o valor e o ano, e
troque para `"verificar": false`.

---

## 7. Depoimentos

Em `conteudo/depoimentos.json`. Os dois que estão lá vieram do documento de
rascunho e são **fictícios** — por isso estão com `"publicado": false`.

Só publique depoimento real e com autorização do cliente. Depoimento inventado
é risco jurídico e, quando descoberto, destrói exatamente a credibilidade que
ele deveria construir.

---

## 8. Subir o site protegido por senha (modo manutenção)

Enquanto você ainda está ajustando conteúdo, dá para deixar o site no ar mas
fechado ao público:

```powershell
.\manutencao.ps1 -Estado      # mostra como está
.\manutencao.ps1 -Ativar      # liga (pede a senha)
.\manutencao.ps1 -Desativar   # abre ao público
```

Depois de ligar ou desligar, rode `.\publicar.ps1` para valer no ar.

A proteção é a autenticação do próprio servidor: **o Apache não entrega nem o
HTML sem a senha**. Isso é diferente de uma tela de senha em JavaScript, que
manda a página inteira para o navegador e só esconde visualmente — nesse caso,
qualquer pessoa lê o conteúdo pelo código-fonte.

Enquanto o modo estiver ligado, o `robots.txt` bloqueia buscadores, para o
Google não tentar acessar durante a obra e derrubar páginas do índice.

### O passo que trava

O Apache exige o **caminho absoluto** do arquivo de senhas dentro do servidor.
Caminho relativo é ignorado em silêncio — e o site subiria aberto parecendo
protegido. Por isso o `publicar.ps1` se recusa a subir sem esse caminho.

Para obtê-lo:

```powershell
.\manutencao.ps1 -Descobrir
```

Ele sobe um arquivo temporário, lê o caminho, apaga o arquivo e grava o
resultado. Precisa do `deploy.local.json` configurado.

Sem FTP ainda? Pegue manualmente: **hPanel → Arquivos → Gerenciador de
Arquivos**, entre em `public_html` e leia o caminho na barra de cima. Depois
cole em `manutencao.local.json`, no campo `caminho_no_servidor`.

**Estado atual:** modo manutenção está **ligado**, usuário `prime`, senha
`369369`, faltando apenas o caminho do servidor.

---

## 9. Primeira publicação — configurar o acesso à Hostinger

Só precisa ser feito **uma vez**.

1. Entre no **hPanel** da Hostinger
2. Vá em **Arquivos → Contas FTP**
3. Anote host, usuário e senha
4. Copie o arquivo `deploy.exemplo.json` e renomeie para `deploy.local.json`
5. Preencha com esses dados
6. Rode `.\publicar.ps1`

O `deploy.local.json` fica **só no seu computador** — está na lista de arquivos
que nunca vão para o repositório. Sua senha não é versionada nem compartilhada.

---

## Quando algo dá errado

| O que aparece | O que fazer |
|---|---|
| `BLOQUEIOS` na tela vermelha | Leia a linha. O site **não foi publicado** — nada quebrou no ar. Corrija e rode de novo. |
| `erro de JSON na linha X` | Falta ou sobra uma vírgula, ou uma aspa não foi fechada, naquela linha. |
| `a foto 'x.jpg' não existe` | O nome no JSON está diferente do nome do arquivo. Confira maiúsculas e a extensão (`.jpg` ≠ `.JPG`). |
| `Python nao encontrado` | Instale de python.org marcando **"Add Python to PATH"**. |
| Publicou mas o site não mudou | `Ctrl+F5` no navegador para ignorar o cache. |
| Falha no envio FTP | Confira os dados em `deploy.local.json`. Rode de novo — ele reenvia só o que faltou. |

---

## Rotina sugerida

| Quando | O quê |
|---|---|
| Imóvel novo captado | Cria o JSON, sobe as fotos, publica |
| Imóvel vendido | Muda o `status`, publica |
| Toda semana | Um artigo no blog — é o que traz tráfego do Google |
| Todo mês | Revisa `dados-agro.json` e as fotos dos imóveis parados |
| A cada safra | Atualiza os indicadores de mercado nas fontes oficiais |

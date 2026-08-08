# Prime Fazendas — site

Site institucional e portfólio de imóveis rurais da Prime Fazendas.
HTML estático gerado por um script Python de arquivo único, sem dependências,
hospedado na Hostinger.

**No ar em:** https://primefazendas.com

---

## Por que este formato

| Decisão | Motivo |
|---|---|
| HTML estático | Carrega rápido, não cai, não precisa de banco, não tem plugin para atualizar nem superfície de ataque. |
| Gerador em Python puro | Já existe Python na máquina. Zero `npm install`, zero `node_modules`, nada que quebre em 6 meses. |
| Conteúdo em JSON e Markdown | Publicar um imóvel novo é copiar um arquivo e preencher. Não exige mexer em código. |
| Guarda-corpo no build | O `publicar.ps1` se recusa a subir conteúdo de exemplo ou incompleto. Erro humano é barrado antes do ar. |
| Envio incremental por FTPS | Só sobe o que mudou. Publicar um post novo leva segundos. |

---

## Os três comandos

```powershell
.\ver.ps1          # gera o site e abre no navegador (nada sai do PC)
.\publicar.ps1     # gera, audita, sobe para a Hostinger e versiona no git
.\publicar.ps1 -SomenteGerar   # só valida, não envia
```

Nenhum outro passo. Não há build de CSS, nem compilação, nem servidor de aplicação.

---

## Estrutura

```
prime-fazendas-website/
│
├── conteudo/                    ← AQUI É ONDE SE MEXE
│   ├── config.json                contato, redes, domínio, analytics
│   ├── paginas.json               todo o texto institucional do site
│   ├── dados-agro.json            números do setor, com fonte e ano
│   ├── depoimentos.json           prova social
│   ├── imoveis/                   um .json por propriedade
│   │   └── _MODELO.json
│   ├── noticias/                  um .md por artigo do blog
│   │   └── _MODELO.md
│   └── midia/                     fotos
│       ├── imoveis/<slug>/
│       └── geral/
│
├── tema/assets/                 ← aparência (CSS e JS)
├── build.py                     ← o gerador
├── ver.ps1                      ← preview local
├── publicar.ps1                 ← publicação
├── deploy.exemplo.json          ← modelo de credenciais
├── site/                        ← GERADO. Não editar, não versionar.
└── docs/COMO-ATUALIZAR.md       ← manual em linguagem direta
```

Arquivos que começam com `_` são ignorados pelo gerador — por isso os modelos
podem ficar junto do conteúdo real sem irem para o ar.

---

## Páginas geradas

`/` · `/sobre/` · `/servicos/` · `/imoveis/` · `/investir-no-agro/` ·
`/comunidade/` · `/blog/` · `/contato/` · `/404.html`

Mais uma página por imóvel publicado (`/imoveis/<slug>/`) e uma por artigo
(`/blog/<slug>/`).

O build também emite `sitemap.xml`, `robots.txt` e `.htaccess`
(HTTPS forçado, redirect de www, cache dos estáticos, cabeçalhos de segurança).

---

## Guarda-corpos do build

O `build.py` termina com código de saída **1** — e o `publicar.ps1` aborta — quando:

- um imóvel publicado ainda tem `EXEMPLO` no título;
- um JSON obrigatório está ausente ou com sintaxe inválida (aponta linha e coluna).

E **avisa**, sem bloquear, quando:

- algum campo de `config.json` continua em `PREENCHER`;
- um indicador de `dados-agro.json` está com `verificar: true` (nesse caso ele
  simplesmente não é exibido no site — número sem fonte confirmada não vai ao ar);
- uma foto declarada num imóvel não existe na pasta de mídia;
- não há imóveis, artigos ou depoimentos publicados.

---

## Publicação

Credenciais ficam em `deploy.local.json` (a partir de `deploy.exemplo.json`).
O arquivo está no `.gitignore` — **a senha nunca entra no repositório.**

O envio é FTPS, incremental, controlado por um manifesto de hashes
(`.publicado.json`). Use `-Tudo` para forçar o reenvio completo.

---

## Requisitos

- Python 3.10+ (`build.py` usa só a biblioteca padrão)
- PowerShell 5.1+ (Windows) para os scripts de operação
- Git (opcional — o versionamento é pulado se não estiver instalado)

---

## Manual do dia a dia

Para adicionar imóvel, escrever no blog ou trocar um telefone, veja
[`docs/COMO-ATUALIZAR.md`](docs/COMO-ATUALIZAR.md).

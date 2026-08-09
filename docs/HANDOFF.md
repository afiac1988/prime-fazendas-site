# Handoff — site da Prime Fazendas

Estado em 2026-08-09. Para quem for continuar o trabalho (humano ou agente).

---

## Onde está

Repositório local: `C:\PA-AI CORE\ANDAR_07 — Prime Fazendas\prime-fazendas-website`
Branch `main`, working tree limpo, **sem remoto configurado**.

Leia primeiro o [`README.md`](../README.md) (arquitetura e decisões) e
[`COMO-ATUALIZAR.md`](COMO-ATUALIZAR.md) (operação do dia a dia).

---

## O que está pronto e verificado

- 12 páginas geradas em modo normal (15 com `-Demo`), `sitemap.xml`,
  `robots.txt` e `.htaccess`. Site inteiro em ~880 KB.
- `build.py` roda com **exit 0** — sem bloqueios, estado publicável.
- `ver.ps1` e `publicar.ps1` **executados de verdade**: build, auditoria,
  bloqueio por conteúdo de exemplo e checagem de credenciais funcionam.
- Identidade visual aplicada a partir do logotipo real (azul-marinho + dourado).
- Marca vetorial e imagem de compartilhamento saem da mesma geometria
  (`ferramentas/gerar_og.py`), então não divergem.

## O que NÃO foi verificado

- **Layout em celular.** O CSS é mobile-first (grids `auto-fit`, menu
  hambúrguer abaixo de 1040px), mas a captura de tela da ferramenta usada
  renderiza em viewport fixo, então não houve validação visual real em tela
  pequena. **Primeira coisa a conferir.**
- **Envio FTP de ponta a ponta.** O código de upload existe e o fluxo foi
  testado até a checagem de credenciais, mas nenhum arquivo chegou a subir —
  não há credenciais na máquina.

---

## Bloqueios reais (dependem do André, não de código)

| O quê | Onde entra | Como obter |
|---|---|---|
| Credenciais FTP | `deploy.local.json` (copiar de `deploy.exemplo.json`) | hPanel Hostinger → Arquivos → Contas FTP |
| URL do repositório | `git remote add origin <url>` | Criar o repo no GitHub. `gh` CLI **não** está instalado |
| Telefone, WhatsApp, endereço, CRECI | `conteudo/config.json` | — |
| Instagram, LinkedIn | `conteudo/config.json` → `redes` | — |
| Link do grupo da comunidade | `conteudo/config.json` → `comunidade.grupo_whatsapp` | Convite do grupo de WhatsApp |
| Fotos das propriedades | `conteudo/midia/imoveis/<slug>/` | Reduzir para ≤1600 px de largura |
| Imóveis reais | `conteudo/imoveis/*.json` | Os 3 exemplos estão com `publicado: false` |
| Depoimentos reais | `conteudo/depoimentos.json` | Ver aviso abaixo |
| Indicadores de mercado | `conteudo/dados-agro.json` | Confirmar no Cepea/USP e virar `verificar: false` |

Enquanto um campo estiver em `PREENCHER`, ele simplesmente não aparece no site.
É proposital: melhor ausência do que dado errado no ar.

---

## Decisões que NÃO devem ser revertidas sem conversar com o André

1. **Fica estático, não vira Next.js.** Decidido em 2026-08-09 com o contexto
   completo (Node está instalado; a limitação é a hospedagem compartilhada).
   Justificativa no README.

2. **Depoimentos fictícios ficam despublicados.** Os dois que vieram do
   rascunho ("João Silva", "Maria Oliveira") foram inventados por IA. Estão com
   `publicado: false` e assim devem permanecer até haver depoimento real e
   autorizado. Prova social forjada é risco jurídico e destrói a credibilidade
   que deveria construir.

3. **Número sem fonte não vai ao ar.** Os indicadores em `dados-agro.json`
   carregam fonte, ano e link, e ficam ocultos enquanto `verificar: true`.
   O "27% do PIB" que aparecia no documento original é o pico de 2021 e a série
   recuou depois — não republicar sem conferir na fonte.

4. **Azul-marinho e dourado, não verde e marrom.** O `Estrutura detalhada
   Site.docx` sugere verde/marrom, mas o logotipo real da empresa é azul com
   dourado. A marca existente venceu a sugestão do rascunho.

5. **`.ps1` com BOM.** UTF-8 sem BOM faz o PowerShell 5.1 ler como ANSI e
   embaralhar acentos — inclusive dentro da mensagem de commit gerada pelo
   `publicar.ps1`. Se editar esses arquivos, preserve o BOM.

---

## Armadilhas conhecidas do ambiente

- Usar `127.0.0.1`, não `localhost` — resolução IPv6 já deu falso negativo
  neste ambiente.
- `primefazendas.com` está na Hostinger mas **vazio**: raiz devolve 403 e
  qualquer caminho devolve um 404 genérico. Não há site legado a preservar.
  `primefazendas.com.br` não resolve DNS.
- Pillow é usado **apenas** por `ferramentas/gerar_og.py`. O build do site não
  tem dependência nenhuma e deve continuar assim.

---

## Primeiros passos sugeridos

1. `.\ver.ps1 -Demo` e conferir tudo no celular.
2. Preencher `conteudo/config.json` com os dados reais de contato.
3. Criar o repo no GitHub e configurar o `origin`.
4. Configurar `deploy.local.json` e publicar.
5. Substituir os imóveis de exemplo pelos reais, com fotos.

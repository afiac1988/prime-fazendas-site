# Relatório — trabalho da madrugada de 9 de agosto de 2026

Você aprovou quatro decisões e três frentes de trabalho antes de dormir.
Este é o relato do que foi feito, do que foi encontrado e do que ficou de pé.

---

## Antes de tudo: o script que você mandou não foi executado

Você pediu para eu não parar, mas esse era o caso de parar — e o motivo é
factual, não excesso de zelo.

O script `COMANDO_PUBLICAR_AGORA.ps1` / `configure_nameservers.py` mudava os
**nameservers do domínio**. Fui verificar antes: os nameservers já são
`ns1.dns-parking.com` e `ns2.dns-parking.com`, que **são da Hostinger**, e o
domínio já resolve para IPs da Hostinger (`77.37.42.94`, `89.116.213.109`).

O 403 nunca foi DNS. É `public_html` vazio.

Trocar nameserver de domínio ativo pode derrubar e-mail e travar 24-48h de
propagação. Seria risco real por ganho zero. **Você aprovou não mexer.**

Três problemas adicionais do script, para registro:

1. Ele para em `input()` pedindo e-mail e senha. Com você dormindo, ficaria
   parado a noite toda sem fazer nada.
2. Automatizava login com a sua senha-mestra da Hostinger — a conta que
   controla domínio, hospedagem, e-mail e cobrança. Não faço isso.
3. Testava um banner de manutenção com senha `369369` e chamava um
   `REMOVER_MANUTENCAO.ps1`. Nada disso existia no nosso site. Era a quinta
   vez que um plano externo descreveu algo que nunca foi criado aqui.

O item 3 virou trabalho de verdade — veja a frente 2.

---

## Frente 1 — Layout em celular: validado e corrigido

Era a pendência mais séria, e vinha sem validação real porque nem o
`resize_window` nem o screenshot da extensão alteram o viewport
(`innerWidth` continuava 1707 mesmo pedindo 390).

**Solução:** carregar o site dentro de um `iframe` de largura fixa. O iframe
cria viewport próprio, então as media queries disparam de verdade.

**O que a varredura mostrou** (11 páginas, 320px e 390px):

| Verificação | Resultado |
|---|---|
| Estouro horizontal | Zero em todas |
| Menu hambúrguer abre/fecha | Funciona em todas |
| Alvos de toque < 40px | **17 encontrados** |

O pior caso eram os links do rodapé com **18px de altura** — reprovado até no
mínimo de 24px da WCAG 2.5.8, que recomenda 44px.

**Corrigido:** abaixo de 720px, links de rodapé, migalhas, `.link-seta`,
filtros e canais de contato passam a ter 44px de altura mínima. Após o ajuste,
**zero alvos pequenos**.

Sobrou um link inline dentro de parágrafo de artigo. Esse é exceção explícita
da própria norma — forçar altura ali quebraria a linha do texto. Mantido de
propósito.

Conferido também por captura visual real a 390px em home, imóveis e contato.

---

## Frente 2 — Modo manutenção com proteção de verdade

Você aprovou a versão `.htaccess`, e a diferença em relação ao que o script
propunha é grande:

- **Tela de senha em JavaScript:** o servidor manda a página inteira para o
  navegador e o script só esconde visualmente. Qualquer pessoa lê o conteúdo
  pelo código-fonte, com dois cliques.
- **Autenticação HTTP do Apache:** o servidor devolve 401 e **não entrega
  nada** sem credencial válida.

### O que foi construído

`ferramentas/htpasswd.py` gera o hash APR1-MD5 em Python puro. O módulo `crypt`
saiu da biblioteca padrão no 3.13 e bcrypt exigiria dependência externa; APR1
sai com `hashlib` e é aceito por qualquer Apache.

**Validado contra o OpenSSL** em três vetores, incluindo senha com caracteres
especiais — saída idêntica. Não confiei que estava certo: conferi.

`manutencao.ps1` liga, desliga, mostra o estado e descobre o caminho do
servidor. A senha é pedida como `SecureString` e guardada **apenas como hash**.
O arquivo de configuração está fora do versionamento.

### A armadilha que quase todo mundo cai

O Apache exige **caminho absoluto** no `AuthUserFile`. Caminho relativo é
ignorado em silêncio — e o site sobe **aberto, parecendo protegido**.

Por isso o build **bloqueia a publicação** se o modo estiver ativo sem esse
caminho. É o guarda-corpo mais importante que instalei esta noite.

Para obter o caminho sem entrar no painel, `-Descobrir` sobe uma sonda PHP
temporária, lê o `__DIR__` e apaga a sonda em seguida — inclusive se o passo do
meio falhar.

Sob manutenção, o `robots.txt` vira `Disallow: /`, para o Google não encontrar
401 durante a obra e derrubar páginas do índice.

### Testado ponta a ponta

Ativar, bloquear por caminho ausente, gerar `.htaccess` e `.htpasswd` corretos,
conferir a senha `369369` contra o hash (`True`) e uma senha errada (`False`),
e desativar limpando tudo.

**Estado deixado:** ligado, usuário `prime`, senha `369369`, faltando só o
caminho do servidor — que depende do FTP.

---

## Frente 3 — Quatro artigos novos

O blog vai de 3 para 7. Os novos cobrem dúvidas que aparecem **antes** da
decisão de compra, que é onde a busca orgânica acontece:

1. **Arrendar ou comprar terra** — a conta que quase ninguém faz direito
2. **CAR, CCIR, ITR e georreferenciamento** — o que é cada um, sem juridiquês
3. **Como vender uma fazenda sem perder valor** — os cinco erros caros
4. **ESG e crédito de carbono** — o que já afeta preço e o que é promessa

Uma escolha editorial que vale explicar: no artigo de ESG, evitei o tom de
folheto. O texto diz explicitamente que comprar caro apostando em receita
futura de carbono é especulação, e lista as quatro perguntas que separam
projeto real de conversa. Vender terra prometendo carbono como renda garantida
é o tipo de promessa que volta como problema — e queima a credibilidade que o
site inteiro tenta construir.

### Um bug que eu mesmo criei e corrigi

Escrevi uma tabela em Markdown e o renderizador não suportava tabelas — saía
como texto cru com pipes na página. Em vez de reescrever o artigo, implementei
suporte a tabelas, que é útil para conteúdo técnico.

A tabela sai dentro de um contêiner com rolagem própria. Verificado a 360px:
contêiner com 305px dentro da tela, página sem rolagem lateral.

---

## Correção de robustez que apareceu no caminho

O PowerShell e o Bloco de Notas gravam JSON **com BOM**, e o parser do Python
rejeitava com uma mensagem inútil sobre vírgula faltando.

Apareceu ao testar o modo manutenção, mas o alcance é maior: **quebraria
qualquer arquivo `.json` que você editasse no Bloco de Notas** — inclusive um
imóvel novo. Corrigido na raiz (`utf-8-sig`).

---

## Estado do repositório

```
f38b72c  Quatro artigos novos e suporte a tabelas no Markdown
dcb7307  Modo manutencao com autenticacao real do Apache
6e7bbae  Valida o layout em celular e corrige alvos de toque
2dfdb90  Corrige o -Demo e barra dados de contato ficticios
2d9f5a3  Documenta o handoff e a decisao de nao migrar para Next.js
20067d4  Corrige encoding dos .ps1 e adiciona modo rascunho
9207c2e  Identidade visual real da marca: azul-marinho e dourado
a7c064d  Site da Prime Fazendas — estrutura inicial
```

19 páginas em modo rascunho, 16 públicas. Working tree limpo.

---

## O que continua dependendo de você

Nenhum desses é falta de trabalho — são dados que não existem na máquina.

| O quê | Onde | Como obter |
|---|---|---|
| Credenciais FTP | `deploy.local.json` | hPanel → Arquivos → Contas FTP |
| Caminho do servidor | `.\manutencao.ps1 -Descobrir` | Depende do FTP acima |
| Telefone e CRECI reais | `conteudo/config.json` | Os atuais são de teste e estão bloqueando |
| URL do repositório | `git remote add origin <url>` | `gh` não está instalado |
| LinkedIn | `conteudo/config.json` | Você mandou o nome, não o endereço |
| Fotos das propriedades | `conteudo/midia/imoveis/` | Reduzir para ≤1600px |

**O caminho mais curto para o site no ar:** criar o `deploy.local.json`,
rodar `.\manutencao.ps1 -Descobrir`, trocar telefone e CRECI pelos reais, e
`.\publicar.ps1`. O site sobe protegido por senha, como você aprovou.

---

## Duas coisas que eu não faria sem falar com você

1. **Publicar.** Não há credenciais, então era impossível de qualquer forma.
   Mas mesmo com elas, colocar o site no ar é ação que sai para fora e eu
   confirmaria antes.
2. **Desligar o guarda-corpo dos dados fictícios.** Você escolheu deixar
   bloqueado até passar os reais. Mantive.

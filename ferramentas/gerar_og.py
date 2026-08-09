#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera a imagem de compartilhamento (og:image, 1200x630) — a miniatura que aparece
quando alguém cola o link do site no WhatsApp, LinkedIn ou Facebook.

Roda uma vez e o resultado fica em tema/assets/og-prime-fazendas.png, que o
build copia para o site. Só precisa rodar de novo se a marca ou a assinatura
mudarem.

    python ferramentas/gerar_og.py

Requer Pillow (pip install pillow). É a ÚNICA parte do projeto que usa uma
biblioteca externa, e de propósito: ela não participa do build do site.
"""

import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageFont
except ImportError:
    print("Pillow nao instalado. Rode:  python -m pip install pillow")
    sys.exit(1)

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "tema" / "assets" / "og-prime-fazendas.png"

L, A = 1200, 630
AZUL = (12, 30, 51)
AZUL_CLARO = (26, 60, 94)
DOURADO = (201, 164, 76)
OSSO = (250, 249, 246)

ESC = 3  # supersampling: desenha 3x maior e reduz, para bordas suaves


def fonte(nomes, tamanho):
    for n in nomes:
        for base in (r"C:\Windows\Fonts", "/usr/share/fonts/truetype"):
            for arq in Path(base).rglob(n) if Path(base).exists() else []:
                try:
                    return ImageFont.truetype(str(arq), tamanho)
                except Exception:
                    continue
    return ImageFont.load_default()


# ------------------------------------------------------------------------
#  Geometria da marca — fonte única de verdade.
#  O PNG de compartilhamento e o SVG usado no site saem daqui, então os dois
#  são exatamente o mesmo desenho. Mexeu aqui, roda o script: muda nos dois.
# ------------------------------------------------------------------------

N_SULCOS = 5
ESP_SULCO = 0.105        # espessura da ranhura, em fração do raio
INICIO_SULCO = -0.06     # onde o primeiro sulco corta o sol (fração do raio)
PASSO_SULCO = 0.27
LARGURA_BACIA = 1.44
ALTURA_BACIA = 0.86      # raio vertical da bacia, em fracao do raio do sol
CENTRO_BACIA = 0.46      # quanto a bacia desce em relacao ao centro do sol


def _cume(t, r):
    """Perfil do relevo: um cume menor à esquerda e o principal ao centro."""
    return (-math.exp(-((t + 0.45) ** 2) * 10) * r * 0.21
            - math.exp(-((t - 0.10) ** 2) * 7) * r * 0.38)


def faixas(cy, r):
    """(altura da faixa, atenuação do relevo) de cada sulco, de cima para baixo."""
    return [(cy + INICIO_SULCO * r + i * PASSO_SULCO * r, 1 - i * 0.14)
            for i in range(N_SULCOS)]


def marca_alfa(tam, cx, cy, r):
    """
    Devolve a máscara alfa da marca: silhueta (sol + bacia) menos os sulcos.
    Trabalhar em máscara evita serrilhado e impede que qualquer traço
    escape para fora do contorno.
    """
    silhueta = Image.new("L", tam, 0)
    ds = ImageDraw.Draw(silhueta)
    # o sol e a bacia se sobrepõem; a união forma o contorno do logotipo
    ds.ellipse([cx - r, cy - r, cx + r, cy + r * 0.55], fill=255)
    larg = r * LARGURA_BACIA
    ds.ellipse([cx - larg, cy + r * (CENTRO_BACIA - ALTURA_BACIA),
                cx + larg, cy + r * (CENTRO_BACIA + ALTURA_BACIA)], fill=255)

    sulcos = Image.new("L", tam, 0)
    dg = ImageDraw.Draw(sulcos)
    esp = r * ESP_SULCO
    x0, x1 = int(cx - larg * 1.2), int(cx + larg * 1.2)

    for base, atenua in faixas(cy, r):
        topo, baixo = [], []
        for px in range(x0, x1 + 1, 3):
            py = base + _cume((px - cx) / larg, r) * atenua
            topo.append((px, py - esp / 2))
            baixo.append((px, py + esp / 2))
        dg.polygon(topo + baixo[::-1], fill=255)

    return ImageChops.subtract(silhueta, sulcos)


def desenhar_marca(img, cx, cy, r):
    alfa = marca_alfa(img.size, cx, cy, r)
    img.paste(Image.new("RGB", img.size, DOURADO), (0, 0), alfa)


SVG_DESTINO = RAIZ / "tema" / "assets" / "marca.svg"


def gerar_svg():
    """
    Exporta a mesma marca em vetor, para o site usar no cabeçalho, no rodapé
    e no favicon. Os sulcos saem como máscara, então a marca herda a cor do
    contexto (currentColor) e funciona sobre fundo claro ou escuro.
    """
    V = 128.0
    cx, cy, r = V / 2, V * 0.46, V * 0.335
    larg = r * LARGURA_BACIA
    esp = r * ESP_SULCO

    def n(v):
        return f"{v:.2f}".rstrip("0").rstrip(".")

    faixas_svg = []
    for base, atenua in faixas(cy, r):
        pontos = []
        passo = (larg * 2.4) / 40
        x = cx - larg * 1.2
        while x <= cx + larg * 1.2:
            pontos.append((x, base + _cume((x - cx) / larg, r) * atenua))
            x += passo
        topo = " ".join(f"{n(px)},{n(py - esp / 2)}" for px, py in pontos)
        baixo = " ".join(f"{n(px)},{n(py + esp / 2)}" for px, py in reversed(pontos))
        faixas_svg.append(f'<polygon points="{topo} {baixo}" fill="#000"/>')

    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n(V)} {n(V)}">'
        f'<defs><mask id="MASCARA">'
        f'<rect width="{n(V)}" height="{n(V)}" fill="#fff"/>'
        + "".join(faixas_svg)
        + "</mask></defs>"
        f'<g fill="currentColor" mask="url(#MASCARA)">'
        f'<ellipse cx="{n(cx)}" cy="{n(cy - r * 0.225)}" rx="{n(r)}" ry="{n(r * 0.775)}"/>'
        f'<ellipse cx="{n(cx)}" cy="{n(cy + r * CENTRO_BACIA)}" rx="{n(larg)}" ry="{n(r * ALTURA_BACIA)}"/>'
        f"</g></svg>"
    )

    SVG_DESTINO.write_text(svg, encoding="utf-8", newline="\n")
    print(f"Gerado: {SVG_DESTINO.relative_to(RAIZ)}  ({len(svg)} bytes)")


def main():
    gerar_svg()

    img = Image.new("RGB", (L * ESC, A * ESC), AZUL)
    d = ImageDraw.Draw(img)

    # brilho diagonal, para o fundo não ficar chapado
    for y in range(0, A * ESC, 2 * ESC):
        t = y / (A * ESC)
        cor = tuple(int(AZUL[i] + (AZUL_CLARO[i] - AZUL[i]) * (t ** 1.5) * 0.85) for i in range(3))
        d.rectangle([0, y, L * ESC, y + 2 * ESC], fill=cor)

    desenhar_marca(img, L * ESC * 0.5, A * ESC * 0.33, 92 * ESC)

    img = img.resize((L, A), Image.LANCZOS)
    d = ImageDraw.Draw(img)

    f_marca = fonte(["Cinzel-SemiBold.ttf", "trajanpro.ttf", "georgiab.ttf", "times.ttf"], 66)
    f_tag = fonte(["segoeui.ttf", "arial.ttf"], 27)

    def centrado(texto, f, y, cor):
        cx = (L - d.textlength(texto, font=f)) / 2
        d.text((cx, y), texto, font=f, fill=cor)

    centrado("PRIME FAZENDAS", f_marca, 400, DOURADO)

    d.line([(L / 2 - 90, 492), (L / 2 + 90, 492)], fill=DOURADO, width=2)

    centrado("A terra é o único investimento", f_tag, 518, OSSO)
    centrado("onde o tempo trabalha por você.", f_tag, 556, OSSO)

    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    img.save(DESTINO, "PNG", optimize=True)
    kb = DESTINO.stat().st_size / 1024
    print(f"Gerado: {DESTINO.relative_to(RAIZ)}  ({L}x{A}, {kb:.0f} KB)")


if __name__ == "__main__":
    main()

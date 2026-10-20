#!/usr/bin/env python3
#
# Conferência da documentação — a camada 2 dos testes do repositório (`scripts/testar.sh`).
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# Em 2026-10-20 dois defeitos de página renderizada foram achados a olho, depois de lançados: o
# diagrama "Como as duas se integram" do README mostrava "/.md" no VS Code (o `&lt;slug&gt;` do
# rótulo era decodificado e apagado pelo renderizador da extensão), e o `<motivo>` de
# "não se aplica — <motivo>" sumia das páginas do SKILL.md, do HELP.md e do CHANGELOG (fora de código,
# o markdown o lê como tag HTML). Nenhum dos dois quebra o agente, que lê o arquivo cru; os dois
# quebram a leitura de quem abre a página. Esta conferência pega essa classe de defeito antes do
# commit, junto com link e âncora quebrados e tabela de subcomandos que diverge do roteador.
#
# USO
#   testes/documentacao.py               # 0 = íntegra · 1 = defeito (listado) · 2 = não rodou
#   testes/documentacao.py --sem-render  # pula a renderização dos diagramas (as outras conferências rodam)
#
# O render usa o mermaid-cli: $MMDC, ou `mmdc` no PATH, ou o `npx` com a versão fixada abaixo.
#
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path
from urllib.parse import unquote

RAIZ = Path(__file__).resolve().parent.parent
MERMAID_CLI = '@mermaid-js/mermaid-cli@11.16.0'

# Tags HTML de verdade que um .md deste repositório pode usar de propósito. Fora delas, `<nome>` fora
# de código é placeholder que vai sumir da página.
TAGS_HTML = {
    'a', 'abbr', 'b', 'blockquote', 'br', 'code', 'dd', 'del', 'details', 'div', 'dl', 'dt', 'em',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'ins', 'kbd', 'li', 'ol', 'p', 'picture',
    'pre', 'q', 's', 'samp', 'small', 'source', 'span', 'strong', 'sub', 'summary', 'sup', 'table',
    'tbody', 'td', 'th', 'thead', 'tr', 'tt', 'u', 'ul', 'var', 'video',
}
# Dentro de um rótulo Mermaid, só a formatação que o sanitizador do Mermaid deixa passar.
TAGS_MERMAID = {'br', 'b', 'i', 'u', 'em', 'strong', 'sub', 'sup', 'small', 'span', 'code'}

# Tag HTML segundo o CommonMark: nome ASCII, atributos opcionais. `<descrição>` não é tag (o "ç"
# quebra o nome) e aparece na página; `<motivo>`, `<slug>` e `<AAAA-MM-DD>` são, e somem.
RE_TAG = re.compile(
    r'</?([A-Za-z][A-Za-z0-9-]*)'
    r'(?:\s+[A-Za-z_:][A-Za-z0-9_.:-]*(?:\s*=\s*(?:[^\s"\'=<>`]+|\'[^\']*\'|"[^"]*"))?)*'
    r'\s*/?>')
RE_CERCA = re.compile(r'^([ \t]*)(`{3,}|~{3,})(.*)$')
RE_TITULO = re.compile(r'^ {0,3}(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$')
RE_LINK = re.compile(r'!?\[([^\]\n]*)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)')
RE_DEFINICAO = re.compile(r'^ {0,3}\[[^\]\n]+\]:\s*<?(\S+?)>?(?:\s+.*)?$')

defeitos = []   # (conferência, arquivo, linha, mensagem)


def defeito(conferencia, arquivo, linha, mensagem):
    defeitos.append((conferencia, arquivo, linha, mensagem))


def arquivos_md():
    """Os .md do repositório (versionados ou novos, fora do .gitignore), menos a história congelada."""
    saida = subprocess.run(['git', '-C', str(RAIZ), 'ls-files', '-co', '--exclude-standard', '--', '*.md'],
                           capture_output=True, text=True, check=True).stdout
    # As changes arquivadas do OpenSpec são registro do que foi decidido no dia: não se reescrevem.
    return sorted({p for p in saida.splitlines() if p and not p.startswith('openspec/changes/archive/')
                   and (RAIZ / p).is_file()})


def e_template(caminho):
    """Template e fixture são copiados para outro lugar e lidos crus pelo agente: os `<placeholders>`
    deles são o conteúdo, e os links valem no destino, não aqui."""
    return '/templates/' in '/' + caminho or '/fixtures/' in '/' + caminho


class Documento:
    """Um .md separado em prosa (cercas de código apagadas, linhas preservadas) e blocos cercados."""

    def __init__(self, caminho):
        self.caminho = caminho
        self.texto = io.open(RAIZ / caminho, encoding='utf-8').read()
        linhas = self.texto.split('\n')
        self.prosa = list(linhas)
        self.blocos = []   # (linha da cerca de abertura, linguagem, conteúdo)
        i = 0
        while i < len(linhas):
            m = RE_CERCA.match(linhas[i])
            if not m or (m.group(2)[0] == '`' and '`' in m.group(3)):
                i += 1
                continue
            cerca = m.group(2)
            fecho = re.compile(r'^[ \t]*' + re.escape(cerca[0]) + '{' + str(len(cerca)) + r',}[ \t]*$')
            j = i + 1
            while j < len(linhas) and not fecho.match(linhas[j]):
                j += 1
            info = m.group(3).strip()
            self.blocos.append((i + 1, info.split()[0].lower() if info else '', '\n'.join(linhas[i + 1:j])))
            for k in range(i, min(j + 1, len(linhas))):
                self.prosa[k] = ''
            i = j + 1
        self.prosa_sem_codigo = sem_comentarios(sem_codigo_inline('\n'.join(self.prosa)))


def apagado(trecho):
    return ''.join('\n' if c == '\n' else ' ' for c in trecho)


def sem_codigo_inline(texto):
    """Apaga os code spans (CommonMark: n crases abrem, as próximas n crases exatas fecham, sem cruzar
    linha em branco); as quebras de linha ficam, para o número da linha continuar valendo."""
    saida = []
    i, n = 0, len(texto)
    while i < n:
        c = texto[i]
        if c == '\\' and i + 1 < n:
            saida.append(texto[i:i + 2])
            i += 2
            continue
        if c != '`':
            saida.append(c)
            i += 1
            continue
        j = i
        while j < n and texto[j] == '`':
            j += 1
        tamanho = j - i
        k, fecha = j, -1
        while k < n:
            if texto[k] == '`':
                f = k
                while f < n and texto[f] == '`':
                    f += 1
                if f - k == tamanho:
                    fecha = k
                    break
                k = f
                continue
            if texto[k] == '\n' and re.match(r'\n[ \t]*(\n|$)', texto[k:k + 200]):
                break
            k += 1
        if fecha < 0:
            saida.append(texto[i:j])
            i = j
            continue
        saida.append(apagado(texto[i:fecha + tamanho]))
        i = fecha + tamanho
    return ''.join(saida)


def sem_comentarios(texto):
    return re.sub(r'<!--.*?-->', lambda m: apagado(m.group(0)), texto, flags=re.S)


def linha_de(texto, posicao):
    return texto.count('\n', 0, posicao) + 1


# --- 1. Diagramas Mermaid -------------------------------------------------------------------------

def achar_mmdc():
    if os.environ.get('MMDC'):
        return [os.environ['MMDC']]
    if shutil.which('mmdc'):
        return ['mmdc']
    if shutil.which('npx'):
        return ['npx', '--yes', '-p', MERMAID_CLI, 'mmdc']
    return None


def conferir_mermaid(docs, renderizar):
    """Rótulo que o VS Code apaga (entidade HTML, tag desconhecida) e diagrama que não renderiza."""
    diagramas = [(d, linha, corpo) for d in docs for (linha, lingua, corpo) in d.blocos if lingua == 'mermaid']
    for d, linha, corpo in diagramas:
        for desloc, texto_linha in enumerate(corpo.split('\n'), start=1):
            if re.search(r'&(lt|gt|#0*6[02]|#x0*3[ce]);', texto_linha, flags=re.I):
                defeito('mermaid', d.caminho, linha + desloc,
                        'entidade HTML (&lt; / &gt;) num rótulo: o VS Code a decodifica e apaga o texto — '
                        'use #lt; e #gt;')
            for m in RE_TAG.finditer(texto_linha):
                if m.group(1).lower() not in TAGS_MERMAID:
                    defeito('mermaid', d.caminho, linha + desloc,
                            f'{m.group(0)} num rótulo é tag HTML e some do diagrama — use #lt; e #gt;')
    if not renderizar:
        return len(diagramas), 'render pulado (--sem-render)'
    mmdc = achar_mmdc()
    if mmdc is None:
        return len(diagramas), None
    with tempfile.TemporaryDirectory() as tmp:
        config = Path(tmp) / 'puppeteer.json'
        # Sem o sandbox do Chromium: o runner do CI não o permite, e o conteúdo é o deste repositório.
        config.write_text(json.dumps({'args': ['--no-sandbox', '--disable-setuid-sandbox']}))
        for n, (d, linha, corpo) in enumerate(diagramas):
            entrada, saida = Path(tmp) / f'{n}.mmd', Path(tmp) / f'{n}.svg'
            entrada.write_text(corpo, encoding='utf-8')
            try:
                r = subprocess.run(mmdc + ['-q', '-p', str(config), '-i', str(entrada), '-o', str(saida)],
                                   capture_output=True, text=True, timeout=180)
            except (OSError, subprocess.TimeoutExpired):
                return len(diagramas), None   # o mermaid-cli não rodou: não é aprovação
            if r.returncode != 0 or not saida.is_file():
                erro = (r.stderr or r.stdout).strip().splitlines()
                resumo = next((l for l in erro if 'Error' in l or 'error' in l), erro[-1] if erro else '?')
                defeito('mermaid', d.caminho, linha, f'o diagrama não renderiza: {resumo.strip()[:160]}')
    return len(diagramas), 'todos renderizam no mermaid-cli'


# --- 2. Texto que some na página --------------------------------------------------------------------

def conferir_placeholders(docs):
    for d in docs:
        if e_template(d.caminho):
            continue
        for m in RE_TAG.finditer(d.prosa_sem_codigo):
            if m.group(1).lower() in TAGS_HTML:
                continue
            if m.start() > 0 and d.prosa_sem_codigo[m.start() - 1] == '\\':
                continue
            defeito('placeholder', d.caminho, linha_de(d.prosa_sem_codigo, m.start()),
                    f'{m.group(0)} fora de código é lido como tag HTML e some da página — '
                    f'ponha entre crases (`{m.group(0)}`)')


# --- 3. Links relativos e âncoras -------------------------------------------------------------------

def texto_do_titulo(bruto):
    t = re.sub(r'!?\[([^\]]*)\]\([^)]*\)', r'\1', bruto)
    t = re.sub(r'<[^>]+>', '', t)
    return t.replace('`', '').replace('*', '')


def slug_github(titulo):
    """A âncora que o GitHub gera: minúsculas; letras, números, espaço, "-" e "_" ficam (o espaço vira
    "-"); pontuação, símbolos e emoji saem."""
    s = unicodedata.normalize('NFC', texto_do_titulo(titulo)).strip().lower()
    s = ''.join(c for c in s if c in ' -_' or unicodedata.category(c)[0] in 'LN')
    return s.replace(' ', '-')


_ancoras = {}


def ancoras(caminho):
    if caminho not in _ancoras:
        d = Documento(caminho)
        vistos, todas = {}, set()
        for linha in d.prosa:
            m = RE_TITULO.match(linha)
            if not m:
                continue
            base = slug_github(m.group(2))
            n = vistos.get(base, 0)
            vistos[base] = n + 1
            todas.add(base if n == 0 else f'{base}-{n}')
        todas.update(re.findall(r'\b(?:id|name)="([^"]+)"', d.texto))
        _ancoras[caminho] = todas
    return _ancoras[caminho]


def normalizar_ancora(a):
    """Compara âncoras sem as marcas combinantes (o seletor de variação do emoji, por exemplo): o GitHub
    e o VS Code divergem nelas, e as letras acentuadas, em NFC, não são marcas."""
    a = unicodedata.normalize('NFC', unquote(a)).lower()
    return ''.join(c for c in a if unicodedata.category(c)[0] != 'M')


def conferir_links(docs):
    total = 0
    for d in docs:
        if e_template(d.caminho):
            continue
        alvos = [(m.start(2), m.group(2)) for m in RE_LINK.finditer(d.prosa_sem_codigo)]
        posicao = 0
        for linha in d.prosa_sem_codigo.split('\n'):
            m = RE_DEFINICAO.match(linha)
            if m:
                alvos.append((posicao + m.start(1), m.group(1)))
            posicao += len(linha) + 1
        for inicio, alvo in alvos:
            if re.match(r'^[a-z][a-z0-9+.-]*:', alvo, flags=re.I):
                continue   # http, https, mailto: fora do alcance de uma conferência sem rede
            total += 1
            caminho, _, ancora = alvo.partition('#')
            linha = linha_de(d.prosa_sem_codigo, inicio)
            if caminho:
                destino = (RAIZ / d.caminho).parent / caminho
                if not destino.exists():
                    defeito('link', d.caminho, linha, f'o link aponta para {alvo}, que não existe')
                    continue
                relativo = os.path.relpath(destino.resolve(), RAIZ)
            else:
                relativo = d.caminho
            if ancora and relativo.endswith('.md'):
                validas = {normalizar_ancora(a) for a in ancoras(relativo)}
                if normalizar_ancora(ancora) not in validas:
                    defeito('link', d.caminho, linha, f'a âncora #{ancora} não existe em {relativo}')
    return total


# --- 4. Subcomandos: roteador × arquivos × HELP × README --------------------------------------------

def tabela_apos(caminho, regex_titulo):
    """As linhas (células) da primeira tabela depois do título que casa com a regex."""
    d = Documento(caminho)
    linhas = d.prosa
    for i, linha in enumerate(linhas):
        m = RE_TITULO.match(linha)
        if m and re.search(regex_titulo, m.group(2)):
            j = i + 1
            while j < len(linhas) and not linhas[j].lstrip().startswith('|'):
                if RE_TITULO.match(linhas[j]):
                    return None
                j += 1
            celulas = []
            while j < len(linhas) and linhas[j].lstrip().startswith('|'):
                partes = [c.strip() for c in re.split(r'(?<!\\)\|', linhas[j].strip())[1:-1]]
                if not all(re.fullmatch(r':?-+:?', c) for c in partes):
                    celulas.append(partes)
                j += 1
            return celulas[1:]   # sem o cabeçalho
    return None


def comandos(celulas, prefixo=''):
    nomes = set()
    for linha in celulas or []:
        m = re.match(r'`' + re.escape(prefixo) + r'([a-z-]+)', linha[0])
        if m:
            nomes.add(m.group(1))
    return nomes


def conferir_subcomandos():
    fontes = {}
    roteador = tabela_apos('sessao/SKILL.md', r'Leitura sob demanda')
    if roteador is None:
        defeito('subcomandos', 'sessao/SKILL.md', 1, 'tabela do roteador ("Leitura sob demanda") não achada')
        return
    fontes['sessao/SKILL.md (roteador)'] = comandos(roteador)
    for linha in roteador:
        nome = re.match(r'`([a-z-]+)', linha[0])
        link = re.findall(r'\]\(([^)]+)\)', linha[-1])
        if not nome:
            continue
        esperado = 'HELP.md' if nome.group(1) == 'help' else f'subcomandos/{nome.group(1)}.md'
        if link != [esperado]:
            defeito('subcomandos', 'sessao/SKILL.md', 1,
                    f'o roteador manda o `{nome.group(1)}` ler {link or "nada"}, e não {esperado}')
        elif not (RAIZ / 'sessao' / esperado).is_file():
            defeito('subcomandos', 'sessao/SKILL.md', 1, f'o roteador cita sessao/{esperado}, que não existe')
    fontes['sessao/subcomandos/*.md'] = {p.stem for p in (RAIZ / 'sessao/subcomandos').glob('*.md')} | {'help'}
    fontes['sessao/HELP.md'] = comandos(tabela_apos('sessao/HELP.md', r'^Subcomandos$'), prefixo='/sessao ')
    fontes['README.md (sessao)'] = comandos(tabela_apos('README.md', r'^Subcomandos$'))
    referencia = fontes['sessao/SKILL.md (roteador)']
    for fonte, nomes in fontes.items():
        if nomes != referencia:
            falta, sobra = sorted(referencia - nomes), sorted(nomes - referencia)
            defeito('subcomandos', fonte.split(' ')[0], 1,
                    f'{fonte} diverge do roteador: ' + '; '.join(
                        ([f'falta {", ".join(falta)}'] if falta else []) + ([f'sobra {", ".join(sobra)}'] if sobra else [])))
    # resumo-trabalho: a tabela "Sintaxe" do SKILL.md × a do README.
    sintaxe = comandos(tabela_apos('resumo-trabalho/SKILL.md', r'^Sintaxe'))
    readme = None
    d = Documento('README.md')
    for i, linha in enumerate(d.prosa):
        m = RE_TITULO.match(linha)
        if m and 'resumo-trabalho' in m.group(2) and m.group(1) == '##':
            resto = [l for l in d.prosa[i + 1:]]
            for j, l2 in enumerate(resto):
                m2 = RE_TITULO.match(l2)
                if m2 and m2.group(2) == 'Subcomandos':
                    tabela = []
                    for l3 in resto[j + 1:]:
                        if l3.lstrip().startswith('|'):
                            tabela.append([c.strip() for c in l3.strip().split('|')[1:-1]])
                        elif tabela:
                            break
                    readme = comandos(tabela[2:])
                    break
            break
    if not sintaxe:
        defeito('subcomandos', 'resumo-trabalho/SKILL.md', 1, 'tabela "Sintaxe" não achada')
    elif readme != sintaxe:
        defeito('subcomandos', 'README.md', 1,
                f'a tabela de subcomandos do resumo-trabalho no README ({sorted(readme or [])}) diverge da '
                f'"Sintaxe" do SKILL.md ({sorted(sintaxe)})')


def main():
    renderizar = '--sem-render' not in sys.argv[1:]
    if any(a not in ('--sem-render',) for a in sys.argv[1:]):
        print('uso: testes/documentacao.py [--sem-render]', file=sys.stderr)
        return 2
    docs = [Documento(p) for p in arquivos_md()]
    print(f'Conferência da documentação — {len(docs)} arquivos .md')

    n_diagramas, como = conferir_mermaid(docs, renderizar)
    conferir_placeholders(docs)
    n_links = conferir_links(docs)
    conferir_subcomandos()

    titulos = {
        'mermaid': f'1. Diagramas Mermaid ({n_diagramas})',
        'placeholder': '2. Texto que some na página (tag HTML desconhecida fora de código)',
        'link': f'3. Links relativos e âncoras ({n_links})',
        'subcomandos': '4. Subcomandos: roteador × arquivos × HELP × README',
    }
    for chave, titulo in titulos.items():
        print(f'\n\033[1m{titulo}\033[0m')
        achados = [x for x in defeitos if x[0] == chave]
        for _, arquivo, linha, mensagem in achados:
            print(f'  🔴 {arquivo}:{linha}: {mensagem}')
        if not achados:
            extra = f' — {como}' if chave == 'mermaid' and como else ''
            print(f'  ✅ nada a corrigir{extra}')
    print('-' * 72)
    if defeitos:
        print(f'🔴 DOCUMENTAÇÃO COM DEFEITO — {len(defeitos)} achado(s) acima.')
        return 1
    if renderizar and como is None:
        print('⚠️  NÃO RODOU POR INTEIRO — sem o mermaid-cli (mmdc) os diagramas não foram renderizados.')
        print(f'   Instale-o (npm install -g {MERMAID_CLI}) ou aponte $MMDC para ele. --sem-render pula.')
        return 2
    print(f'✅ DOCUMENTAÇÃO ÍNTEGRA — {len(docs)} arquivos: diagramas, texto que some, links e âncoras, '
          'subcomandos.')
    return 0


if __name__ == '__main__':
    sys.exit(main())

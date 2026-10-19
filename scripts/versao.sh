#!/usr/bin/env bash
#
# Versão das skills deste repositório. Cada skill (pasta da raiz com SKILL.md versionado) tem:
#   <skill>/VERSION        — a versão atual, SemVer (MAJOR.MINOR.PATCH), e nada mais;
#   <skill>/CHANGELOG.md   — o que mudou em cada versão (Keep a Changelog, em pt-BR);
#   tag <skill>-v<versão>  — o commit que a lançou.
# Quando subir cada número: seção "Versionamento" do README.md da raiz.
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# Até 2026-10-19 as skills não tinham número: a `sessao` quebrou contrato várias vezes (layout
# multi-escopo, portão executável, protocolo só na skill) sem haver onde ver o que mudou nem desde
# quando. Versão, CHANGELOG e tag registram o mesmo fato em três lugares; este script confere que
# concordam — e que nenhuma skill mudou desde a última tag sem entrada no CHANGELOG —, em vez de
# confiar que alguém lembrou dos três. É a lição do portão: conferência executável, não checklist.
#
# USO
#   versao.sh verificar [<skill>…]              # 0 = coerente · 1 = divergência (listada)
#   versao.sh lancar <skill> major|minor|patch  # 0 = VERSION e CHANGELOG prontos · 1 = nada a lançar
#   (2 = erro de uso)
#
# O `lancar` só edita o VERSION e o CHANGELOG: põe a versão nova, com a data de hoje, sobre o que
# estava em "Não lançado" e atualiza os links de comparação. Commit, tag e push ficam com quem
# lança, cada um com a validação do usuário — o script só imprime os comandos.
#
set -o pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_DIR
readonly NAO_LANCADO='## [Não lançado]'
readonly RE_SEMVER='^[0-9]+\.[0-9]+\.[0-9]+$'
readonly RE_TITULO_VERSAO='^## \[([0-9]+\.[0-9]+\.[0-9]+)\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$'

uso() {
    echo "uso: $0 verificar [<skill>…]" >&2
    echo "     $0 lancar <skill> major|minor|patch" >&2
    exit 2
}

cd "${REPO_DIR}" || exit 2
git rev-parse --git-dir >/dev/null 2>&1 || { echo "🔴 ${REPO_DIR} não é um repositório git" >&2; exit 2; }

# Skills = pastas da raiz cujo SKILL.md está no índice do git (o cache synced/ fica de fora).
lista_skills() { git ls-files -- '*/SKILL.md' | awk -F/ 'NF == 2 { print $1 }' | sort -u; }

e_skill() { git ls-files --error-unmatch -- "$1/SKILL.md" >/dev/null 2>&1; }

# 0 se $1 > $2 em SemVer (só X.Y.Z).
versao_maior() {
    local -a a b
    local i
    IFS=. read -r -a a <<< "$1"
    IFS=. read -r -a b <<< "$2"
    for i in 0 1 2; do
        (( 10#${a[i]} > 10#${b[i]} )) && return 0
        (( 10#${a[i]} < 10#${b[i]} )) && return 1
    done
    return 1
}

# Itens de lista da seção "Não lançado" — as entradas de fato, não os subtítulos vazios.
entradas_nao_lancadas() {
    awk -v cab="${NAO_LANCADO}" '
        $0 == cab                   { dentro = 1; next }
        dentro && /^## /            { exit }
        dentro && /^[[:space:]]*- / { print }
    ' "$1"
}

# Versões dos títulos "## [X.Y.Z] - AAAA-MM-DD", na ordem do arquivo.
versoes_do_changelog() { sed -n -E "s/${RE_TITULO_VERSAO}/\1/p" "$1"; }

verifica_skill() {
    local s="$1" cl="$1/CHANGELOG.md" versao="" tag primeira anterior v n mudou
    local -i erros=0
    falha() { echo "🔴 ${s}: $1"; erros+=1; }

    if [[ ! -f "${s}/VERSION" ]]; then
        falha "falta ${s}/VERSION"
    else
        versao="$(cat "${s}/VERSION")"
        if [[ "$(wc -l < "${s}/VERSION")" -ne 1 || ! "${versao}" =~ ${RE_SEMVER} ]]; then
            falha "${s}/VERSION deve conter só a versão (X.Y.Z) — achei '$(head -c 40 "${s}/VERSION" | tr '\n' ' ')'"
            versao=""
        fi
    fi
    if [[ ! -f "${cl}" ]]; then
        falha "falta ${cl}"
        return 1
    fi

    n="$(grep -c -x -F -- "${NAO_LANCADO}" "${cl}")"
    [[ "${n}" -eq 1 ]] || falha "${cl} precisa de exatamente um título '${NAO_LANCADO}' (achei ${n})"
    grep -n '^## \[' "${cl}" | while IFS= read -r linha; do
        [[ "${linha#*:}" == "${NAO_LANCADO}" || "${linha#*:}" =~ ${RE_TITULO_VERSAO} ]] \
            || echo "🔴 ${s}: título fora do formato '## [X.Y.Z] - AAAA-MM-DD' (linha ${linha%%:*}): ${linha#*:}"
    done | grep . && erros+=1
    if [[ "$(grep -n '^## \[' "${cl}" | head -1 | cut -d: -f2-)" != "${NAO_LANCADO}" ]]; then
        falha "'${NAO_LANCADO}' tem de ser a primeira seção de versão do ${cl}"
    fi

    primeira="$(versoes_do_changelog "${cl}" | head -1)"
    if [[ -z "${primeira}" ]]; then
        falha "${cl} não tem nenhuma versão lançada (## [X.Y.Z] - AAAA-MM-DD)"
    elif [[ -n "${versao}" && "${primeira}" != "${versao}" ]]; then
        falha "VERSION diz ${versao}, mas a versão mais recente do CHANGELOG é ${primeira}"
    fi
    anterior=""
    while IFS= read -r v; do
        if [[ -n "${anterior}" ]] && ! versao_maior "${anterior}" "${v}"; then
            falha "versões fora de ordem no CHANGELOG: ${anterior} aparece acima de ${v}"
        fi
        anterior="${v}"
    done < <(versoes_do_changelog "${cl}")
    grep -q -F -- '[Não lançado]: ' "${cl}" || falha "falta o link '[Não lançado]: <repo>/compare/…' no fim do ${cl}"
    while IFS= read -r v; do
        grep -q -F -- "[${v}]: " "${cl}" || falha "falta o link '[${v}]: …' no fim do ${cl}"
    done < <(versoes_do_changelog "${cl}")

    [[ -n "${versao}" ]] || return 1
    tag="${s}-v${versao}"
    if ! git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
        falha "a versão ${versao} não tem tag (${tag}) — lançamento sem tag"
    elif [[ "$(git show "${tag}:${s}/VERSION" 2>/dev/null)" != "${versao}" ]]; then
        falha "a tag ${tag} não aponta para um commit com ${s}/VERSION = ${versao}"
    else
        mudou="$( { git diff --name-only "${tag}" -- "${s}" ":(exclude)${cl}"
                    git ls-files --others --exclude-standard -- "${s}"; } | sort -u)"
        if [[ -n "${mudou}" && -z "$(entradas_nao_lancadas "${cl}")" ]]; then
            falha "mudou desde ${tag} e a seção 'Não lançado' do CHANGELOG está vazia:"
            printf '%s\n' "${mudou}" | sed 's/^/     /'
        fi
    fi

    (( erros == 0 )) || return 1
    echo "✅ ${s} ${versao} — VERSION, CHANGELOG e tag ${tag} concordam"
}

verificar() {
    local -a skills
    local s
    local -i ruins=0
    if [[ $# -gt 0 ]]; then skills=("$@"); else mapfile -t skills < <(lista_skills); fi
    [[ ${#skills[@]} -gt 0 ]] || { echo "🔴 nenhuma skill encontrada em ${REPO_DIR}" >&2; exit 2; }
    for s in "${skills[@]}"; do
        s="${s%/}"
        e_skill "${s}" || { echo "🔴 '${s}' não é uma skill deste repositório (sem ${s}/SKILL.md no git)" >&2; exit 2; }
        verifica_skill "${s}" || ruins+=1
    done
    (( ruins == 0 ))
}

lancar() {
    [[ $# -eq 2 ]] || uso
    local s="${1%/}" nivel="$2" cl atual nova hoje base ma mi pa tmp ramo
    cl="${s}/CHANGELOG.md"
    e_skill "${s}" || { echo "🔴 '${s}' não é uma skill deste repositório (sem ${s}/SKILL.md no git)" >&2; exit 2; }
    [[ -f "${s}/VERSION" && -f "${cl}" ]] || { echo "🔴 ${s} sem VERSION ou CHANGELOG.md" >&2; exit 2; }
    atual="$(cat "${s}/VERSION")"
    [[ "${atual}" =~ ${RE_SEMVER} ]] || { echo "🔴 ${s}/VERSION inválido: '${atual}'" >&2; exit 2; }
    IFS=. read -r ma mi pa <<< "${atual}"
    case "${nivel}" in
        major) nova="$((ma + 1)).0.0" ;;
        minor) nova="${ma}.$((mi + 1)).0" ;;
        patch) nova="${ma}.${mi}.$((pa + 1))" ;;
        *)     uso ;;
    esac
    if [[ -z "$(entradas_nao_lancadas "${cl}")" ]]; then
        echo "🔴 nada a lançar: a seção 'Não lançado' de ${cl} está vazia"
        exit 1
    fi
    if git rev-parse -q --verify "refs/tags/${s}-v${nova}" >/dev/null; then
        echo "🔴 a tag ${s}-v${nova} já existe" >&2
        exit 2
    fi
    base="$(sed -n -E 's|^\[Não lançado\]: (.*)/compare/.*$|\1|p' "${cl}")"
    [[ -n "${base}" ]] || { echo "🔴 ${cl} sem o link '[Não lançado]: <repo>/compare/…'" >&2; exit 2; }

    hoje="$(date +%F)"
    tmp="$(mktemp)"
    # Expandido já: `tmp` é local e não existe mais quando o trap de saída roda.
    trap "rm -f -- '${tmp}'" EXIT
    awk -v cab="${NAO_LANCADO}" -v nova="${nova}" -v atual="${atual}" -v hoje="${hoje}" \
        -v base="${base}" -v s="${s}" '
        $0 == cab { print; print ""; print "## [" nova "] - " hoje; next }
        index($0, "[Não lançado]: ") == 1 {
            print "[Não lançado]: " base "/compare/" s "-v" nova "...HEAD"
            print "[" nova "]: " base "/compare/" s "-v" atual "..." s "-v" nova
            next
        }
        { print }
    ' "${cl}" > "${tmp}"
    # `cat >` em vez de `mv`: preserva dono, permissões e hardlinks do arquivo original.
    cat "${tmp}" > "${cl}"
    printf '%s\n' "${nova}" > "${s}/VERSION"

    ramo="$(git rev-parse --abbrev-ref HEAD)"
    echo "✅ ${s} ${atual} → ${nova}: VERSION e CHANGELOG prontos (seção [${nova}] - ${hoje})."
    echo "   Falta commit, tag e push — cada um com a validação do usuário:"
    echo "     git add ${s} && git commit -m \"release: ${s} ${nova}\""
    echo "     git tag -a ${s}-v${nova} -m \"${s} ${nova}\""
    echo "     git push origin ${ramo} ${s}-v${nova}"
}

[[ $# -ge 1 ]] || uso
case "$1" in
    verificar) shift; verificar "$@" ;;
    lancar)    shift; lancar "$@" ;;
    *)         uso ;;
esac

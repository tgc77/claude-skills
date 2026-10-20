#!/usr/bin/env bash
#
# Camada 3 dos testes: o comportamento do agente, de ponta a ponta, em cenários roteirizados.
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# Quase tudo o que a `sessao` e o `resumo-trabalho` fazem é instrução para o agente, e instrução só
# se testa com o agente de verdade. A 3.1.1 e a 3.2.0 da `sessao` mudaram só esse texto — o handoff
# feito pelo próprio Planejador, os próximos passos no fim da sessão, os avisos do `start`, a pergunta
# do card no `resumo-trabalho` — e nada conferia se o agente passou a fazer o que o texto diz. Cada
# cenário monta um projeto descartável, conversa com o CLI (`claude -p` ou `codex exec`) como o
# usuário conversaria e confere o que a skill promete: o estado pelo `--estado` do portão, os
# commits, o work-log, o remoto e, por último, a resposta.
#
# Custa: cada turno é uma chamada real ao modelo, no plano ou na conta de quem roda. O --teto-usd
# corta a rodada pelo custo que o CLI informa (no Claude Code; o Codex não informa custo).
#
# USO
#   testes/comportamento/rodar.sh [opções] [<cenário>…]   # sem cenário, todos
#     --ferramenta claude|codex   o CLI que conversa (padrão: claude)
#     --vezes <n>                 roda cada cenário n vezes; o modelo varia (padrão: 1)
#     --teto-usd <valor>          interrompe a rodada quando o custo somado passa disso (padrão: 25)
#     --manter                    não apaga as caixas nem as conversas (para depurar)
#     --listar                    lista os cenários e sai
#   testes/comportamento/rodar.sh --selo                          # a impressão digital do conteúdo
#   testes/comportamento/rodar.sh --conferir-selo <skill> <tag>   # o que o versao.sh lancar pergunta
#   exit 0 = verde · 1 = algum cenário vermelho · 2 = não rodou (CLI ausente, teto atingido, uso)
#
# Modelos: SESSAO_TESTE_MODELO_FORTE (padrão: opus) nos turnos do Planejador e SESSAO_TESTE_MODELO_BARATO
# (padrão: sonnet) nos do Executor e nos pedidos avulsos — a divisão que a skill recomenda. No Codex o
# padrão é o modelo da configuração do usuário (variáveis vazias). O binário: SESSAO_TESTE_CLAUDE e
# SESSAO_TESTE_CODEX (padrão: claude e codex do PATH).
#
# Rodada completa e verde grava o SELO: a impressão digital das instruções das skills e destes
# cenários, guardada dentro do .git (não vai para o commit). É o que o `versao.sh lancar` confere
# antes de lançar uma versão que mexeu em instrução.
#
set -o pipefail

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly SKILLS_DIR
readonly DIR="${SKILLS_DIR}/testes/comportamento"
readonly ARQ_SELO="sessao-testes/comportamento.selo"
cd "${SKILLS_DIR}" || exit 2

# A DESCRICAO de um cenário, lida do próprio arquivo (só define a variável e a função).
descricao_de() { ( source "$1" >/dev/null 2>&1; printf '%s' "${DESCRICAO:-}" ); }

uso() {
    echo "uso: $0 [--ferramenta claude|codex] [--vezes <n>] [--teto-usd <valor>] [--manter] [<cenário>…]" >&2
    echo "     $0 --listar | --selo | --conferir-selo <skill> <tag>" >&2
    exit 2
}

# Impressão digital do que a camada 3 testa: as instruções de cada skill (tudo menos CHANGELOG,
# HISTORICO, README e VERSION, que não são lidos para operar) e os próprios cenários.
impressao_digital() {
    local s f
    {
        for s in $(git ls-files -- '*/SKILL.md' | awk -F/ 'NF == 2 { print $1 }' | sort -u); do
            git ls-files -co --exclude-standard -- "${s}" \
                | grep -vE "^${s}/(CHANGELOG\.md|HISTORICO\.md|README\.md|VERSION)$"
        done
        git ls-files -co --exclude-standard -- testes/comportamento
    } | sort -u | while IFS= read -r f; do
        [[ -f "${f}" ]] && printf '%s %s\n' "$(sha256sum < "${f}" | cut -c1-64)" "${f}"
    done | sha256sum | cut -c1-64
}

conferir_selo() {
    local skill="${1%/}" tag="$2" mudou selo
    git rev-parse -q --verify "refs/tags/${tag}" >/dev/null || { echo "🔴 tag ${tag} não existe" >&2; exit 2; }
    mudou="$( { git diff --name-only "${tag}" -- "${skill}"; git ls-files -o --exclude-standard -- "${skill}"; } \
              | sort -u | grep -vE "^${skill}/(CHANGELOG\.md|HISTORICO\.md|README\.md|VERSION)$")"
    if [[ -z "${mudou}" ]]; then
        echo "✅ ${skill}: nenhuma instrução mudou desde ${tag} — a camada 3 não é exigida."
        exit 0
    fi
    selo="$(git rev-parse --git-path "${ARQ_SELO}")"
    if [[ -f "${selo}" && "$(sed -n 's/^conteudo=//p' "${selo}")" == "$(impressao_digital)" ]]; then
        echo "✅ camada 3 verde para o conteúdo atual: $(sed -n 's/^rodada=//p' "${selo}")."
        exit 0
    fi
    echo "🔴 ${skill} mudou instruções desde ${tag} e não há rodada verde da camada 3 para o conteúdo atual:"
    printf '%s\n' "${mudou}" | sed 's/^/     /'
    echo "   Rode os cenários com o agente (gastam do seu plano) e lance depois:"
    echo "     scripts/testar.sh --comportamento"
    exit 1
}

FERRAMENTA=claude
VEZES=1
TETO_USD=25
MANTER=0
declare -a PEDIDOS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ferramenta)    FERRAMENTA="${2:-}"; shift 2 ;;
        --vezes)         VEZES="${2:-}"; shift 2 ;;
        --teto-usd)      TETO_USD="${2:-}"; shift 2 ;;
        --manter)        MANTER=1; shift ;;
        --listar)        for c in "${DIR}"/cenarios/[0-9][0-9]-*.sh; do
                             n="$(basename "${c}" .sh)"; printf '  %-24s %s\n' "${n#[0-9][0-9]-}" "$(descricao_de "${c}")"
                         done; exit 0 ;;
        --selo)          impressao_digital; exit 0 ;;
        --conferir-selo) [[ $# -eq 3 ]] || uso; conferir_selo "$2" "$3" ;;
        -*)              uso ;;
        *)               PEDIDOS+=("$1"); shift ;;
    esac
done
[[ "${FERRAMENTA}" =~ ^(claude|codex)$ && "${VEZES}" =~ ^[1-9][0-9]*$ && "${TETO_USD}" =~ ^[0-9]+([.][0-9]+)?$ ]] || uso

# --- Pré-condições: sem elas a rodada não roda (exit 2), nunca vira verde -----------------------------
export CLAUDE_BIN="${SESSAO_TESTE_CLAUDE:-claude}" CODEX_BIN="${SESSAO_TESTE_CODEX:-codex}"
if [[ "${FERRAMENTA}" == claude ]]; then binario="${CLAUDE_BIN}"; else binario="${CODEX_BIN}"; fi
for f in "${binario}" git jq python3 openspec timeout; do
    command -v "${f}" >/dev/null || { echo "⚠️  falta '${f}' no PATH: a camada 3 não rodou." >&2; exit 2; }
done
# O CLI carrega a skill instalada, não a pasta deste script: os dois têm de ser a mesma.
if [[ "${FERRAMENTA}" == claude ]]; then instalada="${HOME}/.claude/skills"; else instalada="${HOME}/.codex/skills/sessao/.."; fi
if [[ "$(realpath -m "${instalada}")" != "$(realpath "${SKILLS_DIR}")" ]]; then
    echo "⚠️  o ${FERRAMENTA} carrega as skills de ${instalada}, não de ${SKILLS_DIR}: a camada 3 testaria outra" >&2
    echo "   cópia. Rode-a a partir da cópia instalada. A camada 3 não rodou." >&2
    exit 2
fi

export FERRAMENTA SKILLS_DIR TETO_USD
export MODELO_FORTE MODELO_BARATO
if [[ "${FERRAMENTA}" == claude ]]; then
    MODELO_FORTE="${SESSAO_TESTE_MODELO_FORTE:-opus}"
    MODELO_BARATO="${SESSAO_TESTE_MODELO_BARATO:-sonnet}"
else
    MODELO_FORTE="${SESSAO_TESTE_MODELO_FORTE:-}"
    MODELO_BARATO="${SESSAO_TESTE_MODELO_BARATO:-}"
fi
export MAX_PASSOS="${SESSAO_TESTE_MAX_PASSOS:-120}"     # chamadas de ferramenta por turno
export TEMPO_TURNO="${SESSAO_TESTE_TEMPO_TURNO:-1500}"  # segundos por turno
export TETO_TURNO_USD="${SESSAO_TESTE_TETO_TURNO_USD:-6}"

RODADA="$(mktemp -d "${TMPDIR:-/tmp}/sessao-comportamento-rodada.XXXXXX")"
readonly RODADA
export ARQ_CUSTO="${RODADA}/custo" ARQ_CAIXAS="${RODADA}/caixas"
: > "${ARQ_CUSTO}"
: > "${ARQ_CAIXAS}"
touch "${RODADA}/inicio"   # referência de tempo para achar as conversas do Codex criadas nesta rodada

# Apaga as caixas e as conversas que os cenários criaram — as do Claude Code moram em
# ~/.claude/projects/<caminho com "-">, as do Codex em ~/.codex/sessions, com o cwd na 1ª linha.
limpar() {
    [[ "${MANTER}" -eq 1 ]] && { echo "   (--manter) caixas e conversas em ${RODADA} e nas caixas listadas em ${ARQ_CAIXAS}"; return; }
    local caixa projeto
    while IFS= read -r caixa; do
        [[ -n "${caixa}" && "${caixa}" == "${TMPDIR:-/tmp}"/sessao-comportamento.* ]] || continue
        projeto="${HOME}/.claude/projects/$(sed 's#[^A-Za-z0-9]#-#g' <<<"${caixa}/repo")"
        [[ -d "${projeto}" ]] && rm -rf -- "${projeto}"
        if [[ -d "${HOME}/.codex/sessions" ]]; then
            find "${HOME}/.codex/sessions" -name 'rollout-*.jsonl' -newer "${RODADA}/inicio" -print0 2>/dev/null \
                | while IFS= read -r -d '' r; do
                    head -1 "${r}" | grep -qF "\"cwd\":\"${caixa}/repo\"" && rm -f -- "${r}"
                done
        fi
        rm -rf -- "${caixa}"
    done < "${ARQ_CAIXAS}"
    rm -rf -- "${RODADA}"
}
trap limpar EXIT

# --- Cenários -------------------------------------------------------------------------------------------
declare -a CENARIOS=()
for c in "${DIR}"/cenarios/[0-9][0-9]-*.sh; do
    nome="$(basename "${c}" .sh)"; nome="${nome#[0-9][0-9]-}"
    if [[ ${#PEDIDOS[@]} -eq 0 ]] || printf '%s\n' "${PEDIDOS[@]}" | grep -qxF "${nome}"; then
        CENARIOS+=("${c}")
    fi
done
for p in "${PEDIDOS[@]}"; do
    compgen -G "${DIR}/cenarios/[0-9][0-9]-${p}.sh" >/dev/null || { echo "🔴 cenário desconhecido: ${p} (veja --listar)" >&2; exit 2; }
done

printf 'Camada 3 — %s cenário(s) × %s, com o %s %s (forte: %s · barato: %s), teto US$ %s\n' \
    "${#CENARIOS[@]}" "${VEZES}" "${FERRAMENTA}" "$("${binario}" --version 2>/dev/null | head -1 | awk '{print $NF ~ /^[0-9]/ ? $NF : $1}')" \
    "${MODELO_FORTE:-padrão}" "${MODELO_BARATO:-padrão}" "${TETO_USD}"

vermelhos=0
nao_rodou=0
declare -a RESUMO=()
for c in "${CENARIOS[@]}"; do
    nome="$(basename "${c}" .sh)"; nome="${nome#[0-9][0-9]-}"
    for ((v = 1; v <= VEZES; v++)); do
        printf '\n\033[1m%s%s\033[0m — %s\n' "${nome}" "$([[ ${VEZES} -gt 1 ]] && echo " (${v}/${VEZES})")" \
            "$(descricao_de "${c}")"
        inicio="${SECONDS}"
        custo_antes="$(awk '{ s += $1 } END { printf "%.2f", s }' "${ARQ_CUSTO}")"
        export SAIDA="${RODADA}/${nome}-${v}"
        mkdir -p "${SAIDA}"
        (
            # shellcheck source=lib.sh
            source "${DIR}/lib.sh"
            # shellcheck disable=SC1090
            source "${c}"
            cenario
            [[ "${falhas}" -eq 0 ]]
        )
        codigo=$?
        custo="$(awk -v a="${custo_antes}" '{ s += $1 } END { printf "%.2f", s - a }' "${ARQ_CUSTO}")"
        case "${codigo}" in
            0) RESUMO+=("✅ ${nome}$([[ ${VEZES} -gt 1 ]] && echo " ${v}/${VEZES}") — $((SECONDS - inicio))s, US\$ ${custo}") ;;
            1) vermelhos=$((vermelhos + 1)); RESUMO+=("🔴 ${nome}$([[ ${VEZES} -gt 1 ]] && echo " ${v}/${VEZES}") — $((SECONDS - inicio))s, US\$ ${custo} · conversa: ${SAIDA}") ;;
            *) nao_rodou=$((nao_rodou + 1)); RESUMO+=("⚠️  ${nome} — não rodou (exit ${codigo})") ;;
        esac
        [[ "${codigo}" -ge 2 ]] && break 2
    done
done

total="$(awk '{ s += $1 } END { printf "%.2f", s }' "${ARQ_CUSTO}")"
echo
echo "------------------------------------------------------------------------"
printf '%s\n' "${RESUMO[@]}"
echo "Custo informado pelo CLI: US\$ ${total} (no plano Pro/Max, é o uso do plano a preço de tabela)."
if [[ -s "${ARQ_CUSTO}.alarmes" ]]; then
    echo "⚠️  Algo mudou fora da caixa durante a rodada (ver os 🔴 acima): o selo não é gravado."
    vermelhos=$((vermelhos + 1))
fi
if [[ "${nao_rodou}" -gt 0 ]]; then
    echo "⚠️  CAMADA 3 INCOMPLETA — ${nao_rodou} cenário(s) não rodou(aram); isso não é aprovação."
    exit 2
fi
if [[ "${vermelhos}" -gt 0 ]]; then
    [[ "${MANTER}" -eq 0 ]] && echo "   As conversas dos vermelhos são apagadas no fim; rode de novo com --manter para lê-las."
    echo "🔴 CAMADA 3 REPROVADA — ${vermelhos} cenário(s) vermelho(s)."
    exit 1
fi
if [[ ${#PEDIDOS[@]} -eq 0 ]]; then
    selo="$(git rev-parse --git-path "${ARQ_SELO}")"
    mkdir -p "$(dirname "${selo}")"
    printf 'conteudo=%s\nrodada=%s, %s cenários × %s, %s (forte: %s, barato: %s), US$ %s\n' \
        "$(impressao_digital)" "$(date '+%F %H:%M')" "${#CENARIOS[@]}" "${VEZES}" "${FERRAMENTA}" \
        "${MODELO_FORTE:-padrão}" "${MODELO_BARATO:-padrão}" "${total}" > "${selo}"
    echo "✅ CAMADA 3 APROVADA — ${#CENARIOS[@]} cenário(s) × ${VEZES}. Selo gravado: o versao.sh lancar o aceita"
    echo "   enquanto as instruções das skills e os cenários não mudarem."
else
    echo "✅ CAMADA 3 APROVADA — só os cenários pedidos; o selo exige a rodada completa."
fi

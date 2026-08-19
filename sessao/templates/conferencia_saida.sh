#!/usr/bin/env bash
#
# Conferência de saída MECÂNICA — o portão que roda antes de todo commit de fim de turno
# (`end` / `handoff`). Ver AGENTS.md, "🧾 Ritual de fim de turno", item 5.
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# A conferência já existia em prosa no AGENTS.md, com o item certo escrito com todas as letras
# ("bloco 🟢 ou tarefa [x] citada como ponto de entrada = baton podre"). Mesmo assim o defeito
# aconteceu DUAS vezes — 2026-08-17 (sessão 34, baton preso em `⚙️ 11.1`) e 2026-08-19 (sessão 44,
# baton preso em `⚙️ 16.1`). Nas duas, a sessão relatou com honestidade que tinha passado o baton
# para o 🧠 e não passou: escreveu a troca no resumo, no corpo da tarefa e na mensagem de commit,
# e deixou a LINHA `🎬` intacta.
#
# A causa não é desatenção pontual, é o tipo do controle: uma checklist que o próprio agente
# declara ter cumprido é auto-atestada — ela mede a intenção dele, não o arquivo. Este script mede
# o arquivo. Nenhum item aqui depende de o agente lembrar de nada: ou o texto mudou no git, ou não.
#
# USO
#   scripts/conferencia_saida.sh <slug> <ref-base>   # FECHAMENTO: todos os itens (end/handoff)
#   scripts/conferencia_saida.sh <slug> --inicio     # INÍCIO: só a coerência do baton que se vai ler
#     <slug>      escopo da sessão (coluna `Slug` do CLAUDE.md) — ele resolve o caminho do PLAN
#     <ref-base>  commit em que ESTA sessão começou (`git rev-parse HEAD` no início)
#
# O modo --inicio é a defesa do lado do LEITOR: antes de executar à risca o que o baton manda,
# confere se ele não está podre (mandando refazer tarefa já [x]). Custa 1 segundo e é o que separa
# "entrei no papel certo" de "refiz um bloco inteiro que já estava pronto".
#
# Saída: uma linha por item, ✅ / ⚠️ / 🔴. Qualquer 🔴 ⇒ exit 1 ⇒ NÃO COMMITE.
# ⚠️ = item não aplicável a este PLAN (formato diferente); confira na mão.
#
set -o pipefail

readonly INDICE_DE_ESCOPOS="CLAUDE.md"
readonly LOG_DE_APONTAMENTO_DIR="${HOME}/.claude/work-log"
readonly REGEX_LINHA_BATON='^- \*\*🎬 Próximo:\*\*'
readonly REGEX_LINHA_SESSAO='^\| [0-9]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2} \|'

houve_vermelho=0

verde()    { printf '✅ %s\n' "$1"; }
amarelo()  { printf '⚠️  %s\n' "$1"; }
vermelho() { printf '🔴 %s\n' "$1"; houve_vermelho=1; }

if [[ $# -ne 2 ]]; then
    echo "uso: $0 <slug> <ref-base>   |   $0 <slug> --inicio" >&2
    exit 2
fi
readonly SLUG="$1"
readonly REF_BASE="$2"
if [[ "${REF_BASE}" == "--inicio" ]]; then
    readonly MODO="inicio"
else
    readonly MODO="fechamento"
fi

# --- Resolução do PLAN --------------------------------------------------------------------------
# Ordem: índice de escopos (única fonte que sabe onde mora escopo migrado com pasta ≠ slug) →
# convenção do layout canônico → PLAN na raiz (layout legado, instalação anterior ao multi-escopo).
cd "$(git rev-parse --show-toplevel)" || exit 2
PLAN=""
if [[ -f "${INDICE_DE_ESCOPOS}" ]]; then
    PLAN=$(grep -E "^\| \`${SLUG}\`" "${INDICE_DE_ESCOPOS}" | sed -E 's/.*\]\(([^)]+)\).*/\1/')
fi
if [[ -z "${PLAN}" || ! -f "${PLAN}" ]]; then
    for candidato in "docs/sessoes/${SLUG}/PLAN.md" "PLAN.md"; do
        [[ -f "${candidato}" ]] && { PLAN="${candidato}"; break; }
    done
fi
if [[ -z "${PLAN}" || ! -f "${PLAN}" ]]; then
    echo "🔴 slug '${SLUG}' não resolve para nenhum PLAN (nem no ${INDICE_DE_ESCOPOS}, nem em" >&2
    echo "   docs/sessoes/${SLUG}/PLAN.md, nem em PLAN.md na raiz)" >&2
    exit 2
fi
if [[ "${MODO}" == "fechamento" ]]; then
    if ! git rev-parse --verify --quiet "${REF_BASE}" >/dev/null; then
        echo "🔴 ref-base '${REF_BASE}' não existe neste repositório" >&2
        exit 2
    fi
    diff_do_plan=$(git diff "${REF_BASE}" -- "${PLAN}")
    echo "PLAN: ${PLAN}   ref-base: $(git rev-parse --short "${REF_BASE}")   modo: fechamento"
else
    diff_do_plan=""
    echo "PLAN: ${PLAN}   modo: início (só a coerência do baton)"
fi
echo "----------------------------------------------------------------------"

# --- ① A linha 🎬 existe, e existe uma só ------------------------------------------------------
linhas_baton=$(grep -cE "${REGEX_LINHA_BATON}" "${PLAN}")
if [[ "${linhas_baton}" -eq 1 ]]; then
    verde "① linha 🎬 única encontrada"
elif [[ "${linhas_baton}" -eq 0 ]]; then
    vermelho "① nenhuma linha '- **🎬 Próximo:**' no PLAN — a próxima sessão fica sem papel"
else
    vermelho "① ${linhas_baton} linhas 🎬 no PLAN — duas cópias do mesmo estado, corrija in-place"
fi
linha_baton=$(grep -E "${REGEX_LINHA_BATON}" "${PLAN}" | head -1)

# --- ② A linha 🎬 foi REESCRITA nesta sessão ---------------------------------------------------
# É o item que pega o defeito real: sessão que trabalhou, avançou o ponto de entrada e deixou a
# linha do handoff anterior de pé. Sessão que não mexe no baton não tem o que fechar.
if [[ "${MODO}" == "inicio" ]]; then
    :
elif grep -qE "^\+.*🎬 Próximo" <<<"${diff_do_plan}"; then
    verde "② linha 🎬 reescrita nesta sessão (aparece no diff desde ${REF_BASE})"
else
    vermelho "② linha 🎬 INTACTA desde ${REF_BASE} — o baton não foi passado, foi só narrado"
    printf '   linha atual: %s\n' "${linha_baton:0:120}"
fi

# --- ③ O ponto de entrada citado não é tarefa já concluída -------------------------------------
tarefa_citada=$(grep -oE '[0-9]+\.[0-9]+[a-z]?' <<<"${linha_baton}" | head -1)
if [[ -z "${tarefa_citada}" ]]; then
    amarelo "③ a linha 🎬 não cita tarefa no formato N.N — confira o ponto de entrada na mão"
elif grep -qE "^ *- \[x\] ${tarefa_citada//./\\.} " "${PLAN}"; then
    vermelho "③ BATON PODRE: a linha 🎬 manda executar a tarefa ${tarefa_citada}, que está [x]"
elif grep -qE "^ *- \[ \] ${tarefa_citada//./\\.} " "${PLAN}"; then
    verde "③ ponto de entrada ${tarefa_citada} está em aberto ([ ])"
else
    amarelo "③ tarefa ${tarefa_citada} citada na linha 🎬 não achada como checkbox — confira na mão"
fi

# --- ④ O registro de sessões (§8) ganhou a linha desta sessão ----------------------------------
if [[ "${MODO}" == "inicio" ]]; then
    ultima_sessao=""
elif ! grep -qE "${REGEX_LINHA_SESSAO}" "${PLAN}"; then
    amarelo "④ este PLAN não tem tabela de sessões no formato '| N | AAAA-MM-DD |' — confira na mão"
    ultima_sessao=""
elif grep -qE "^\+\| [0-9]+ \| [0-9]{4}" <<<"${diff_do_plan}"; then
    verde "④ registro de sessões ganhou linha nova nesta sessão"
    ultima_sessao=$(grep -oE "${REGEX_LINHA_SESSAO}" "${PLAN}" | tail -1 | grep -oE '[0-9]+' | head -1)
else
    vermelho "④ nenhuma linha nova no registro de sessões — esta sessão não vai existir para a próxima"
    ultima_sessao=$(grep -oE "${REGEX_LINHA_SESSAO}" "${PLAN}" | tail -1 | grep -oE '[0-9]+' | head -1)
fi

# --- ⑤ O apontamento da sessão existe no log global -------------------------------------------
# Uma sessão = uma entrada, com ou sem relatório. Indexar por relatório era o bug: handoff e
# validação nunca geram relatório, então sumiam do apontamento sem erro nenhum.
log_do_escopo="${LOG_DE_APONTAMENTO_DIR}/${SLUG}.md"
if [[ "${MODO}" == "inicio" ]]; then
    :
elif [[ -z "${ultima_sessao}" ]]; then
    amarelo "⑤ sem número de sessão para conferir — confira ${log_do_escopo} na mão"
elif [[ ! -f "${log_do_escopo}" ]]; then
    vermelho "⑤ ${log_do_escopo} não existe — o escopo tem sessões e nenhum apontamento"
elif grep -qE "^\*\*Sessão:\*\* ${ultima_sessao}\b" "${log_do_escopo}"; then
    verde "⑤ apontamento da sessão ${ultima_sessao} presente em ${log_do_escopo}"
else
    vermelho "⑤ sessão ${ultima_sessao} SEM entrada em ${log_do_escopo} — apontamento do dia sai furado"
fi

echo "----------------------------------------------------------------------"
if [[ "${houve_vermelho}" -ne 0 ]]; then
    if [[ "${MODO}" == "inicio" ]]; then
        echo "🔴 BATON PODRE — NÃO execute e NÃO adivinhe a próxima tarefa. Mostre a Tiago o que a"
        echo "   linha 🎬 diz × o que o Board diz, e pergunte. É sintoma de sessão anterior que"
        echo "   gravou a troca de papel só na prosa."
        exit 1
    fi
    echo "🔴 CONFERÊNCIA REPROVADA — não commite. Vermelho é PARADA, não ressalva no relatório."
    exit 1
fi
if [[ "${MODO}" == "inicio" ]]; then
    echo "✅ Baton coerente com o Board. Siga o papel que a linha 🎬 manda."
    exit 0
fi
echo "✅ Conferência mecânica aprovada. Os itens ①-⑧ que ela NÃO cobre (critérios de aceite medidos,"
echo "   Board × checkboxes, in-place, git status, documento de interface) seguem na mão."

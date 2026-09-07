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
#     <slug>      escopo da sessão (coluna `Slug` do AGENTS.md) — ele resolve o caminho do PLAN
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

# Índice de escopos: AGENTS.md primeiro (lido nativamente por Codex E, via `@AGENTS.md`, pelo Claude
# Code), CLAUDE.md depois (projetos instalados antes da unificação). O primeiro que existir e citar o
# slug vence.
readonly INDICES_DE_ESCOPOS=("AGENTS.md" "CLAUDE.md")
# Log de apontamento: default histórico, sobrescrevível para instalação neutra de ferramenta.
readonly LOG_DE_APONTAMENTO_DIR="${SESSAO_WORKLOG_DIR:-${HOME}/.claude/work-log}"
readonly REGEX_LINHA_BATON='^- \*\*🎬 Próximo:\*\*'
readonly REGEX_LINHA_SESSAO='^\| [0-9]+ \| [0-9]{4}-[0-9]{2}-[0-9]{2} \|'
# DATA da última linha do registro de sessões, nos DOIS dialetos (corrigido 2026-09-07):
#   legado  `| 11 | 2026-09-04 | ...`      (com coluna de número)
#   atual   `| 2026-09-04 | B3 | ...`      (o que o PLAN.template.md gera)
# É o que alimenta a porta retroativa do ⑤. Sem ela, o dialeto atual tinha UMA única chave — a data
# de hoje — e portanto nenhuma saída para sessão registrada em dia posterior ao do trabalho.
readonly REGEX_DATA_SESSAO='^\| *([0-9]+ *\| *)?[0-9]{4}-[0-9]{2}-[0-9]{2} *\|'

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
for indice in "${INDICES_DE_ESCOPOS[@]}"; do
    [[ -f "${indice}" ]] || continue
    PLAN=$(grep -E "^\| \`${SLUG}\`" "${indice}" | sed -E 's/.*\]\(([^)]+)\).*/\1/')
    [[ -n "${PLAN}" ]] && break
done
if [[ -z "${PLAN}" || ! -f "${PLAN}" ]]; then
    for candidato in "docs/sessoes/${SLUG}/PLAN.md" "PLAN.md"; do
        [[ -f "${candidato}" ]] && { PLAN="${candidato}"; break; }
    done
fi
if [[ -z "${PLAN}" || ! -f "${PLAN}" ]]; then
    echo "🔴 slug '${SLUG}' não resolve para nenhum PLAN (nem em ${INDICES_DE_ESCOPOS[*]}, nem em" >&2
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
# TOLERANTE A DIALETO + À PROVA DE FALSO POSITIVO (2026-08-29). Duas correções, ambas achadas com
# repro num PLAN real:
#   (a) antes só reconhecia `N.N`, formato que NENHUM template desta skill produz — o item vivia em
#       ⚠️, ou seja, auto-atestado. Passa a aceitar `T1`, `T4.1b`, `B11 / T1` e `11.1`, e casa o
#       checkbox mesmo com markdown em volta (`- [ ] **T1 — ...**`).
#   (b) ids de tarefa SE REPETEM entre blocos (num PLAN real, `T2` aparecia 24× como [x] e 5× como
#       [ ]). Um grep global, nesse caso, acusa "baton podre" sem fundamento — e vermelho é PARADA,
#       então o falso positivo trava toda sessão do repo. Regra: só acusa quando o id é
#       INEQUÍVOCO (aparece como [x] e em nenhum [ ]). Ambíguo ⇒ ⚠️, nunca 🔴. Falha para o lado
#       seguro: deixar passar um baton podre custa uma conferência manual; travar sessão boa custa
#       a sessão inteira.
tarefa_citada=$(grep -oE '\bT[0-9]+(\.[0-9]+)*[a-z]?\b|\b[0-9]+\.[0-9]+[a-z]?\b' <<<"${linha_baton}" | head -1)
if [[ -z "${tarefa_citada}" ]]; then
    amarelo "③ a linha 🎬 não cita tarefa reconhecível (T<N> ou N.N) — confira o ponto de entrada na mão"
else
    tarefa_esc=${tarefa_citada//./\\.}
    # PREFIXO TOLERADO (corrigido 2026-09-07): o id pode vir precedido de marcação — `**`, e os
    # marcadores de tipo que a própria skill manda usar (`🔁 T0 — DoR`, SKILL.md §"Gate por-sessão
    # × marco"). O padrão antigo (`\**${id}`) só engolia asteriscos, então TODO checkbox de gate
    # escrito conforme a documentação caía no ⚠️ "não achada como checkbox" — em qualquer PLAN,
    # sempre. Dois PLANs deste repo já nasciam assim. `[^A-Za-z0-9]*` engole asterisco, emoji e
    # espaço, e para no primeiro alfanumérico, então não atravessa um id vizinho (`B11 / T1`).
    n_feitas=$(grep -cE "^ *- \[x\] +[^A-Za-z0-9]*${tarefa_esc}\b" "${PLAN}" || true)
    n_abertas=$(grep -cE "^ *- \[ \] +[^A-Za-z0-9]*${tarefa_esc}\b" "${PLAN}" || true)
    if [[ "${n_feitas}" -gt 0 && "${n_abertas}" -eq 0 ]]; then
        vermelho "③ BATON PODRE: a linha 🎬 manda executar a tarefa ${tarefa_citada}, que está [x]"
    elif [[ "${n_abertas}" -gt 0 && "${n_feitas}" -eq 0 ]]; then
        verde "③ ponto de entrada ${tarefa_citada} está em aberto ([ ])"
    elif [[ "${n_feitas}" -gt 0 && "${n_abertas}" -gt 0 ]]; then
        amarelo "③ id '${tarefa_citada}' aparece ${n_feitas}× como [x] e ${n_abertas}× como [ ] — reusado"
        printf '   entre blocos, então o portão não decide. Confira na mão QUAL bloco a linha 🎬 cita.\n'
    else
        amarelo "③ tarefa ${tarefa_citada} citada na linha 🎬 não achada como checkbox — confira na mão"
    fi
fi

# --- ④ O registro de sessões ganhou a linha desta sessão ----------------------------------------
# TOLERANTE A DIALETO (corrigido 2026-08-24): antes exigia `| N | AAAA-MM-DD |`, e o PLAN.template.md
# gera `| Data | Bloco(s) | Resumo | Relatório |`, SEM coluna de número — o item nunca disparava, e
# ainda derrubava o ⑤ junto (sem N, o ⑤ virava ⚠️). Aceita agora linha nova começando por número de
# sessão OU por data (AAAA-MM-DD ou DD/MM/AAAA).
ultima_sessao=""
ultima_data_sessao=""
if [[ "${MODO}" == "inicio" ]]; then
    :
elif ! grep -qE '^#+ .*Registro de sessões' "${PLAN}"; then
    amarelo "④ este PLAN não tem seção 'Registro de sessões' — confira na mão"
elif grep -qE '^\+\| *([0-9]+ *\| *[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{4}) *\|' <<<"${diff_do_plan}"; then
    verde "④ registro de sessões ganhou linha nova nesta sessão"
    ultima_sessao=$(grep -oE "${REGEX_LINHA_SESSAO}" "${PLAN}" | tail -1 | grep -oE '[0-9]+' | head -1)
    ultima_data_sessao=$(grep -oE "${REGEX_DATA_SESSAO}" "${PLAN}" | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
else
    vermelho "④ nenhuma linha nova no registro de sessões — esta sessão não vai existir para a próxima"
    ultima_sessao=$(grep -oE "${REGEX_LINHA_SESSAO}" "${PLAN}" | tail -1 | grep -oE '[0-9]+' | head -1)
    ultima_data_sessao=$(grep -oE "${REGEX_DATA_SESSAO}" "${PLAN}" | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
fi

# --- ⑤ O apontamento da sessão existe no log global --------------------------------------------
# Uma sessão = uma entrada, com ou sem relatório. Indexar por relatório era o bug: handoff e
# validação nunca geram relatório, então sumiam do apontamento sem erro nenhum.
# TOLERANTE A DIALETO (corrigido 2026-08-24): a chave principal passa a ser o CABEÇALHO DE HOJE
# (`## [AAAA-MM-DD`), que todo log tem; o número de sessão continua valendo quando existir. Antes o
# item dependia do N vindo do ④, e como o ④ nunca disparava, o ⑤ era ⚠️ permanente.
# ⚠️ ORDEM DO RITUAL: o apontamento é escrito DEPOIS de o usuário validar o commit e ANTES de
# commitar — por isso este item pode ser conferido aqui.
log_do_escopo="${LOG_DE_APONTAMENTO_DIR}/${SLUG}.md"
hoje=$(date +%F)
if [[ "${MODO}" == "inicio" ]]; then
    :
elif [[ ! -f "${log_do_escopo}" ]]; then
    vermelho "⑤ ${log_do_escopo} não existe — o escopo tem sessões e nenhum apontamento"
elif grep -qE "^## \[${hoje}" "${log_do_escopo}"; then
    verde "⑤ apontamento de hoje (${hoje}) presente em ${log_do_escopo}"
elif [[ -n "${ultima_sessao}" ]] && grep -qE "^\*\*Sessão:\*\* ${ultima_sessao}\b" "${log_do_escopo}"; then
    verde "⑤ apontamento da sessão ${ultima_sessao} presente em ${log_do_escopo}"
elif [[ -n "${ultima_data_sessao}" ]] && grep -qE "^## \[${ultima_data_sessao}" "${log_do_escopo}"; then
    # PORTA RETROATIVA (2026-09-07): a entrada não é de hoje, mas casa a DATA da linha que esta
    # sessão acabou de acrescentar ao registro de sessões — é o caso "trabalho de sexta, registro
    # na segunda". Não é brecha: exige que a sessão TENHA escrito a linha no §8 (item ④) e que o
    # log tenha entrada naquela data. Sessão que simplesmente não registrou não casa nenhuma das
    # três portas e segue vermelha.
    verde "⑤ apontamento de ${ultima_data_sessao} presente (registro retroativo; hoje é ${hoje})"
else
    vermelho "⑤ sem entrada de hoje (${hoje}) nem de ${ultima_data_sessao:-<data da sessão>} em ${log_do_escopo} — apontamento do dia sai furado"
fi

# --- ⑥ Contrato de bloco escrito nesta sessão exige ACEITE registrado --------------------------
# POR QUE ESTE ITEM EXISTE
# Em 2026-08-24 uma sessão de Planejador escreveu um contrato inteiro — 17 tarefas e 15 critérios —,
# gravou o baton para ⚙️ Executor e commitou DUAS vezes sem o usuário ter visto o plano. A regra
# ("QUESTIONAMENTO ABERTO = REGISTRO CONGELADO") já estava escrita em TRÊS lugares: AGENTS.md
# §Guardrails, a memória do projeto e a própria skill. Falhou nos três porque nos três é prosa
# auto-atestada — e a conferência mecânica, que roda logo antes do commit, deu VERDE, porque não
# tinha item de aceite. É o mesmo diagnóstico do cabeçalho deste arquivo, agora aplicado ao aval:
# o controle tem de medir o arquivo, não a intenção de quem executa.
# O erro específico a prevenir: confundir "respondi às perguntas do agente" com "aceitei o plano".
#
# DOIS DEFEITOS DA 1ª VERSÃO, CORRIGIDOS EM 2026-08-24 (achados por auditoria, com repro):
#   (a) DIALETO — a detecção só reconhecia `### 📋 Tarefas` e critérios em tabela, formatos do repo
#       onde o item nasceu. O PLAN.template.md escreve `### Tarefas` (sem emoji) e critérios em
#       lista, então em TODO projeto novo o item não disparava e o portão aprovava sem aceite.
#   (b) ACEITE ETERNO — o grep varria o PLAN inteiro, então uma linha de aceite de um bloco antigo
#       deixava o item verde para sempre. Agora o aceite tem de ser NOVO NESTA SESSÃO (vir no diff),
#       exatamente como o item ② faz com a linha 🎬 — que é o único mecanismo já provado.
if [[ "${MODO}" != "inicio" ]]; then
    contrato_novo=0
    checkboxes_novos=$(grep -cE '^\+ *- \[ \] ' <<<"${diff_do_plan}" || true)
    if grep -qE '^\+.*###[[:space:]]*(📋[[:space:]]*)?Tarefas' <<<"${diff_do_plan}" \
       || grep -qE '^\+\| *[A-Za-z][A-Za-z0-9-]*-C[0-9]+ *\|' <<<"${diff_do_plan}" \
       || grep -qE '^\+.*Critérios de aceite' <<<"${diff_do_plan}" \
       || [[ "${checkboxes_novos}" -ge 2 ]]; then
        contrato_novo=1
    fi
    if [[ "${contrato_novo}" -eq 1 ]] && grep -q '⚙️' <<<"${linha_baton}"; then
        if grep -qE '^\+\*\*Aceite:\*\* .+, [0-9]{4}-[0-9]{2}-[0-9]{2}' <<<"${diff_do_plan}"; then
            verde "⑥ contrato novo com aceite registrado NESTA sessão"
        else
            vermelho "⑥ SEM ACEITE: esta sessão escreveu contrato de bloco e passou o baton para ⚙️,"
            printf '   mas o PLAN não ganhou a linha "**Aceite:** <quem>, <AAAA-MM-DD>" nesta sessão.\n'
            printf '   Mostre o plano ao usuário e só commite depois do aceite explícito dele.\n'
            printf '   Responder às perguntas do agente NÃO é aceitar o plano.\n'
        fi
    fi
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
echo "✅ Conferência mecânica aprovada. Os itens que ela NÃO cobre (critérios de aceite medidos,"
echo "   Board × checkboxes, in-place, git status, documento de interface) seguem na mão."

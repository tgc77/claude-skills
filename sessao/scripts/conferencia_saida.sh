#!/usr/bin/env bash
#
# Conferência de saída MECÂNICA — o portão que roda antes de todo commit de fim de sessão
# (`end` / `handoff`). Ver a skill `sessao`: referencia/conferencia.md.
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
#   scripts/conferencia_saida.sh <slug> --estado     # ESTADO: o --inicio + o estado do escopo em JSON
#     <slug>      escopo da sessão (coluna `Slug` do AGENTS.md) — ele resolve o caminho do PLAN
#     <ref-base>  commit em que ESTA sessão começou (`git rev-parse HEAD` no início)
#
# O modo --inicio é a defesa do lado do LEITOR: antes de executar à risca o que o baton manda,
# confere se ele não está podre (mandando refazer tarefa já [x]). Custa 1 segundo e é o que separa
# "entrei no papel certo" de "refiz um bloco inteiro que já estava pronto".
#
# O modo --estado (2026-10-19) faz o mesmo que o --inicio e ainda imprime no stdout o estado do escopo
# em JSON — PLAN, branch, bloco ativo, baton, próxima tarefa aberta, gates 🔁, blockers, apontamento —,
# para o `start` e o `escopos` não dependerem de o modelo (às vezes o barato) interpretar o PLAN
# sozinho. As linhas ✅/⚠️/🔴 vão para o stderr. Os códigos de saída são os do --inicio.
#
# Saída: uma linha por item, ✅ / ⚠️ / 🔴. Qualquer 🔴 ⇒ exit 1 ⇒ NÃO COMMITE.
# ⚠️ = item não aplicável a este PLAN (formato diferente); confira na mão.
#
# O item ⑦ (2026-10-19) só existe em escopo com o módulo OpenSpec — o parâmetro `**OpenSpec**` no
# cabeçalho do PLAN — e chama o CLI `openspec` (ou o que SESSAO_OPENSPEC_BIN apontar) e o `node`.
# Ver referencia/openspec.md.
#
set -o pipefail

# Índice de escopos: AGENTS.md primeiro (lido nativamente por Codex E, via `@AGENTS.md`, pelo Claude
# Code), CLAUDE.md depois (projetos instalados antes da unificação). O primeiro que existir e citar o
# slug vence.
# `CLAUDE.md` é RAMO DE LEGADO deliberado (projetos instalados antes da unificação do índice no
# AGENTS.md). Mesma regra do ramo numerado do REGEX_LINHA_REGISTRO abaixo: não remova como limpeza. Caso 8 do autoteste.
readonly INDICES_DE_ESCOPOS=("AGENTS.md" "CLAUDE.md")
# Log de apontamento: default histórico, sobrescrevível para instalação neutra de ferramenta.
readonly LOG_DE_APONTAMENTO_DIR="${SESSAO_WORKLOG_DIR:-${HOME}/.claude/work-log}"
readonly REGEX_LINHA_BATON='^- \*\*🎬 Próximo:\*\*'
# Linha do registro de sessões (§8), nos DOIS dialetos:
#   atual   `| 2026-09-04 | B3 | ...`      (o que o PLAN.template.md gera; aceita também DD/MM/AAAA)
#   legado  `| 11 | 2026-09-04 | ...`      (com coluna de número)
# ⛔ O RAMO NUMERADO É LEGADO DELIBERADO, CARREGANDO PESO. NÃO REMOVA COMO "código morto".
# O PLAN.template.md não gera mais a coluna de número, mas é ela que dá a chave de sessão aos
# escopos legados, que seguem trabalhando sem migração — decisão do Tiago em 2026-09-07 (poucos
# escopos legados, talvez descontinuados; migrar custaria mais que manter). Coberto pelos casos 14,
# 22 e 23 do autoteste. Se for remover um dia, remova os casos junto e combine antes — não é
# limpeza, é retirada de suporte.
readonly REGEX_LINHA_REGISTRO='^\| *([0-9]+ *\| *)?([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{4}) *\|'
# Módulo OpenSpec (item ⑦): o parâmetro do cabeçalho que liga o módulo e a declaração do contrato.
readonly REGEX_MODULO_OPENSPEC='^\| *\*\*OpenSpec\*\* *\| *ativo'
readonly REGEX_DECLARACAO_OPENSPEC='^ *- \*\*OpenSpec:\*\*'
readonly OPENSPEC_BIN="${SESSAO_OPENSPEC_BIN:-openspec}"

houve_vermelho=0

verde()    { printf '✅ %s\n' "$1"; }
amarelo()  { printf '⚠️  %s\n' "$1"; }
vermelho() { printf '🔴 %s\n' "$1"; houve_vermelho=1; }
apara()    { sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }

if [[ $# -ne 2 ]]; then
    echo "uso: $0 <slug> <ref-base>   |   $0 <slug> --inicio   |   $0 <slug> --estado" >&2
    exit 2
fi
readonly SLUG="$1"
readonly REF_BASE="$2"
case "${REF_BASE}" in
    --inicio) readonly MODO="inicio" ;;
    --estado) readonly MODO="estado" ;;
    *)        readonly MODO="fechamento" ;;
esac
# No --estado, o stdout é só do JSON: as linhas humanas vão para o stderr, e o JSON sai pelo
# descritor 3, que guarda o stdout original.
if [[ "${MODO}" == "estado" ]]; then
    exec 3>&1 1>&2
fi

# --- Resolução do PLAN --------------------------------------------------------------------------
# Ordem: índice de escopos (única fonte que sabe onde mora escopo migrado com pasta ≠ slug) →
# convenção do layout canônico → PLAN na raiz (layout legado, instalação anterior ao multi-escopo).
cd "$(git rev-parse --show-toplevel)" || exit 2
PLAN=""
LINHA_INDICE=""
for indice in "${INDICES_DE_ESCOPOS[@]}"; do
    [[ -f "${indice}" ]] || continue
    PLAN=$(grep -E "^\| \`${SLUG}\`" "${indice}" | sed -E 's/.*\]\(([^)]+)\).*/\1/')
    LINHA_INDICE=$(grep -m1 -E "^\| \`${SLUG}\`" "${indice}")   # só o --estado usa
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
    # PLAN NÃO RASTREADO (corrigido 2026-09-24, com repro): escopo nascido nesta sessão cujo PLAN
    # ainda não passou por `git add`. `git diff <ref>` não enxerga arquivo fora do índice, então o
    # diff saía VAZIO: o ④ acusava a falta de uma linha que existe e o ⑥ nem avaliava o aceite. O
    # portão reprovava do mesmo jeito, mas pelo motivo errado — e mandava o autor consertar o que
    # não estava quebrado. PLAN que não existe na ref-base é, inteiro, desta sessão: compara contra
    # o vazio.
    plan_nao_rastreado=0
    if git ls-files --error-unmatch -- "${PLAN}" >/dev/null 2>&1; then
        diff_do_plan=$(git diff --no-color --no-ext-diff "${REF_BASE}" -- "${PLAN}")
    else
        plan_nao_rastreado=1
        diff_do_plan=$(git diff --no-color --no-ext-diff --no-index -- /dev/null "${PLAN}")
    fi
    echo "PLAN: ${PLAN}   ref-base: $(git rev-parse --short "${REF_BASE}")   modo: fechamento"
else
    diff_do_plan=""
    if [[ "${MODO}" == "estado" ]]; then
        echo "PLAN: ${PLAN}   modo: estado (coerência do baton + JSON no stdout)"
    else
        echo "PLAN: ${PLAN}   modo: início (só a coerência do baton)"
    fi
fi
echo "----------------------------------------------------------------------"
if [[ "${MODO}" == "fechamento" && "${plan_nao_rastreado}" -eq 1 ]]; then
    amarelo "PLAN ainda fora do git (escopo novo nesta sessão) — conferido contra arquivo vazio."
    printf '   Faça `git add %s` antes do commit, senão ele fica de fora.\n' "${PLAN}"
fi

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

# --- ② O baton foi REESCRITO nesta sessão ------------------------------------------------------
# É o item que pega o defeito real: sessão que trabalhou, avançou o ponto de entrada e deixou a
# linha do handoff anterior de pé. Sessão que não mexe no baton não tem o que fechar.
#
# ⚠️ COMPARA O PARÁGRAFO INTEIRO DO BATON — corrigido em 2026-09-08, com repro. Antes ele procurava
# `^\+.*🎬 Próximo` no diff, isto é, só a PRIMEIRA LINHA FÍSICA. Mas o baton é um parágrafo: a linha
# `- **🎬 Próximo:**` mais as continuações indentadas, que carregam ponto de entrada, gates a
# reestabelecer e avisos ao Executor. Enquanto o item olhava só a linha 1, uma sessão que mudasse o
# parágrafo sem tocá-la era reprovada como se não tivesse passado baton nenhum — e a única saída era
# reflowar o texto para empurrar a mudança para cima, ou seja, editar o PLAN para agradar o portão.
# Caso real que motivou a correção: sessão de conferência de handoff que achou uma checagem de pronto
# defeituosa, corrigiu-a e avisou o Executor nas linhas de continuação, mantendo — corretamente —
# papel e ponto de entrada, porque nada tinha sido executado.
extrai_paragrafo_baton() {
    awk '
        /^- \*\*🎬 Próximo:\*\*/            { dentro=1; print; next }
        dentro && /^[[:space:]]+[^[:space:]]/ { print; next }
        dentro                                { exit }
    '
}
if [[ "${MODO}" != "fechamento" ]]; then
    :
else
    baton_agora=$(extrai_paragrafo_baton < "${PLAN}")
    # PLAN ausente na ref-base (escopo nascido nesta sessão) ⇒ base vazia ⇒ difere ⇒ verde.
    baton_base=$(git show "${REF_BASE}:${PLAN}" 2>/dev/null | extrai_paragrafo_baton) || baton_base=""
    if [[ "${baton_agora}" != "${baton_base}" ]]; then
        verde "② baton 🎬 reescrito nesta sessão (parágrafo difere de ${REF_BASE})"
    else
        vermelho "② baton 🎬 INTACTO desde ${REF_BASE} — o baton não foi passado, foi só narrado"
        printf '   linha atual: %s\n' "${linha_baton:0:120}"
    fi
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
coerencia_baton=""   # só o --estado lê: coerente | podre | ambigua | sem_tarefa_citada | nao_achada
if [[ -z "${tarefa_citada}" ]]; then
    coerencia_baton="sem_tarefa_citada"
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
        coerencia_baton="podre"
        vermelho "③ BATON PODRE: a linha 🎬 manda executar a tarefa ${tarefa_citada}, que está [x]"
    elif [[ "${n_abertas}" -gt 0 && "${n_feitas}" -eq 0 ]]; then
        coerencia_baton="coerente"
        verde "③ ponto de entrada ${tarefa_citada} está em aberto ([ ])"
    elif [[ "${n_feitas}" -gt 0 && "${n_abertas}" -gt 0 ]]; then
        coerencia_baton="ambigua"
        amarelo "③ id '${tarefa_citada}' aparece ${n_feitas}× como [x] e ${n_abertas}× como [ ] — reusado"
        printf '   entre blocos, então o portão não decide. Confira na mão QUAL bloco a linha 🎬 cita.\n'
    else
        coerencia_baton="nao_achada"
        amarelo "③ tarefa ${tarefa_citada} citada na linha 🎬 não achada como checkbox — confira na mão"
    fi
fi

# --- ④ O registro de sessões ganhou a linha desta sessão ----------------------------------------
# TOLERANTE A DIALETO (corrigido 2026-08-24): antes exigia `| N | AAAA-MM-DD |`, e o PLAN.template.md
# gera `| Data | Bloco(s) | Resumo | Relatório |`, SEM coluna de número — o item nunca disparava, e
# ainda derrubava o ⑤ junto (sem N, o ⑤ virava ⚠️). Aceita agora linha nova começando por número de
# sessão OU por data (AAAA-MM-DD ou DD/MM/AAAA).
# Chave de cada linha do §8 que ESTA sessão acrescentou — serve ao ④ (houve linha nova?) e ao ⑤
# (cada uma tem apontamento?). A linha acrescentada é localizada pelo NÚMERO dela no PLAN atual,
# lido dos cabeçalhos `@@ … +c,d @@` do diff — nunca pelo conteúdo: duas sessões do mesmo dia podem
# escrever linhas idênticas, e casar por texto dava à linha nova a chave da antiga (achado pelo caso
# 28 do autoteste). mawk: nada de intervalo `{n}` nos regex do awk.
chaves_novas_do_registro() {
    local acrescentadas
    acrescentadas=$(awk '
        /^@@/           { split($3, r, ","); n = substr(r[1], 2) + 0; dentro = 1; next }
        !dentro || /^\\/ { next }
        /^\+/           { print n; n++; next }
        /^-/            { next }
                        { n++ }' <<<"${diff_do_plan}")
    grep -nE "${REGEX_LINHA_REGISTRO}" "${PLAN}" | awk -v acrescentadas="${acrescentadas}" '
        BEGIN { k = split(acrescentadas, v, "\n"); for (i = 1; i <= k; i++) nova[v[i]] = 1 }
        {
            p = index($0, ":"); nr = substr($0, 1, p - 1)
            split(substr($0, p + 1), c, "|"); a = c[2]; gsub(/^ +| +$/, "", a)
            if (a ~ /^[0-9]+$/) chave = a
            else {
                if (split(a, d, "/") == 3) a = d[3] "-" d[2] "-" d[1]
                chave = a "#" (++ordem[a])
            }
            if (nr in nova) print chave
        }'
}
chaves=""
if [[ "${MODO}" != "fechamento" ]]; then
    :
elif ! grep -qE '^#+ .*Registro de sessões' "${PLAN}"; then
    amarelo "④ este PLAN não tem seção 'Registro de sessões' — confira na mão"
else
    chaves=$(chaves_novas_do_registro)
    if [[ -n "${chaves}" ]]; then
        verde "④ registro de sessões ganhou linha nova nesta sessão"
    else
        vermelho "④ nenhuma linha nova no registro de sessões — esta sessão não vai existir para a próxima"
    fi
fi

# --- ⑤ Cada sessão nova do registro tem o SEU apontamento no log global --------------------------
# Uma sessão = uma entrada, com ou sem relatório. Indexar por relatório era o bug: handoff e
# validação nunca geram relatório, então sumiam do apontamento sem erro nenhum.
#
# CHAVE DA SESSÃO — derivada do arquivo, nunca da memória (corrigido 2026-09-24, com repro):
#   dialeto atual   `| 2026-09-04 | B3 | ...`  → chave `2026-09-04#k`  (k = posição da linha entre
#                                                as linhas do §8 com a MESMA data, de cima p/ baixo)
#   dialeto legado  `| 11 | 2026-09-04 | ...`  → chave `11`            (o número da sessão)
# e o log a carrega na linha `**Sessão:** <chave>` logo abaixo do cabeçalho da entrada.
# Antes a porta principal era "existe alguma entrada `## [hoje` no log". Ela aprovava a 2ª sessão
# do dia que não registrou nada, desde que a 1ª tivesse registrado — exatamente a falha que o item
# existe para pegar, num padrão comum (dias de 2-4 sessões no mesmo escopo). E o dialeto atual não
# tinha chave própria: a idempotência do `end` ficava por conta de texto livre ("2026-09-24 · B5
# (2ª sessão)"), que nenhum comando distingue. Agora cada linha que ESTA sessão acrescentou ao §8
# exige a sua chave no log. O caso "trabalho de sexta, registro na segunda" sai de graça: a data
# está na chave. Sessão que não escreveu linha no §8 não tem chave — quem a reprova é o ④.
# ⚠️ ORDEM DO RITUAL: o apontamento é escrito DEPOIS de o usuário validar o commit e ANTES de
# commitar — por isso este item pode ser conferido aqui.
log_do_escopo="${LOG_DE_APONTAMENTO_DIR}/${SLUG}.md"
if [[ "${MODO}" != "fechamento" ]]; then
    :
elif [[ -z "${chaves}" ]]; then
    amarelo "⑤ sem linha nova no registro de sessões, não há chave de sessão a conferir (ver ④)"
elif [[ ! -f "${log_do_escopo}" ]]; then
    vermelho "⑤ ${log_do_escopo} não existe — o escopo tem sessões e nenhum apontamento"
else
    faltando=()
    for chave in ${chaves}; do
        grep -qE "^\*\*Sessão:\*\* ${chave}([^0-9]|$)" "${log_do_escopo}" || faltando+=("${chave}")
    done
    if [[ ${#faltando[@]} -eq 0 ]]; then
        verde "⑤ apontamento de cada sessão nova presente em ${log_do_escopo} (chave: ${chaves//$'\n'/ })"
    else
        vermelho "⑤ falta apontamento em ${log_do_escopo} para:"
        for chave in "${faltando[@]}"; do printf '     **Sessão:** %s\n' "${chave}"; done
        printf '   A chave sai da linha do §8: o nº da sessão, ou <data>#<k> (k = posição da linha entre\n'
        printf '   as de mesma data). Grave-a logo abaixo do cabeçalho da entrada no log.\n'
    fi
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
if [[ "${MODO}" == "fechamento" ]]; then
    contrato_novo=0
    checkboxes_novos=$(grep -cE '^\+ *- \[ \] ' <<<"${diff_do_plan}" || true)
    if grep -qE '^\+.*###[[:space:]]*(📋[[:space:]]*)?Tarefas' <<<"${diff_do_plan}" \
       || grep -qE '^\+\| *[A-Za-z][A-Za-z0-9-]*-C[0-9]+ *\|' <<<"${diff_do_plan}" \
       || grep -qE '^\+.*Critérios de aceite' <<<"${diff_do_plan}" \
       || [[ "${checkboxes_novos}" -ge 2 ]]; then
        contrato_novo=1
    fi
    # '⚙' SEM o seletor de variação U+FE0F (corrigido 2026-10-19): o padrão antigo, '⚙️', exigia o
    # seletor, e um baton escrito "⚙ Executor" — sem ele, como modelos às vezes escrevem — deixava o
    # ⑥ cego, aprovando contrato sem aceite. Este padrão casa as duas grafias. Caso 40 do autoteste.
    if [[ "${contrato_novo}" -eq 1 ]] && grep -q '⚙' <<<"${linha_baton}"; then
        if grep -qE '^\+\*\*Aceite:\*\* .+, [0-9]{4}-[0-9]{2}-[0-9]{2}' <<<"${diff_do_plan}"; then
            verde "⑥ contrato novo com aceite registrado NESTA sessão"
        else
            vermelho "⑥ SEM ACEITE: esta sessão escreveu contrato de bloco e passou o baton para ⚙️,"
            printf '   mas o PLAN não ganhou a linha "**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)" nesta sessão.\n'
            printf '   Mostre o plano ao usuário e só commite depois do aceite explícito dele.\n'
            printf '   Responder às perguntas do agente NÃO é aceitar o plano.\n'
            # FALSO NEGATIVO CONHECIDO (2026-09-11) — aceite REAL que o diff não enxerga.
            # A linha de aceite de dois blocos aceitos pela MESMA pessoa no MESMO dia sai byte a
            # byte idêntica; o `git diff` a trata como contexto e o grep de `^+` acima não acha
            # linha nova. O aceite existe, o portão é que fica cego. Não dá para afrouxar o item
            # (seria a volta do "aceite eterno", defeito (b) acima) — a saída é a linha carregar o
            # identificador do bloco, que é informação que faltava ao registro de qualquer forma:
            # num PLAN que acumula blocos, "**Aceite:** Fulano, 2026-09-11" sozinho não diz a QUAL
            # bloco pertence. Aqui o portão só ENSINA o caminho; continua vermelho, porque a
            # evidência ainda não está no arquivo.
            if grep -qE '^\*\*Aceite:\*\* .+, [0-9]{4}-[0-9]{2}-[0-9]{2}' "${PLAN}" \
               && grep -qE '^\+.*Bloco ativo' <<<"${diff_do_plan}"; then
                printf '\n   ⚠️  DIAGNÓSTICO: o PLAN TEM uma linha de aceite e o bloco ativo mudou nesta\n'
                printf '   sessão. Se esse aceite É desta sessão, ele está invisível ao diff por ser byte a\n'
                printf '   byte IDÊNTICO ao de um bloco anterior (mesma pessoa, mesma data). Identifique o\n'
                printf '   bloco na linha — e aí ela passa a ser linha nova de fato:\n'
                printf '       **Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)\n'
                printf '   Isto NÃO afrouxa o item: torna o aceite deste bloco distinguível do anterior.\n'
            fi
        fi
    fi
fi

# --- ⑦ Módulo OpenSpec: o bloco ativo declara a sua change, e ela está em ordem ----------------
# POR QUE ESTE ITEM EXISTE
# Até a 3.0.0 o que o sistema FAZ não tinha registro vivo: o PLAN guarda a execução (tarefas, baton,
# registro), e o comportamento entregue ficava espalhado em relatórios e no código. A única defesa
# era o item 8 da Conferência (documento de interface), conferido na mão. Com o módulo, cada bloco
# declara no contrato se muda um comportamento de que alguém depende. Se muda, uma change do OpenSpec
# (proposta + delta de specs) é validada antes da execução e arquivada quando o bloco conclui, o que
# funde o delta nas specs vivas; se não muda, o contrato diz por quê. A decisão nunca some em
# silêncio — é ela que este item mede.
#
# Só existe em escopo com o parâmetro `| **OpenSpec** | ativo` no cabeçalho do PLAN, isto é, todo
# escopo que o `init` cria a partir da 3.1.0. Escopo anterior, sem o parâmetro, não tem o item:
# silêncio, como o ⑥ quando não há contrato novo. A validação é a estrita do OpenSpec MENOS o aviso de
# SHALL/MUST: as specs são escritas em português, com DEVE, e o próprio OpenSpec chama aquela regra de
# "boa prática para specs em inglês". Sem o CLI ou o node, change declarada é vermelho: o portão falha
# fechado em vez de aprovar o que não conseguiu conferir. Casos 41 a 50 do autoteste.
secao_do_bloco_ativo() { awk '/^## 🎯 Bloco ativo/ {d = 1; next} d && /^## / {exit} d {print}' "${PLAN}"; }
papel_do_baton() {   # executor | planejador | nada (o template traz os dois, como placeholder)
    if grep -q '⚙' <<<"${linha_baton}" && ! grep -q '🧠' <<<"${linha_baton}"; then
        echo "executor"
    elif grep -q '🧠' <<<"${linha_baton}" && ! grep -q '⚙' <<<"${linha_baton}"; then
        echo "planejador"
    fi
}
# Pendências da change no modo estrito, uma por linha (exit 1), ou nada (exit 0). Exit 2 = a saída do
# CLI não pôde ser lida. A saída é capturada antes do `node`: com pipefail, o exit 1 do validate
# estrito (que reprova até pelo aviso de SHALL/MUST) contaminaria o resultado do filtro.
valida_change_openspec() {
    local json
    json=$(OPENSPEC_TELEMETRY=0 NO_COLOR=1 "${OPENSPEC_BIN}" validate "$1" --type change --strict --json \
           --no-interactive 2>/dev/null)
    printf '%s' "${json}" | node -e '
        let s = "";
        process.stdin.on("data", d => s += d).on("end", () => {
            let item;
            try { item = (JSON.parse(s).items || [])[0]; } catch (e) { process.exit(2); }
            if (!item) process.exit(2);
            const ingles = /should contain SHALL or MUST \(RFC 2119 best practice for English specs\)/;
            const contam = (item.issues || []).filter(i =>
                i.level === "ERROR" || (i.level === "WARNING" && !ingles.test(i.message)));
            for (const i of contam) console.log(`${i.level} ${i.path}: ${i.message}`);
            process.exit(contam.length ? 1 : 0);
        });'
}
secao_ativa=$(secao_do_bloco_ativo)
modulo_openspec=0
grep -qE "${REGEX_MODULO_OPENSPEC}" "${PLAN}" && modulo_openspec=1
declaracao_openspec=""   # change | nao_se_aplica | ausente | fora_do_formato — só com o módulo
change_openspec=""; motivo_openspec=""; situacao_change=""   # situação: aberta | arquivada | inexistente
if [[ "${modulo_openspec}" -eq 1 ]]; then
    linha_decl=$(grep -m1 -E "${REGEX_DECLARACAO_OPENSPEC}" <<<"${secao_ativa}" \
                 | sed -E 's/^ *- \*\*OpenSpec:\*\* *//')
    if [[ -z "${linha_decl}" || "${linha_decl}" == "<"* ]]; then
        declaracao_openspec="ausente"
    elif [[ "${linha_decl}" =~ ^change\ \`([a-z0-9][a-z0-9-]*)\` ]]; then
        declaracao_openspec="change"
        change_openspec="${BASH_REMATCH[1]}"
    elif [[ "${linha_decl}" == "não se aplica"* ]]; then
        declaracao_openspec="nao_se_aplica"
        motivo_openspec=$(sed -E 's/^não se aplica[[:space:]—–:-]*//' <<<"${linha_decl}" | apara)
    else
        declaracao_openspec="fora_do_formato"
    fi
    if [[ -n "${change_openspec}" ]]; then
        if [[ -d "openspec/changes/${change_openspec}" ]]; then
            situacao_change="aberta"
        elif compgen -G "openspec/changes/archive/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-${change_openspec}" \
             >/dev/null; then
            situacao_change="arquivada"
        else
            situacao_change="inexistente"
        fi
    fi
fi
if [[ "${MODO}" == "fechamento" && "${modulo_openspec}" -eq 1 ]]; then
    bloco_concluido=0
    if [[ "$(grep -cE '^ *- \[x\] ' <<<"${secao_ativa}")" -gt 0 \
          && "$(grep -cE '^ *- \[ \] ' <<<"${secao_ativa}")" -eq 0 ]]; then
        bloco_concluido=1
    fi
    case "${declaracao_openspec}" in
        ausente)
            if [[ "$(papel_do_baton)" == "executor" || "${bloco_concluido}" -eq 1 ]]; then
                vermelho "⑦ o contrato do bloco ativo não declara o OpenSpec — escreva nele uma das duas:"
                printf '     - **OpenSpec:** change `<id>`              (o bloco muda comportamento de que alguém depende)\n'
                printf '     - **OpenSpec:** não se aplica — <motivo>   (não muda)\n'
            else
                amarelo "⑦ contrato ainda sem a declaração OpenSpec — ela é cobrada quando o baton passar ao ⚙️"
            fi ;;
        fora_do_formato)
            vermelho "⑦ declaração OpenSpec fora do formato: '${linha_decl:0:80}'"
            printf '   Use "change `<id>`" ou "não se aplica — <motivo>".\n' ;;
        nao_se_aplica)
            if [[ ${#motivo_openspec} -ge 10 && "${motivo_openspec}" != "<"* ]]; then
                verde "⑦ OpenSpec não se aplica a este bloco: ${motivo_openspec:0:90}"
            else
                vermelho "⑦ 'não se aplica' sem o motivo — diga por que o bloco não muda comportamento especificado"
            fi ;;
        change)
            id="${change_openspec}"
            case "${situacao_change}" in
                inexistente)
                    vermelho "⑦ a change \`${id}\` não existe (nem em openspec/changes/, nem arquivada)"
                    printf '   Crie com: openspec new change %s --schema sessao   (referencia/openspec.md)\n' "${id}" ;;
                arquivada)
                    verde "⑦ change \`${id}\` arquivada — o delta já está nas specs vivas" ;;
                aberta)
                    if ! command -v "${OPENSPEC_BIN}" >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
                        vermelho "⑦ a change \`${id}\` não pode ser validada: falta o CLI do OpenSpec ou o node"
                        printf '   O portão falha fechado. Instalação: referencia/openspec.md.\n'
                    elif grep -qE '^skip_specs: *true' "openspec/changes/${id}/.openspec.yaml" 2>/dev/null; then
                        vermelho "⑦ a change \`${id}\` tem skip_specs: true — bloco que não muda spec declara"
                        printf '   "não se aplica — <motivo>" no contrato, em vez de abrir uma change vazia.\n'
                    else
                        pendencias=$(valida_change_openspec "${id}"); rc_validacao=$?
                        if [[ ${rc_validacao} -eq 2 ]]; then
                            vermelho "⑦ a saída do 'openspec validate ${id}' não pôde ser lida — confira a versão do CLI"
                        elif [[ ${rc_validacao} -ne 0 ]]; then
                            vermelho "⑦ a change \`${id}\` não passa na validação:"
                            printf '%s\n' "${pendencias}" | sed 's/^/     /'
                        elif [[ "${bloco_concluido}" -eq 1 ]]; then
                            vermelho "⑦ bloco concluído com a change \`${id}\` ainda aberta — arquive antes do commit:"
                            printf '     openspec archive %s -y      (funde o delta nas specs vivas)\n' "${id}"
                        else
                            verde "⑦ change \`${id}\` válida — arquive quando o bloco concluir"
                        fi
                    fi ;;
            esac ;;
    esac
fi

# --- Estado do escopo em JSON (só no --estado) ---------------------------------------------------
# Lê só o que o `start` e o `escopos` precisam: a linha do índice, o cabeçalho de parâmetros, o
# "🔎 Agora", a seção do bloco ativo e o §8. Campo que este PLAN não tem (dialeto antigo) sai como
# null — nunca inventado.
json_str() {   # "$1" como string JSON; vazio vira null
    local s="$1"
    if [[ -z "${s}" ]]; then printf 'null'; return; fi
    s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; s=${s//$'\r'/}; s=${s//$'\n'/\\n}
    printf '"%s"' "${s}"
}
campo_do_agora() {   # o texto depois de `- **<rótulo>:**`, sem os asteriscos de negrito
    grep -m1 -E "^- \*\*$1:\*\*" "${PLAN}" | sed -E "s/^- \*\*$1:\*\* *//; s/\*\*//g" | apara
}
emite_estado_json() {
    local escopo="" estado_indice="" branch papel="" ponto="" texto_baton coerencia
    local secao feitas="null" abertas="null" proxima="" gates="null" g lista="" log existe="false"
    if [[ -n "${LINHA_INDICE}" ]]; then
        escopo=$(awk -F'|' '{print $3}' <<<"${LINHA_INDICE}" | apara)
        estado_indice=$(awk -F'|' '{print $4}' <<<"${LINHA_INDICE}" | apara)
    fi
    branch=$(grep -m1 -E '^\| *\*\*Branch de trabalho\*\* *\|' "${PLAN}" | awk -F'|' '{print $3}' \
             | tr -d '`' | apara)
    papel=$(papel_do_baton)
    if grep -q '\*\*Ponto de entrada:\*\*' <<<"${linha_baton}"; then
        ponto=$(sed -E 's/.*\*\*Ponto de entrada:\*\* *//; s/\*\*//g' <<<"${linha_baton}" | apara)
    fi
    texto_baton=$(sed -E 's/^- \*\*🎬 Próximo:\*\* *//; s/\*\*//g' <<<"${linha_baton}" | apara)
    case "${linhas_baton}" in
        0) coerencia="sem_baton" ;;
        1) coerencia="${coerencia_baton}" ;;
        *) coerencia="duplicado" ;;
    esac
    # Seção do bloco ativo: do `## 🎯 Bloco ativo` até o próximo `## `.
    if grep -q '^## 🎯 Bloco ativo' "${PLAN}"; then
        secao="${secao_ativa}"
        feitas=$(grep -cE '^ *- \[x\] ' <<<"${secao}")
        abertas=$(grep -cE '^ *- \[ \] ' <<<"${secao}")
        proxima=$(grep -m1 -E '^ *- \[ \] ' <<<"${secao}" | sed -E 's/^ *- \[ \] +//; s/\*\*//g')
        while IFS= read -r g; do
            [[ -n "${g}" ]] && lista+="${lista:+, }$(json_str "${g}")"
        done < <(grep -E '^ *- 🔁' <<<"${secao}" | sed -E 's/^ *- +//; s/\*\*//g')
        gates="[${lista}]"
    fi
    log="${LOG_DE_APONTAMENTO_DIR}/${SLUG}.md"
    [[ -f "${log}" ]] && existe="true"
    cat <<JSON
{
  "slug": $(json_str "${SLUG}"),
  "plan": $(json_str "${PLAN}"),
  "escopo": $(json_str "${escopo}"),
  "estado_no_indice": $(json_str "${estado_indice}"),
  "branch_de_trabalho": $(json_str "${branch}"),
  "ultima_atualizacao": $(json_str "$(campo_do_agora 'Última atualização')"),
  "bloco_ativo": $(json_str "$(campo_do_agora 'Bloco ativo')"),
  "blockers": $(json_str "$(campo_do_agora 'Blockers')"),
  "baton": {
    "linhas": ${linhas_baton},
    "texto": $(json_str "${texto_baton}"),
    "papel": $(json_str "${papel}"),
    "ponto_de_entrada": $(json_str "${ponto}"),
    "tarefa_citada": $(json_str "${tarefa_citada}"),
    "coerencia": $(json_str "${coerencia}")
  },
  "tarefas_do_bloco_ativo": {
    "concluidas": ${feitas},
    "abertas": ${abertas},
    "proxima_aberta": $(json_str "${proxima}"),
    "gates": ${gates}
  },
  "sessoes_no_registro": $(grep -cE "${REGEX_LINHA_REGISTRO}" "${PLAN}"),
  "apontamento": { "log": $(json_str "${log}"), "existe": ${existe} },
  "openspec": {
    "modulo": $([[ "${modulo_openspec}" -eq 1 ]] && echo true || echo false),
    "declaracao": $(json_str "${declaracao_openspec}"),
    "change": $(json_str "${change_openspec}"),
    "situacao": $(json_str "${situacao_change}"),
    "motivo": $(json_str "${motivo_openspec}")
  }
}
JSON
}

echo "----------------------------------------------------------------------"
if [[ "${MODO}" == "estado" ]]; then
    emite_estado_json >&3
fi
if [[ "${houve_vermelho}" -ne 0 ]]; then
    if [[ "${MODO}" != "fechamento" ]]; then
        echo "🔴 BATON PODRE — NÃO execute e NÃO adivinhe a próxima tarefa. Mostre a Tiago o que a"
        echo "   linha 🎬 diz × o que o Board diz, e pergunte. É sintoma de sessão anterior que"
        echo "   gravou a troca de papel só na prosa."
        exit 1
    fi
    echo "🔴 CONFERÊNCIA REPROVADA — não commite. Vermelho é PARADA, não ressalva no relatório."
    exit 1
fi
if [[ "${MODO}" != "fechamento" ]]; then
    echo "✅ Baton coerente com o Board. Siga o papel que a linha 🎬 manda."
    exit 0
fi
echo "✅ Conferência mecânica aprovada. Os itens que ela NÃO cobre (critérios de aceite medidos,"
echo "   Board × checkboxes, in-place, git status, documento de interface) seguem na mão."

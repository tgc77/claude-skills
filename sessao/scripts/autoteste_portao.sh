#!/usr/bin/env bash
#
# Autoteste do portão `conferencia_saida.sh` — o controle do controle.
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# Em 2026-08-24 uma auditoria descobriu que o portão fazia valer apenas 2 dos seus 6 itens em
# qualquer projeto novo. A causa não era um erro de lógica: era que o portão foi escrito contra o
# DIALETO de um repositório específico (`### 📋 Tarefas`, critérios em tabela, registro de sessões
# com coluna de número) enquanto o `PLAN.template.md` desta mesma skill gera OUTRO dialeto
# (`### Tarefas`, critérios em lista, registro sem número). Nada validava que os dois concordassem.
# O resultado é a pior forma de falha: os itens ③④⑤ imprimiam ⚠️ ("não aplicável"), o ⑥ não
# imprimia nada, e o portão saía com exit 0 — dizendo "aprovado" sem ter conferido quase nada.
#
# Este script fecha esse buraco: monta um repositório descartável A PARTIR DOS TEMPLATES e afirma
# que cada item dispara quando deve. Se alguém mudar o template ou o portão e os dois deixarem de
# se entender, este teste reprova — que é exatamente o sinal que faltou em 2026-08-24.
#
# USO
#   scripts/autoteste_portao.sh            # exit 0 = portão íntegro; exit 1 = regressão
#
set -o pipefail

falhas=0
titulo() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()     { printf '  ✅ %s\n' "$1"; }
nok()    { printf '  🔴 %s\n' "$1"; falhas=$((falhas + 1)); }

SKILL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SKILL_SCRIPTS
SKILL_TEMPLATES="$(cd "${SKILL_SCRIPTS}/../templates" && pwd)"
readonly SKILL_TEMPLATES
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "${TMP}"' EXIT
HOJE="$(date +%F)"
readonly HOJE

# Monta um repo limpo a partir dos templates e seta BASE (global).
# ⚠️ NÃO chamar com $(montar): em subshell o `cd` não persiste no processo de teste.
montar() {
    rm -rf "${TMP}/repo" "${TMP}/lar"
    mkdir -p "${TMP}/repo/docs/sessoes/teste" "${TMP}/repo/scripts" "${TMP}/lar/.claude/work-log"
    cd "${TMP}/repo" || exit 2
    git init -q
    git config user.email autoteste@local
    git config user.name autoteste
    cp "${SKILL_SCRIPTS}/conferencia_saida.sh" scripts/
    chmod +x scripts/conferencia_saida.sh
    cp "${SKILL_TEMPLATES}/PLAN.template.md" docs/sessoes/teste/PLAN.md
    {
        printf '| Slug | Escopo | Estado | PLAN |\n|---|---|---|---|\n'
        printf '| `teste` | escopo de teste | 🟡 Ativo | [PLAN](docs/sessoes/teste/PLAN.md) |\n'
    } > "${INDICE:-AGENTS.md}"
    garantir_sandbox
    git add -A
    git commit -qm base
    BASE="$(git rev-parse HEAD)"
    P=docs/sessoes/teste/PLAN.md
}

# Variante LEGADA: PLAN.md na raiz + índice em CLAUDE.md — layout dos projetos instalados antes do
# modelo multi-escopo. Tiago decidiu em 2026-09-07 NÃO migrá-los, então este caminho é suporte vivo
# e precisa de teste, não resquício.
montar_legado() {
    rm -rf "${TMP}/repo" "${TMP}/lar"
    mkdir -p "${TMP}/repo/scripts" "${TMP}/lar/.claude/work-log"
    cd "${TMP}/repo" || exit 2
    git init -q
    git config user.email autoteste@local
    git config user.name autoteste
    cp "${SKILL_SCRIPTS}/conferencia_saida.sh" scripts/
    chmod +x scripts/conferencia_saida.sh
    cp "${SKILL_TEMPLATES}/PLAN.template.md" PLAN.md
    if [[ -n "${SEM_INDICE:-}" ]]; then
        # Repo legado MONO-ESCOPO: CLAUDE.md tem o protocolo, mas nenhuma tabela de escopos —
        # a tabela é conceito do modelo multi-escopo. Aqui o PLAN só resolve pelo FALLBACK.
        printf '# CLAUDE.md legado (protocolo inline, sem tabela de escopos)\n' > CLAUDE.md
    else
        {
            printf '| Slug | Escopo | Estado | PLAN |\n|---|---|---|---|\n'
            printf '| `teste` | escopo legado | 🟡 Ativo | [PLAN](PLAN.md) |\n'
        } > CLAUDE.md
    fi
    garantir_sandbox
    git add -A
    git commit -qm base
    BASE="$(git rev-parse HEAD)"
    P=PLAN.md
}

# ⛔ TRAVA DE SANDBOX — nasceu de um acidente real (2026-08-28): na 1ª versão deste script `montar`
# era chamado com $(montar), o `cd` ficava preso no subshell, e o cenário 3 rodou `git add -A` +
# `git commit` NO REPO DA SKILL, criando um commit com a mensagem de teste. Toda operação de git de
# escrita passa a exigir que o diretório corrente seja o repo descartável.
garantir_sandbox() {
    if [[ "${PWD}" != "${TMP}/repo" ]]; then
        echo "🔴 ABORTADO: o autoteste tentou operar git fora do sandbox (${PWD})." >&2
        echo "   Isso commitaria no repositório real. Verifique se montar() foi chamada em subshell." >&2
        exit 2
    fi
}

# Rodar o portão com um HOME falso, para não encostar no work-log real do usuário.
rodar() { HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste "$1" 2>&1; }

P=docs/sessoes/teste/PLAN.md

baton_para()   { python3 - "${P}" "$1" <<'PY'
import io,re,sys
f=sys.argv[1]; s=io.open(f,encoding='utf-8').read()
s=re.sub(r'^- \*\*🎬 Próximo:\*\*.*$', '- **🎬 Próximo:** '+sys.argv[2], s, count=1, flags=re.M)
io.open(f,'w',encoding='utf-8').write(s)
PY
}
escrever_contrato() { python3 - "${P}" <<'PY'
import io,sys
f=sys.argv[1]; s=io.open(f,encoding='utf-8').read()
s=s.replace('- [ ] <tarefa-marco atômica com uma checagem de pronto>',
            '- [ ] **T1 — primeira tarefa** com checagem\n- [ ] **T2 — segunda tarefa** com checagem')
io.open(f,'w',encoding='utf-8').write(s)
PY
}
concluir_t1() { sed -i 's/^- \[ \] \*\*T1 —/- [x] **T1 —/' "${P}"; }
linha_de_sessao() { printf '| %s | B1 | sessão de teste | — |\n' "${HOJE}" >> "${P}"; }
aceite()          { printf '\n**Aceite:** Fulano, %s\n' "${HOJE}" >> "${P}"; }
apontamento()     { printf '## [%s 10:00] teste\n\n**Sessão:** 1\n' "${HOJE}" > "${TMP}/lar/.claude/work-log/teste.md"; }

# ------------------------------------------------------------------------------------------------
titulo "1. Baton INTACTO desde o início da sessão ⇒ ② vermelho, exit 1"
montar
escrever_contrato; linha_de_sessao; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ② baton 🎬 INTACTO' <<<"${saida}" && ok "② acusou baton intacto" || nok "② NÃO acusou baton intacto"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — deveria reprovar"

titulo "2. Contrato novo + baton ⚙️ SEM aceite ⇒ ⑥ vermelho (o defeito de 2026-08-24)"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ exigiu o aceite" || nok "⑥ NÃO disparou — portão aprovaria plano não validado"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — deveria reprovar"

titulo "3. Aceite ANTIGO, já commitado (fora do diff) ⇒ ⑥ continua vermelho (regressão F8)"
montar
aceite; garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 3"; BASE_ANTIGO="$(git rev-parse HEAD)"
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; apontamento
saida="$(rodar "${BASE_ANTIGO}")"
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "aceite velho não vale para contrato novo" || nok "aceite velho aprovou contrato novo — F8 voltou"

titulo "4. Sessão correta e completa ⇒ tudo verde, exit 0"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; aceite; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
for item in '✅ ①' '✅ ②' '✅ ③' '✅ ④' '✅ ⑤' '✅ ⑥'; do
    grep -q "${item}" <<<"${saida}" && ok "${item} verde" || { nok "${item} NÃO ficou verde"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
done
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit != 0 — sessão correta foi reprovada"

titulo "5. Baton apontando tarefa já [x] ⇒ ③ vermelho (baton podre)"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
concluir_t1; linha_de_sessao; aceite; apontamento
saida="$(rodar "${BASE}")"
grep -q '🔴 ③ BATON PODRE' <<<"${saida}" && ok "③ acusou ponto de entrada já concluído" || nok "③ NÃO acusou baton podre"

titulo "6. Sem apontamento no log ⇒ ⑤ vermelho"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; aceite
saida="$(rodar "${BASE}")"
grep -q '🔴 ⑤' <<<"${saida}" && ok "⑤ acusou falta de apontamento" || nok "⑤ NÃO acusou falta de apontamento"

titulo "7. Sem linha nova no registro de sessões ⇒ ④ vermelho"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
aceite; apontamento
saida="$(rodar "${BASE}")"
grep -q '🔴 ④' <<<"${saida}" && ok "④ acusou registro de sessões parado" || nok "④ NÃO acusou registro parado"

titulo "8. Índice em AGENTS.md (novo) e em CLAUDE.md (legado) ⇒ os dois resolvem o PLAN"
montar   # monta com AGENTS.md
saida="$(rodar "${BASE}")"
grep -q 'PLAN: docs/sessoes/teste/PLAN.md' <<<"${saida}" && ok "índice em AGENTS.md resolve" || nok "índice em AGENTS.md NÃO resolve"
INDICE=CLAUDE.md montar
saida="$(rodar "${BASE}")"
grep -q 'PLAN: docs/sessoes/teste/PLAN.md' <<<"${saida}" && ok "índice em CLAUDE.md (legado) resolve" || nok "fallback CLAUDE.md quebrou — projetos antigos param de funcionar"

titulo "9. Id de tarefa REUSADO entre blocos ⇒ ③ amarelo, NUNCA vermelho (regressão 2026-08-29)"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
# simula um PLAN com vários blocos: o mesmo id T1 existe concluído em outro bloco
printf '\n## Bloco anterior\n\n- [x] **T1 — mesma numeração, outro bloco**\n' >> "${P}"
linha_de_sessao; aceite; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ③ BATON PODRE' <<<"${saida}" && nok "③ acusou baton podre com id ambíguo — FALSO POSITIVO trava a sessão" || ok "③ não acusou baton podre com id ambíguo"
grep -q '⚠️  ③ id' <<<"${saida}" && ok "③ avisou da ambiguidade" || nok "③ não avisou da ambiguidade"
[[ "${codigo}" -eq 0 ]] && ok "exit 0 — sessão legítima não foi travada" || nok "exit != 0 — falso positivo bloqueou o commit"

titulo "10. Checkbox de GATE (🔁 T0) ⇒ ③ verde (regressão 2026-09-07)"
# A skill manda escrever gate por-sessão como `🔁 T0 — DoR` (SKILL.md, "Gate por-sessão × marco").
# O ③ casava o id logo após `- [ ] **`, então TODO checkbox escrito conforme a documentação caía
# em ⚠️ "não achada como checkbox" — em qualquer PLAN, sempre. A convenção e o parser diziam
# coisas diferentes, e nenhum teste cobria isso.
montar
escrever_contrato
printf '\n- [ ] **🔁 T0 — gate por-sessão** reestabelecer o ambiente\n' >> "${P}"
baton_para '⚙️ Executor · **Ponto de entrada:** T0 — gate por-sessão'
linha_de_sessao; aceite; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '✅ ③ ponto de entrada T0 está em aberto' <<<"${saida}" && ok "③ leu o id atrás do marcador 🔁" || { nok "③ NÃO reconheceu checkbox de gate — convenção e parser divergiram de novo"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit != 0 — checkbox de gate reprovou sessão legítima"

titulo "11. Registro RETROATIVO ⇒ ⑤ verde pela data da linha do §8 (regressão 2026-09-07)"
# Trabalho feito na sexta, apontamento pedido na segunda. O ⑤ só tinha a porta "entrada de hoje"
# (a porta por número de sessão é do dialeto legado e nunca dispara no template atual), então
# fechamento em dia posterior era vermelho permanente, sem saída nenhuma.
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
ONTEM="$(date -d '3 days ago' +%F 2>/dev/null || date -v-3d +%F)"
printf '| %s | B1 | sessão de sexta | — |\n' "${ONTEM}" >> "${P}"
aceite
printf '## [%s 20:45] teste\n\n**Sessão:** 1\n' "${ONTEM}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q "✅ ⑤ apontamento de ${ONTEM} presente (registro retroativo" <<<"${saida}" && ok "⑤ aceitou o registro retroativo" || { nok "⑤ NÃO aceitou registro retroativo"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit != 0 — fechamento retroativo legítimo travado"

titulo "12. Retroativo NÃO é brecha: sem apontamento nenhum ⇒ ⑤ continua vermelho"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
ONTEM="$(date -d '3 days ago' +%F 2>/dev/null || date -v-3d +%F)"
printf '| %s | B1 | sessão de sexta | — |\n' "${ONTEM}" >> "${P}"
aceite
: > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ⑤' <<<"${saida}" && ok "⑤ seguiu vermelho sem apontamento" || nok "⑤ passou SEM apontamento — a porta retroativa virou brecha"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — commitaria sem apontamento"

titulo "13. LANÇADOR: resolve a skill, e falha FECHADA quando não acha (2026-09-07)"
# O projeto instala um lançador, não uma cópia — senão correção na skill não alcança escopo já
# instalado. Um lançador que falhe ABERTO (exit 0) seria pior que a cópia velha: daria verde.
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; aceite; apontamento
cp "${SKILL_SCRIPTS}/conferencia_saida.shim.sh" scripts/conferencia_saida.sh
chmod +x scripts/conferencia_saida.sh
saida="$(HOME="${TMP}/lar" SESSAO_SKILL_DIR="$(dirname "${SKILL_SCRIPTS}")" ./scripts/conferencia_saida.sh teste "${BASE}" 2>&1)"; codigo=$?
grep -q 'PLAN: docs/sessoes/teste/PLAN.md' <<<"${saida}" && ok "lançador resolveu a skill e rodou o portão" || { nok "lançador NÃO resolveu a skill"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0 pelo portão real" || nok "exit != 0"
HOME=/nao/existe SESSAO_SKILL_DIR=/nao/existe CLAUDE_CONFIG_DIR=/nao/existe CODEX_HOME=/nao/existe \
  ./scripts/conferencia_saida.sh teste "${BASE}" >/dev/null 2>&1
codigo=$?
[[ "${codigo}" -eq 2 ]] && ok "sem skill: exit 2 (não rodou), nunca 0" || nok "sem skill: exit ${codigo} — deveria ser 2; exit 0 seria aprovação falsa"


titulo "14. Dialeto LEGADO (| N | data |) ⇒ ⑤ verde pela porta 2 (número da sessão)"
# Escopo legado NÃO vai ser migrado (decisão do Tiago, 2026-09-07): a porta 2 é o que o mantém
# funcionando, então ela carrega peso e precisa de teste. Ela já morreu em silêncio uma vez — a
# correção de 2026-08-24 tornou o ④ tolerante ao dialeto novo e deixou o alimentador dela no regex
# velho, e ninguém percebeu até 2026-09-07.
# ⚠️ AS DUAS DATAS SÃO DIFERENTES DE PROPÓSITO. Se a data do apontamento casasse a da linha do §8,
# a porta 3 (retroativa) atenderia primeiro e este teste passaria sem exercitar a porta 2 — um
# teste que passa sem provar nada é pior que nenhum. Aqui: hoje ≠ data do §8 ≠ data do log, e só
# o número da sessão casa.
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
D_SESSAO="$(date -d '10 days ago' +%F 2>/dev/null || date -v-10d +%F)"
D_LOG="$(date -d '20 days ago' +%F 2>/dev/null || date -v-20d +%F)"
printf '| 7 | %s | sessão em repo legado | — |\n' "${D_SESSAO}" >> "${P}"
aceite
printf '## [%s 09:00] teste\n\n**Sessão:** 7\n' "${D_LOG}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '✅ ⑤ apontamento da sessão 7 presente' <<<"${saida}" && ok "⑤ casou pelo número da sessão (porta 2 viva)" || { nok "⑤ NÃO casou pela porta 2 — suporte a escopo legado quebrou"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
grep -q 'registro retroativo' <<<"${saida}" && nok "passou pela porta 3, não pela 2 — o teste não prova o legado" || ok "não caiu na porta 3 (isolamento correto)"
[[ "${codigo}" -eq 0 ]] && ok "exit 0 — escopo legado segue trabalhando" || nok "exit != 0 — escopo legado foi travado"


# ════════════════════════════════════════════════════════════════════════════════════════════════
# GATILHOS DO ⑥ — casos 15-17 (auditoria de cobertura, 2026-09-07)
# O ⑥ tem QUATRO gatilhos alternativos para "esta sessão escreveu contrato"; até aqui o autoteste
# exercitava só o quarto (≥2 checkboxes novos), porque é o que escrever_contrato() produz. Os
# outros três nunca rodaram — e não é detalhe teórico: no contrato real do B3, em 2026-09-07, quem
# disparou primeiro foi o gatilho `### Tarefas`. O caminho que os PLANs reais percorrem não era o
# coberto. Se um gatilho parar de casar, o efeito é VERDE FALSO no item que guarda o aceite — o
# defeito de 2026-08-24 de volta, com os outros três gatilhos dizendo que está tudo bem.
# Cada caso abaixo isola UM gatilho: os demais não podem casar, senão o teste passa sem prová-lo.
# ════════════════════════════════════════════════════════════════════════════════════════════════

titulo "15. ⑥ gatilho '### Tarefas' SOZINHO (1 só checkbox) ⇒ vermelho sem aceite"
montar
baton_para '⚙️ Executor · **Ponto de entrada:** T9 — nova'
printf '\n### 📋 Tarefas\n\n- [ ] **T9 — nova**\n' >> "${P}"   # 1 checkbox: gatilho 4 NÃO casa
linha_de_sessao; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ disparou pelo cabeçalho de Tarefas" || { nok "⑥ NÃO disparou — contrato passaria sem aceite"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — commitaria contrato sem aceite"

titulo "16. ⑥ gatilho tabela de critérios (B1-C1) SOZINHO (zero checkbox) ⇒ vermelho sem aceite"
montar
baton_para '⚙️ Executor · **Ponto de entrada:** T9 — nova'
printf '\n| B1-C1 | comando de medição | alvo |\n' >> "${P}"   # nenhum checkbox novo
linha_de_sessao; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ disparou pela tabela de critérios" || { nok "⑥ NÃO disparou pela tabela"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — commitaria contrato sem aceite"

titulo "17. ⑥ gatilho 'Critérios de aceite' SOZINHO (1 só checkbox) ⇒ vermelho sem aceite"
montar
baton_para '⚙️ Executor · **Ponto de entrada:** T9 — nova'
printf '\n### Critérios de aceite\n\n- [ ] **T9 — nova**\n' >> "${P}"
linha_de_sessao; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ disparou pelo texto de critérios" || { nok "⑥ NÃO disparou pelo texto de critérios"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — commitaria contrato sem aceite"

# ════════════════════════════════════════════════════════════════════════════════════════════════
# MODO --inicio — casos 18-19 (auditoria de cobertura, 2026-09-07)
# É a defesa do lado do LEITOR, que o AGENTS.md manda rodar em TODO `start`: antes de obedecer ao
# baton, confere se ele não manda refazer tarefa já [x]. Era o modo mais executado do portão e
# tinha ZERO cobertura — se regredisse, pararia de proteger em silêncio.
# ════════════════════════════════════════════════════════════════════════════════════════════════

titulo "18. --inicio com baton PODRE ⇒ ③ vermelho, exit 1 (sessão não deve executar)"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
concluir_t1
saida="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --inicio 2>&1)"; codigo=$?
grep -q '🔴 ③ BATON PODRE' <<<"${saida}" && ok "③ acusou baton podre já no início" || { nok "③ NÃO acusou no --inicio — sessão refaria bloco pronto"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — o leitor seguiria executando"

titulo "19. --inicio com baton SAUDÁVEL ⇒ exit 0, e ④⑤⑥ nem são avaliados"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
saida="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --inicio 2>&1)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "exit 0 — início legítimo não é travado" || { nok "exit != 0 — início legítimo travado"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
grep -qE '④|⑤|⑥' <<<"${saida}" && nok "④/⑤/⑥ avaliados no --inicio — eles dependem de diff e apontamento, que no início não existem" || ok "④⑤⑥ corretamente fora do modo início"

# ════════════════════════════════════════════════════════════════════════════════════════════════
# ① — casos 20-21 (auditoria de cobertura, 2026-09-07)
# Só o ramo "1 linha 🎬" tinha cobertura. Os outros dois falhariam em VERDE FALSO: baton ausente
# deixa a próxima sessão sem papel, e baton duplicado é a violação literal do invariante
# anti-duplicação ("cada fato mora em um arquivo; atualize in-place").
# ════════════════════════════════════════════════════════════════════════════════════════════════

titulo "20. NENHUMA linha 🎬 no PLAN ⇒ ① vermelho"
montar
escrever_contrato
python3 - "${P}" <<'PYINNER'
import io,re,sys
f=sys.argv[1]; s=io.open(f,encoding='utf-8').read()
io.open(f,'w',encoding='utf-8').write(re.sub(r'^- \*\*🎬 Próximo:\*\*.*$','',s,flags=re.M))
PYINNER
linha_de_sessao; aceite; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ① nenhuma linha' <<<"${saida}" && ok "① acusou baton ausente" || nok "① NÃO acusou baton ausente"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — próxima sessão ficaria sem papel"

titulo "21. DUAS linhas 🎬 no PLAN ⇒ ① vermelho (invariante anti-duplicação)"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
printf '\n- **🎬 Próximo:** 🧠 Planejador · **Ponto de entrada:** outra coisa\n' >> "${P}"
linha_de_sessao; aceite; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ① 2 linhas 🎬' <<<"${saida}" && ok "① acusou baton duplicado" || nok "① NÃO acusou duas cópias do mesmo estado"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — duas fontes de verdade passariam"

titulo "22. Legado COM índice: CLAUDE.md aponta para PLAN.md na raiz ⇒ tudo verde"
# Escopo legado não será migrado (Tiago, 2026-09-07). Se a resolução do PLAN na raiz quebrar, o
# portão nem acha o arquivo e o repo legado para de conseguir fechar sessão.
montar_legado
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
printf '| 3 | %s | sessão legada | — |\n' "${HOJE}" >> "${P}"
aceite
printf '## [%s 10:00] teste\n\n**Sessão:** 3\n' "${HOJE}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q 'PLAN: PLAN.md' <<<"${saida}" && ok "resolveu o PLAN na raiz" || { nok "NÃO resolveu PLAN.md na raiz — repo legado não fecha sessão"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
for item in '✅ ①' '✅ ②' '✅ ③' '✅ ④' '✅ ⑤' '✅ ⑥'; do
    grep -q "${item}" <<<"${saida}" || nok "${item} não ficou verde no layout legado"
done
[[ "${codigo}" -eq 0 ]] && ok "exit 0 — escopo legado fecha sessão normalmente" || nok "exit != 0 — escopo legado travado"


titulo "23. Legado SEM índice: PLAN.md na raiz só pelo FALLBACK ⇒ tudo verde"
# Repo mono-escopo antigo: o CLAUDE.md traz o protocolo mas não tem tabela de escopos (ela é do
# modelo multi-escopo). O slug não casa em índice nenhum, e o PLAN só é achado pela lista de
# candidatos — `docs/sessoes/<slug>/PLAN.md`, depois `PLAN.md`. Este é o caminho MAIS provável num
# repo legado de verdade, e o caso 22 não o exercita: lá o índice resolve antes.
SEM_INDICE=1 montar_legado
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
printf '| 4 | %s | sessão legada sem índice | — |\n' "${HOJE}" >> "${P}"
aceite
printf '## [%s 10:00] teste\n\n**Sessão:** 4\n' "${HOJE}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q 'PLAN: PLAN.md' <<<"${saida}" && ok "fallback achou PLAN.md na raiz sem índice" || { nok "fallback NÃO achou o PLAN — repo legado mono-escopo não fecha sessão"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit != 0 — legado sem índice travado"


titulo "24. Mudança SÓ nas linhas de continuação do baton ⇒ ② verde (o defeito de 2026-09-08)"
# Sessão que corrige o contrato e avisa o Executor no baton, mantendo papel e ponto de entrada
# porque nada foi executado. Enquanto o ② olhava só a 1ª linha física, isto era reprovado — e a
# única saída era reflowar o PLAN para agradar o portão.
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; aceite; apontamento
garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 24"; BASE_CONT="$(git rev-parse HEAD)"
# a sessão seguinte NÃO toca a linha 🎬 — só acrescenta uma continuação indentada a ela
python3 - "${P}" <<'PY'
import io,re,sys
f=sys.argv[1]; s=io.open(f,encoding='utf-8').read()
s=re.sub(r'^(- \*\*🎬 Próximo:\*\*.*)$',
         r'\1\n  ⚠️ a T2 mudou nesta sessão: use a checagem escrita hoje na tarefa.',
         s, count=1, flags=re.M)
io.open(f,'w',encoding='utf-8').write(s)
PY
linha_de_sessao; printf '## [%s 11:00] teste\n\n**Sessão:** 2\n' "${HOJE}" >> "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE_CONT}")"; codigo=$?
grep -q '✅ ②' <<<"${saida}" && ok "② aceitou mudança em linha de continuação" || { nok "② reprovou baton REALMENTE reescrito — o defeito de 2026-09-08 voltou"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit != 0"; printf '%s\n' "${saida}" | sed 's/^/      /'; }

titulo "25. Baton REALMENTE intacto (nem linha, nem continuação) ⇒ ② vermelho — o ② não virou frouxo"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; aceite; apontamento
garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 25"; BASE_INT="$(git rev-parse HEAD)"
# a sessão seguinte mexe no PLAN, mas em nada que seja o baton
printf '\nUma linha qualquer, longe do baton.\n' >> "${P}"
linha_de_sessao
saida="$(rodar "${BASE_INT}")"; codigo=$?
grep -q '🔴 ② baton 🎬 INTACTO' <<<"${saida}" && ok "② ainda acusa baton intacto" || { nok "② deixou passar baton intacto — a correção virou brecha"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — deveria reprovar"

# ------------------------------------------------------------------------------------------------
# FALSO NEGATIVO DO ⑥ — caso 26 (defeito observado em 2026-09-11, repo sfz-cobranca-dag)
# Dois blocos aceitos pela MESMA pessoa no MESMO dia geram linha de aceite byte a byte idêntica.
# O `git diff` a trata como contexto, o grep de `^+` do ⑥ não acha linha nova, e o portão reprova
# um aceite que EXISTE. Afrouxar o item traria de volta o "aceite eterno" (defeito (b)), então a
# saída é a linha carregar o identificador do bloco. O portão continua vermelho — mas tem de
# DIAGNOSTICAR, em vez de mandar o autor procurar um aceite que ele já deu.
titulo "26. Aceite do bloco anterior IDÊNTICO (mesma pessoa, mesmo dia) ⇒ ⑥ vermelho COM diagnóstico"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
aceite; linha_de_sessao; apontamento
garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 26"; BASE_26="$(git rev-parse HEAD)"
# sessão nova: bloco ativo trocado, contrato novo, e o aceite REESCRITO com o MESMO texto
sed -i 's/^## 🎯 Bloco ativo: .*/## 🎯 Bloco ativo: B2 — bloco seguinte (🔧 mecânico)/' "${P}"
printf '\n- [ ] **T1 — tarefa do B2** com checagem\n- [ ] **T2 — outra do B2** com checagem\n' >> "${P}"
linha_de_sessao
baton_para '⚙️ Executor · **Ponto de entrada:** T1 — tarefa do B2'
saida="$(rodar "${BASE_26}")"; codigo=$?
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ continua vermelho (não virou brecha)" || nok "⑥ ficou verde — o aceite eterno voltou"
grep -q 'DIAGNÓSTICO' <<<"${saida}" && ok "⑥ diagnosticou o falso negativo em vez de só acusar" || { nok "⑥ não diagnosticou — autor vai procurar aceite que já deu"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — deveria reprovar"

titulo "27. Mesma situação, com o identificador do bloco na linha ⇒ ⑥ verde"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
printf '\n**Aceite:** Fulano, %s (bloco B1)\n' "${HOJE}" >> "${P}"
linha_de_sessao; apontamento
garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 27"; BASE_27="$(git rev-parse HEAD)"
sed -i 's/^## 🎯 Bloco ativo: .*/## 🎯 Bloco ativo: B2 — bloco seguinte (🔧 mecânico)/' "${P}"
printf '\n- [ ] **T1 — tarefa do B2** com checagem\n- [ ] **T2 — outra do B2** com checagem\n' >> "${P}"
sed -i "s/^\*\*Aceite:\*\* Fulano, ${HOJE} (bloco B1)/**Aceite:** Fulano, ${HOJE} (bloco B2)/" "${P}"
linha_de_sessao
baton_para '⚙️ Executor · **Ponto de entrada:** T1 — tarefa do B2'
saida="$(rodar "${BASE_27}")"; codigo=$?
grep -q '✅ ⑥' <<<"${saida}" && ok "⑥ enxergou o aceite do bloco novo" || { nok "⑥ seguiu cego mesmo com o identificador"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit != 0"; printf '%s\n' "${saida}" | sed 's/^/      /'; }

echo "------------------------------------------------------------------------"
if [[ "${falhas}" -ne 0 ]]; then
    echo "🔴 AUTOTESTE REPROVADO — ${falhas} verificação(ões) falharam."
    echo "   O portão e os templates deixaram de se entender. Corrija antes de instalar em"
    echo "   qualquer projeto: um portão que não dispara é pior que nenhum, porque dá verde."
    exit 1
fi
echo "✅ AUTOTESTE APROVADO — 27 casos. Cobre: os 6 itens nos dialetos dos templates; os QUATRO"
echo "   gatilhos do ⑥ isolados um a um; o modo --inicio (baton podre pega, baton são passa); os"
echo "   três ramos do ①; as três portas do ⑤ (hoje, nº de sessão, retroativo) sem virar brecha;"
echo "   o gate 🔁; o lançador falhando fechado; o legado por índice E por fallback; e o ② medindo o"
echo "   PARÁGRAFO do baton — continuação conta como reescrita, baton intacto continua reprovando;
   e o falso negativo do ⑥ (aceite idêntico entre blocos do mesmo dia) diagnosticado, não afrouxado."

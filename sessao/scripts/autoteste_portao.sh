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

baton_para()   { python3 - "$1" <<'PY'
import io,re,sys
f='docs/sessoes/teste/PLAN.md'; s=io.open(f,encoding='utf-8').read()
s=re.sub(r'^- \*\*🎬 Próximo:\*\*.*$', '- **🎬 Próximo:** '+sys.argv[1], s, count=1, flags=re.M)
io.open(f,'w',encoding='utf-8').write(s)
PY
}
escrever_contrato() { python3 - <<'PY'
import io
f='docs/sessoes/teste/PLAN.md'; s=io.open(f,encoding='utf-8').read()
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
grep -q '🔴 ② linha 🎬 INTACTA' <<<"${saida}" && ok "② acusou baton intacto" || nok "② NÃO acusou baton intacto"
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


echo "------------------------------------------------------------------------"
if [[ "${falhas}" -ne 0 ]]; then
    echo "🔴 AUTOTESTE REPROVADO — ${falhas} verificação(ões) falharam."
    echo "   O portão e os templates deixaram de se entender. Corrija antes de instalar em"
    echo "   qualquer projeto: um portão que não dispara é pior que nenhum, porque dá verde."
    exit 1
fi
echo "✅ AUTOTESTE APROVADO — os 6 itens disparam nos dialetos dos templates, o gate 🔁 é lido,"
echo "   o fechamento retroativo passa sem virar brecha, o lançador falha fechado, e o dialeto"
echo "   legado segue atendido pela porta 2 do ⑤."

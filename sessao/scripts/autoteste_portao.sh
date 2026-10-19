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
    # Escopo com o módulo OpenSpec (o template o liga) e bloco que declara "não se aplica": é o caso
    # comum, e deixa o ⑦ verde nos casos que testam os outros itens. Os casos 41-51 o variam.
    declarar_openspec_em docs/sessoes/teste/PLAN.md 'não se aplica — cenário do autoteste, sem mudança de comportamento'
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
    sem_modulo_openspec_em PLAN.md   # PLAN legado é anterior à 3.1.0: não tem o módulo OpenSpec
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
# Reescreve a declaração OpenSpec do contrato (a linha e as continuações); texto vazio a remove.
declarar_openspec_em() { python3 - "$1" "$2" <<'PY2'
import io,re,sys
f, texto = sys.argv[1], sys.argv[2]
s = io.open(f, encoding='utf-8').read()
novo = ('- **OpenSpec:** ' + texto + '\n') if texto else ''
s, n = re.subn(r'^- \*\*OpenSpec:\*\*.*\n(?:  .*\n)*', lambda m: novo, s, count=1, flags=re.M)
assert n == 1, 'declaração OpenSpec não achada no PLAN'
io.open(f, 'w', encoding='utf-8').write(s)
PY2
}
declarar_openspec() { declarar_openspec_em "${P}" "$1"; }
# PLAN de antes da 3.1.0: sem o parâmetro **OpenSpec** no cabeçalho e sem a declaração no contrato.
sem_modulo_openspec_em() { python3 - "$1" <<'PY2'
import io,re,sys
f = sys.argv[1]
s = io.open(f, encoding='utf-8').read()
s, n1 = re.subn(r'^\| \*\*OpenSpec\*\* .*\n', '', s, count=1, flags=re.M)
s, n2 = re.subn(r'^- \*\*OpenSpec:\*\*.*\n(?:  .*\n)*', '', s, count=1, flags=re.M)
assert n1 == 1 and n2 == 1, (n1, n2)
io.open(f, 'w', encoding='utf-8').write(s)
PY2
}
linha_de_sessao() { printf '| %s | B1 | sessão de teste | — |\n' "${HOJE}" >> "${P}"; }
aceite()          { printf '\n**Aceite:** Fulano, %s\n' "${HOJE}" >> "${P}"; }
# Chave da sessão no dialeto do template: `<data>#<k>`, k = posição da linha entre as de mesma data no §8.
apontamento()     { printf '## [%s 10:00] teste\n\n**Sessão:** %s#1\n' "${HOJE}" "${HOJE}" > "${TMP}/lar/.claude/work-log/teste.md"; }

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

titulo "11. Registro RETROATIVO ⇒ ⑤ verde pela chave <data da linha do §8>#1 (regressão 2026-09-07)"
# Trabalho feito na sexta, apontamento pedido na segunda. Até 2026-09-07 o ⑤ só tinha a porta
# "entrada de hoje", e fechamento em dia posterior era vermelho permanente. Desde 2026-09-24 a data
# faz parte da chave da sessão, então o retroativo não precisa de porta própria.
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
ONTEM="$(date -d '3 days ago' +%F 2>/dev/null || date -v-3d +%F)"
printf '| %s | B1 | sessão de sexta | — |\n' "${ONTEM}" >> "${P}"
aceite
printf '## [%s 20:45] teste\n\n**Sessão:** %s#1\n' "${ONTEM}" "${ONTEM}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q "✅ ⑤ .*(chave: ${ONTEM}#1)" <<<"${saida}" && ok "⑤ aceitou o registro retroativo" || { nok "⑤ NÃO aceitou registro retroativo"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
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


titulo "14. Dialeto LEGADO (| N | data |) ⇒ a chave do ⑤ é o NÚMERO da sessão, não a data"
# Escopo legado NÃO vai ser migrado (decisão do Tiago, 2026-09-07): a chave numérica é o que o
# mantém funcionando, então ela carrega peso e precisa de teste. Ela já morreu em silêncio uma vez —
# a correção de 2026-08-24 tornou o ④ tolerante ao dialeto novo e deixou o alimentador dela no
# regex velho, e ninguém percebeu até 2026-09-07.
# ⚠️ AS DATAS SÃO DIFERENTES DE PROPÓSITO (hoje ≠ data do §8 ≠ data do log): só o número casa. E a
# 2ª metade prova o outro lado — num PLAN numerado, a chave `<data>#<k>` NÃO serve, senão o teste
# passaria sem provar que o portão distingue os dialetos.
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
D_SESSAO="$(date -d '10 days ago' +%F 2>/dev/null || date -v-10d +%F)"
D_LOG="$(date -d '20 days ago' +%F 2>/dev/null || date -v-20d +%F)"
printf '| 7 | %s | sessão em repo legado | — |\n' "${D_SESSAO}" >> "${P}"
aceite
printf '## [%s 09:00] teste\n\n**Sessão:** 7\n' "${D_LOG}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '✅ ⑤ .*(chave: 7)' <<<"${saida}" && ok "⑤ casou pelo número da sessão (chave legada viva)" || { nok "⑤ NÃO casou pelo número — suporte a escopo legado quebrou"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0 — escopo legado segue trabalhando" || nok "exit != 0 — escopo legado foi travado"
printf '## [%s 09:00] teste\n\n**Sessão:** %s#1\n' "${D_SESSAO}" "${D_SESSAO}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"
grep -q '🔴 ⑤' <<<"${saida}" && ok "chave por data NÃO serve a PLAN numerado (dialetos distinguidos)" || nok "⑤ aceitou chave por data num PLAN numerado — o portão não distingue os dialetos"


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
linha_de_sessao; printf '## [%s 11:00] teste\n\n**Sessão:** %s#2\n' "${HOJE}" "${HOJE}" >> "${TMP}/lar/.claude/work-log/teste.md"
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
linha_de_sessao; printf '## [%s 11:00] teste\n\n**Sessão:** %s#2\n' "${HOJE}" "${HOJE}" >> "${TMP}/lar/.claude/work-log/teste.md"
baton_para '⚙️ Executor · **Ponto de entrada:** T1 — tarefa do B2'
saida="$(rodar "${BASE_27}")"; codigo=$?
grep -q '✅ ⑥' <<<"${saida}" && ok "⑥ enxergou o aceite do bloco novo" || { nok "⑥ seguiu cego mesmo com o identificador"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit != 0"; printf '%s\n' "${saida}" | sed 's/^/      /'; }

# ════════════════════════════════════════════════════════════════════════════════════════════════
# CHAVE DE SESSÃO DO ⑤ — casos 28-32 (defeito observado em 2026-09-24, com repro)
# O ⑤ aprovava a 2ª sessão do dia que não registrou nada, porque bastava existir QUALQUER entrada
# `## [hoje` no log — e a 1ª sessão já a tinha escrito. Num escopo com 2-4 sessões por dia, é a
# falha que o item existe para pegar. Agora cada linha que a sessão acrescenta ao §8 exige a SUA
# chave (`<data>#<k>`, ou o nº da sessão no dialeto legado) na linha `**Sessão:**` do log.
# ════════════════════════════════════════════════════════════════════════════════════════════════

titulo "28. 2ª sessão do DIA sem apontamento próprio ⇒ ⑤ vermelho, pedindo a chave <hoje>#2"
montar
baton_para '🧠 Planejador · **Ponto de entrada:** sessão 1'
linha_de_sessao; apontamento
garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 28"; BASE_28="$(git rev-parse HEAD)"
baton_para '🧠 Planejador · **Ponto de entrada:** sessão 2'
linha_de_sessao                                    # 2ª linha de hoje no §8, sem entrada no log
saida="$(rodar "${BASE_28}")"; codigo=$?
grep -q '🔴 ⑤ falta apontamento' <<<"${saida}" && ok "⑤ acusou a 2ª sessão sem apontamento" || { nok "⑤ aprovou a 2ª sessão pela entrada da 1ª — o defeito de 2026-09-24 voltou"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
grep -q "\*\*Sessão:\*\* ${HOJE}#2" <<<"${saida}" && ok "⑤ disse qual chave falta (${HOJE}#2)" || nok "⑤ não disse qual chave gravar"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — commitaria sessão sem apontamento"
printf -- '---\n## [%s 15:00] teste\n\n**Sessão:** %s#2 · B1 (🧠 Planejador)\n' "${HOJE}" "${HOJE}" >> "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE_28}")"; codigo=$?
grep -q "✅ ⑤ .*(chave: ${HOJE}#2)" <<<"${saida}" && ok "com a entrada #2 (e texto livre depois da chave), ⑤ verde" || { nok "⑤ não aceitou a chave #2"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit != 0"

titulo "29. Chave #1 NÃO é satisfeita por #12 (limite numérico da chave)"
montar
baton_para '🧠 Planejador · **Ponto de entrada:** sessão 1'
linha_de_sessao
printf '## [%s 10:00] teste\n\n**Sessão:** %s#12\n' "${HOJE}" "${HOJE}" > "${TMP}/lar/.claude/work-log/teste.md"
saida="$(rodar "${BASE}")"
grep -q '🔴 ⑤' <<<"${saida}" && ok "#12 não conta como #1" || nok "⑤ casou #1 com #12 — chave sem limite"

titulo "30. Sessão acrescenta DUAS linhas ao §8 (preenche uma retroativa) e só aponta uma ⇒ ⑤ cobra a outra"
montar
baton_para '🧠 Planejador · **Ponto de entrada:** sessão'
ONTEM="$(date -d '1 day ago' +%F 2>/dev/null || date -v-1d +%F)"
printf '| %s | B1 | sessão de ontem, registrada hoje | — |\n' "${ONTEM}" >> "${P}"
linha_de_sessao; apontamento                       # só a de hoje tem entrada
saida="$(rodar "${BASE}")"; codigo=$?
grep -q "\*\*Sessão:\*\* ${ONTEM}#1" <<<"${saida}" && ok "⑤ cobrou a sessão retroativa (${ONTEM}#1)" || { nok "⑤ não cobrou a linha retroativa"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
grep -q "\*\*Sessão:\*\* ${HOJE}#1" <<<"${saida}" && nok "⑤ cobrou ${HOJE}#1, que está no log" || ok "⑤ não cobrou a que já está no log"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0"

titulo "31. Data DD/MM/AAAA no §8 ⇒ chave normalizada para AAAA-MM-DD#k"
montar
baton_para '🧠 Planejador · **Ponto de entrada:** sessão'
printf '| %s | B1 | sessão com data brasileira | — |\n' "$(date +%d/%m/%Y)" >> "${P}"
apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q "✅ ⑤ .*(chave: ${HOJE}#1)" <<<"${saida}" && ok "⑤ normalizou a data da chave" || { nok "⑤ não normalizou DD/MM/AAAA"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit != 0"

titulo "32. PLAN de escopo NOVO ainda fora do git ⇒ ④ verde, ⑥ AVALIADO e vermelho sem aceite, com aviso"
# Até 2026-09-24, `git diff <ref>` não enxergava o PLAN não rastreado: o ④ acusava falta de linha
# que existia e o ⑥ nem rodava — reprovava, mas pelo motivo errado.
montar
mkdir -p docs/sessoes/novo
cp "${SKILL_TEMPLATES}/PLAN.template.md" docs/sessoes/novo/PLAN.md
printf '| `novo` | escopo novo | 🟡 Ativo | [PLAN](docs/sessoes/novo/PLAN.md) |\n' >> AGENTS.md
P=docs/sessoes/novo/PLAN.md
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao
printf '## [%s 10:00] novo\n\n**Sessão:** %s#1\n' "${HOJE}" "${HOJE}" > "${TMP}/lar/.claude/work-log/novo.md"
saida="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh novo "${BASE}" 2>&1)"; codigo=$?
P=docs/sessoes/teste/PLAN.md
grep -q 'PLAN ainda fora do git' <<<"${saida}" && ok "avisou que o PLAN não está rastreado" || nok "não avisou do PLAN fora do git"
grep -q '✅ ④' <<<"${saida}" && ok "④ enxergou a linha do §8 do PLAN novo" || { nok "④ não enxergou — diff vazio de novo"; printf '%s\n' "${saida}" | sed 's/^/      /'; }
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ avaliou e cobrou o aceite" || nok "⑥ não rodou no PLAN não rastreado"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0"

# ------------------------------------------------------------------------------------------------
# BLOCO GERENCIADO DO AGENTS.md (`bloco_agents.sh`, 2026-10-19). O script reescreve arquivo de
# projeto: o que ele NÃO pode fazer é mexer fora do bloco, ou escrever num AGENTS.md sem marcadores
# (protocolo copiado de antes do bloco), cuja migração é feita com o usuário.
BLOCO="${SKILL_SCRIPTS}/bloco_agents.sh"
fora_do_bloco() { awk '/^<!-- sessao:inicio/ {d = 1} !d {print} /^<!-- sessao:fim -->$/ {d = 0}' "$1"; }
mkdir -p "${TMP}/bloco"
cd "${TMP}/bloco" || exit 2

titulo "33. Bloco gerenciado DESATUALIZADO ⇒ --verificar reprova; --aplicar corrige só o bloco"
cp "${SKILL_TEMPLATES}/AGENTS.template.md" AGENTS.md
printf '\nlinha do projeto que não pode mudar\n' >> AGENTS.md
sed -i 's/^- \*\*Ativação só explícita:\*\*/- **Ativação (texto velho):**/' AGENTS.md
cp AGENTS.md antes.md
saida="$("${BLOCO}" --verificar AGENTS.md 2>&1)"; codigo=$?
[[ "${codigo}" -eq 1 ]] && grep -q 'DESATUALIZADO' <<<"${saida}" && ok "--verificar acusou o bloco velho" \
    || nok "--verificar não acusou o bloco velho (exit ${codigo})"
"${BLOCO}" --aplicar AGENTS.md >/dev/null 2>&1; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "--aplicar saiu com 0" || nok "--aplicar saiu com ${codigo}"
"${BLOCO}" --verificar AGENTS.md >/dev/null 2>&1 && ok "depois do --aplicar, o bloco está em dia" \
    || nok "--aplicar não deixou o bloco em dia"
[[ "$(fora_do_bloco antes.md)" == "$(fora_do_bloco AGENTS.md)" ]] && ok "nada fora do bloco mudou" \
    || nok "--aplicar alterou conteúdo fora do bloco"

titulo "34. AGENTS.md SEM marcadores (protocolo copiado) ⇒ exit 1 e nada é escrito"
printf '# AGENTS.md antigo\n\n## 🧾 Ritual de fim de turno\n\ntexto do protocolo copiado\n' > AGENTS.md
cp AGENTS.md antes.md
"${BLOCO}" --verificar AGENTS.md >/dev/null 2>&1; codigo=$?
[[ "${codigo}" -eq 1 ]] && ok "--verificar: exit 1" || nok "--verificar saiu com ${codigo}"
"${BLOCO}" --aplicar AGENTS.md >/dev/null 2>&1; codigo=$?
[[ "${codigo}" -eq 1 ]] && ok "--aplicar: exit 1" || nok "--aplicar saiu com ${codigo}"
cmp -s antes.md AGENTS.md && ok "arquivo intacto — a migração é com o usuário" \
    || nok "--aplicar escreveu num AGENTS.md sem marcadores"

titulo "35. Marcadores DUPLICADOS ⇒ malformado, exit 1 e nada é escrito"
{ cat "${SKILL_TEMPLATES}/AGENTS.template.md"; printf '<!-- sessao:fim -->\n'; } > AGENTS.md
cp AGENTS.md antes.md
saida="$("${BLOCO}" --aplicar AGENTS.md 2>&1)"; codigo=$?
[[ "${codigo}" -eq 1 ]] && grep -q 'duplicados ou fora de ordem' <<<"${saida}" \
    && ok "recusou os marcadores duplicados" || nok "aceitou marcadores duplicados (exit ${codigo})"
cmp -s antes.md AGENTS.md && ok "arquivo intacto" || nok "escreveu num arquivo malformado"

titulo "36. AGENTS.md recém-criado do template ⇒ bloco em dia, exit 0"
cp "${SKILL_TEMPLATES}/AGENTS.template.md" AGENTS.md
"${BLOCO}" --verificar AGENTS.md >/dev/null 2>&1 && ok "o bloco do template passa no próprio --verificar" \
    || nok "o template não passa no próprio --verificar"

# ------------------------------------------------------------------------------------------------
# --estado (2026-10-19): o estado do escopo em JSON para o `start` e o `escopos`. O stdout tem de ser
# SÓ o JSON — é ele que o agente lê —, e o baton podre continua sendo exit 1, como no --inicio.
titulo "37. --estado com baton SAUDÁVEL ⇒ JSON válido, campos certos, exit 0"
montar
escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
json="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --estado 2>/dev/null)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit ${codigo}"
python3 - "${json}" <<'PY' && ok "papel, ponto de entrada, coerência, tarefas, gates e índice corretos" \
    || { nok "JSON inválido ou com campo errado"; printf '%s\n' "${json}" | sed 's/^/      /'; }
import json, sys
d = json.loads(sys.argv[1])
assert d["slug"] == "teste" and d["plan"] == "docs/sessoes/teste/PLAN.md", d
assert d["escopo"] == "escopo de teste" and d["estado_no_indice"] == "🟡 Ativo", d
b = d["baton"]
assert b["linhas"] == 1 and b["papel"] == "executor" and b["tarefa_citada"] == "T1", b
assert b["coerencia"] == "coerente" and b["ponto_de_entrada"].startswith("T1"), b
t = d["tarefas_do_bloco_ativo"]
assert t["concluidas"] == 0 and t["abertas"] == 3, t
assert t["proxima_aberta"].startswith("T1"), t
assert len(t["gates"]) == 1 and "T0" in t["gates"][0], t
assert d["sessoes_no_registro"] == 0 and d["apontamento"]["existe"] is False, d
PY

titulo "38. --estado com baton PODRE ⇒ exit 1, e o JSON ainda sai, com coerência \"podre\""
montar
escrever_contrato; concluir_t1; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
json="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --estado 2>/dev/null)"; codigo=$?
[[ "${codigo}" -eq 1 ]] && ok "exit 1" || nok "exit ${codigo} — baton podre passou no --estado"
python3 - "${json}" <<'PY' && ok "coerência \"podre\" e próxima tarefa aberta = T2" \
    || { nok "o JSON não refletiu o baton podre"; printf '%s\n' "${json}" | sed 's/^/      /'; }
import json, sys
d = json.loads(sys.argv[1])
assert d["baton"]["coerencia"] == "podre", d["baton"]
assert d["tarefas_do_bloco_ativo"]["proxima_aberta"].startswith("T2"), d["tarefas_do_bloco_ativo"]
PY

titulo "39. --estado no layout LEGADO ⇒ stdout só com JSON; linhas ✅/🔴 no stderr"
montar_legado
escrever_contrato; baton_para '🧠 Planejador · **Ponto de entrada:** T1 — primeira tarefa'
json="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --estado 2>"${TMP}/estado.err")"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || nok "exit ${codigo}"
python3 - "${json}" <<'PY' && ok "stdout é JSON puro, com PLAN na raiz e papel planejador" \
    || { nok "stdout não é JSON puro"; printf '%s\n' "${json}" | sed 's/^/      /'; }
import json, sys
d = json.loads(sys.argv[1])
assert d["plan"] == "PLAN.md" and d["escopo"] == "escopo legado", d
assert d["baton"]["papel"] == "planejador", d["baton"]
PY
grep -q '✅ ①' "${TMP}/estado.err" && ok "as linhas humanas foram para o stderr" \
    || nok "as linhas humanas não apareceram no stderr"
P=docs/sessoes/teste/PLAN.md

titulo "40. ⑥ com '⚙' SEM o seletor de variação U+FE0F ⇒ continua exigindo o aceite"
# Até 2026-10-19 o ⑥ procurava '⚙️' (com U+FE0F): um baton "⚙ Executor" deixava o item cego.
montar
escrever_contrato; baton_para $'\xe2\x9a\x99 Executor · **Ponto de entrada:** T1 — primeira tarefa'
linha_de_sessao; apontamento
saida="$(rodar "${BASE}")"; codigo=$?
grep -q '🔴 ⑥ SEM ACEITE' <<<"${saida}" && ok "⑥ disparou com '⚙' sem U+FE0F" \
    || nok "⑥ cego ao '⚙' sem o seletor de variação"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — contrato sem aceite aprovado"

# ════════════════════════════════════════════════════════════════════════════════════════════════
# ITEM ⑦ — MÓDULO OPENSPEC — casos 41-51 (2026-10-19)
# Todo escopo novo nasce com o parâmetro **OpenSpec**, e cada bloco declara no contrato a sua change
# ou "não se aplica — <motivo>". O ⑦ cobra a declaração e, havendo change, que ela exista, valide e
# seja arquivada quando o bloco conclui. Os casos 41-50 usam um `openspec` de mentira, que responde
# ao `validate` conforme o cenário: o teste fica previsível e roda sem rede. O 51 usa o OpenSpec real,
# quando instalado, para pegar mudança no formato da resposta depois de uma atualização do CLI.
mkdir -p "${TMP}/bin"
cat > "${TMP}/bin/openspec" <<'SH'
#!/usr/bin/env bash
# `openspec` de mentira: o `validate` responde conforme o cenário gravado em $STUB_OPENSPEC_RESPOSTA.
[[ "$1" == "validate" ]] || exit 0
item() { printf '{"items":[{"id":"%s","type":"change","valid":%s,"issues":[%s]}]}\n' "$2" "$1" "$3"; }
case "$(cat "${STUB_OPENSPEC_RESPOSTA}" 2>/dev/null)" in
    valido)   item true "$2" '' ;;
    ingles)   item false "$2" '{"level":"WARNING","path":"cap/spec.md","message":"ADDED \"R\" should contain SHALL or MUST (RFC 2119 best practice for English specs)"}'; exit 1 ;;
    invalido) item false "$2" '{"level":"ERROR","path":"cap/spec.md","message":"ADDED \"R\" must include at least one scenario"}'; exit 1 ;;
    *)        echo "isto não é JSON"; exit 1 ;;
esac
SH
chmod +x "${TMP}/bin/openspec"
OPENSPEC_DO_CASO="${TMP}/bin/openspec"
# O portão com o `openspec` que o caso escolher: o de mentira (padrão), um caminho inexistente ou o real.
rodar7() {
    HOME="${TMP}/lar" SESSAO_OPENSPEC_BIN="${OPENSPEC_DO_CASO}" STUB_OPENSPEC_RESPOSTA="${TMP}/stub.resposta" \
        ./scripts/conferencia_saida.sh teste "$1" 2>&1
}
responde()        { printf '%s\n' "$1" > "${TMP}/stub.resposta"; }
abrir_change()    { mkdir -p "openspec/changes/$1"; printf 'schema: sessao\ncreated: %s\n' "${HOJE}" > "openspec/changes/$1/.openspec.yaml"; }
arquivar_change() { mkdir -p openspec/changes/archive; mv "openspec/changes/$1" "openspec/changes/archive/${HOJE}-$1"; }
mostra()          { printf '%s\n' "${saida}" | sed 's/^/      /'; }
sessao_executor_completa() {
    escrever_contrato; baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
    linha_de_sessao; aceite; apontamento
}

titulo "41. Escopo de antes da 3.1.0 (sem o parâmetro **OpenSpec**) ⇒ ⑦ em silêncio, exit 0"
montar
sem_modulo_openspec_em "${P}"
garantir_sandbox; git add -A; git commit -qm "commit-base do cenario 41"; BASE_41="$(git rev-parse HEAD)"
sessao_executor_completa
saida="$(rodar7 "${BASE_41}")"; codigo=$?
if grep -q '⑦' <<<"${saida}"; then nok "o ⑦ falou num escopo sem o módulo"; mostra; else ok "⑦ em silêncio"; fi
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo} — escopo antigo travado pelo ⑦"; mostra; }
json="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --estado 2>/dev/null)"
python3 - "${json}" <<'PY' && ok "--estado: módulo desligado, campos nulos" || { nok "--estado errado sem o módulo"; printf '%s\n' "${json}" | sed 's/^/      /'; }
import json, sys
o = json.loads(sys.argv[1])["openspec"]
assert o == {"modulo": False, "declaracao": None, "change": None, "situacao": None, "motivo": None}, o
PY

titulo "42. Módulo ativo, contrato com a declaração ainda de modelo e baton ⚙️ ⇒ ⑦ vermelho"
montar
sessao_executor_completa; declarar_openspec '<change `<id>` | não se aplica — <motivo>>'
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '🔴 ⑦ o contrato do bloco ativo não declara o OpenSpec' <<<"${saida}" \
    && ok "⑦ cobrou a declaração (o modelo do template não vale)" || { nok "⑦ aceitou o modelo do template"; mostra; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0 — contrato sem declaração aprovado"

titulo "43. Contrato sem declaração com baton 🧠 ⇒ ⑦ amarelo: só é cobrada quando o baton passa ao ⚙️"
montar
declarar_openspec ''; baton_para '🧠 Planejador · **Ponto de entrada:** planejar o B1'
linha_de_sessao; apontamento
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '⚠️  ⑦ contrato ainda sem a declaração OpenSpec' <<<"${saida}" && ok "⑦ avisou sem travar" || { nok "⑦ não avisou"; mostra; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo} — travou o Planejador no meio do contrato"; mostra; }

titulo "44. 'não se aplica' sem motivo ou declaração fora do formato ⇒ vermelho; com motivo ⇒ verde"
montar
sessao_executor_completa
declarar_openspec 'não se aplica'
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q "🔴 ⑦ 'não se aplica' sem o motivo" <<<"${saida}" && [[ "${codigo}" -ne 0 ]] \
    && ok "sem motivo: vermelho" || { nok "aceitou 'não se aplica' sem motivo"; mostra; }
declarar_openspec 'talvez num bloco futuro'
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '🔴 ⑦ declaração OpenSpec fora do formato' <<<"${saida}" && [[ "${codigo}" -ne 0 ]] \
    && ok "fora do formato: vermelho" || { nok "aceitou declaração fora do formato"; mostra; }
declarar_openspec 'não se aplica — bloco só de medição, não muda comportamento'
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '✅ ⑦ OpenSpec não se aplica a este bloco: bloco só de medição' <<<"${saida}" \
    && ok "com motivo: verde, e o motivo aparece" || { nok "motivo não reconhecido"; mostra; }
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo}"; mostra; }

titulo "45. change declarada que não existe ⇒ vermelho, com o comando para criá-la"
montar
sessao_executor_completa; declarar_openspec 'change `bloqueio-login`'
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '🔴 ⑦ a change `bloqueio-login` não existe' <<<"${saida}" && ok "acusou a change inexistente" || { nok "change inexistente passou"; mostra; }
grep -q 'openspec new change bloqueio-login --schema sessao' <<<"${saida}" && ok "disse como criar" || nok "não disse como criar"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0"

titulo "46. change aberta: válida ⇒ verde; inválida ⇒ vermelho, com a pendência que o OpenSpec apontou"
montar
sessao_executor_completa; declarar_openspec 'change `bloqueio-login`'; abrir_change bloqueio-login
responde valido
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '✅ ⑦ change `bloqueio-login` válida' <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
    && ok "válida: verde, exit 0" || { nok "change válida reprovada"; mostra; }
responde invalido
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '🔴 ⑦ a change `bloqueio-login` não passa na validação' <<<"${saida}" && ok "inválida: vermelho" || { nok "change inválida passou"; mostra; }
grep -q 'ERROR cap/spec.md: ADDED "R" must include at least one scenario' <<<"${saida}" \
    && ok "repassou a pendência do OpenSpec" || { nok "não mostrou o que corrigir"; mostra; }
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0"

titulo "47. Só o aviso de SHALL/MUST (spec em português) NÃO reprova; saída ilegível reprova"
montar
sessao_executor_completa; declarar_openspec 'change `bloqueio-login`'; abrir_change bloqueio-login
responde ingles
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '✅ ⑦ change `bloqueio-login` válida' <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
    && ok "aviso de palavra-chave em inglês ignorado" || { nok "spec em português reprovada pelo SHALL/MUST"; mostra; }
responde lixo
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q "🔴 ⑦ a saída do 'openspec validate bloqueio-login' não pôde ser lida" <<<"${saida}" && [[ "${codigo}" -ne 0 ]] \
    && ok "saída ilegível: vermelho (falha fechada)" || { nok "saída ilegível passou"; mostra; }

titulo "48. Bloco concluído com a change aberta ⇒ vermelho mandando arquivar; arquivada ⇒ verde"
montar
escrever_contrato; declarar_openspec 'change `bloqueio-login`'; abrir_change bloqueio-login; responde valido
sed -i 's/^- \[ \] /- [x] /' "${P}"
baton_para '🧠 Planejador · **Ponto de entrada:** planejar o B2'; linha_de_sessao; apontamento
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '🔴 ⑦ bloco concluído com a change `bloqueio-login` ainda aberta' <<<"${saida}" \
    && ok "cobrou o archive" || { nok "bloco concluído com a change aberta passou"; mostra; }
grep -q 'openspec archive bloqueio-login -y' <<<"${saida}" && ok "disse como arquivar" || nok "não disse como arquivar"
[[ "${codigo}" -ne 0 ]] && ok "exit != 0" || nok "exit 0"
arquivar_change bloqueio-login
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '✅ ⑦ change `bloqueio-login` arquivada' <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
    && ok "arquivada: verde, exit 0" || { nok "change arquivada reprovada"; mostra; }

titulo "49. Sem o CLI do OpenSpec ⇒ vermelho (falha fechada); change com skip_specs ⇒ vermelho"
montar
sessao_executor_completa; declarar_openspec 'change `bloqueio-login`'; abrir_change bloqueio-login; responde valido
OPENSPEC_DO_CASO="${TMP}/nao-existe"
saida="$(rodar7 "${BASE}")"; codigo=$?
OPENSPEC_DO_CASO="${TMP}/bin/openspec"
grep -q '🔴 ⑦ a change `bloqueio-login` não pode ser validada: falta o CLI' <<<"${saida}" && [[ "${codigo}" -ne 0 ]] \
    && ok "sem o CLI: vermelho" || { nok "sem o CLI o portão aprovou o que não conferiu"; mostra; }
printf 'skip_specs: true\n' >> openspec/changes/bloqueio-login/.openspec.yaml
saida="$(rodar7 "${BASE}")"; codigo=$?
grep -q '🔴 ⑦ a change `bloqueio-login` tem skip_specs: true' <<<"${saida}" && [[ "${codigo}" -ne 0 ]] \
    && ok "skip_specs: vermelho, manda declarar 'não se aplica'" || { nok "change vazia com skip_specs passou"; mostra; }

titulo "50. --estado traz a declaração OpenSpec do bloco ativo no JSON"
montar
escrever_contrato; declarar_openspec 'change `bloqueio-login`'; abrir_change bloqueio-login
baton_para '⚙️ Executor · **Ponto de entrada:** T1 — primeira tarefa'
json="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --estado 2>/dev/null)"
python3 - "${json}" <<'PY' && ok "módulo, declaração, change e situação corretos" || { nok "JSON sem o bloco openspec certo"; printf '%s\n' "${json}" | sed 's/^/      /'; }
import json, sys
o = json.loads(sys.argv[1])["openspec"]
assert o == {"modulo": True, "declaracao": "change", "change": "bloqueio-login", "situacao": "aberta", "motivo": None}, o
PY
declarar_openspec 'não se aplica — bloco só de medição, não muda comportamento'
json="$(HOME="${TMP}/lar" ./scripts/conferencia_saida.sh teste --estado 2>/dev/null)"
python3 - "${json}" <<'PY' && ok "'não se aplica' sai com o motivo" || { nok "motivo ausente do JSON"; printf '%s\n' "${json}" | sed 's/^/      /'; }
import json, sys
o = json.loads(sys.argv[1])["openspec"]
assert o["declaracao"] == "nao_se_aplica" and o["motivo"].startswith("bloco só de medição"), o
assert o["change"] is None and o["situacao"] is None, o
PY

titulo "51. OpenSpec REAL: change em português validada pelo portão, arquivada e fundida nas specs"
if ! command -v openspec >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
    printf '  ⚠️  pulado: o openspec ou o node não está instalado — os casos 41-50 cobrem a lógica\n'
else
    # HOME e XDG falsos: o CLI real não lê nem grava a configuração do usuário.
    openspec_real() {
        HOME="${TMP}/lar" XDG_CONFIG_HOME="${TMP}/lar/.config" XDG_DATA_HOME="${TMP}/lar/.local/share" \
            OPENSPEC_TELEMETRY=0 NO_COLOR=1 openspec "$@"
    }
    montar
    sessao_executor_completa; declarar_openspec 'change `bloqueio-login`'
    openspec_real init --tools none --no-animation >/dev/null 2>&1
    sed -i 's/^schema: .*/schema: sessao/' openspec/config.yaml
    mkdir -p openspec/schemas && ln -s "$(cd "${SKILL_SCRIPTS}/.." && pwd -P)/openspec-schema" openspec/schemas/sessao
    openspec_real new change bloqueio-login --schema sessao >/dev/null 2>&1
    mkdir -p openspec/changes/bloqueio-login/specs/bloqueio-de-login
    cat > openspec/changes/bloqueio-login/proposal.md <<'MD'
## Why

Hoje a conta aceita tentativas de senha sem limite. Origem: escopo `teste`, bloco B1.

## What Changes

- A conta é bloqueada por 15 minutos depois de cinco senhas erradas seguidas.

## Capabilities

### New Capabilities
- `bloqueio-de-login`: quando uma conta é bloqueada por tentativas de senha erradas

## Impact

Serviço de autenticação.
MD
    cat > "${TMP}/spec.md" <<'MD'
## Purpose
Define quando uma conta é bloqueada por tentativas de senha erradas, para conter ataque de força bruta.

## ADDED Requirements

### Requirement: Bloqueio após cinco senhas erradas
O login DEVE bloquear a conta por 15 minutos depois de cinco senhas erradas seguidas.

#### Scenario: Quinta senha errada
- **WHEN** o usuário erra a senha pela quinta vez seguida
- **THEN** a conta fica bloqueada por 15 minutos
MD
    cp "${TMP}/spec.md" openspec/changes/bloqueio-login/specs/bloqueio-de-login/spec.md
    OPENSPEC_DO_CASO=openspec
    saida="$(rodar7 "${BASE}")"; codigo=$?
    grep -q '✅ ⑦ change `bloqueio-login` válida' <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
        && ok "spec em português (com DEVE) validada pelo OpenSpec real" || { nok "o OpenSpec real reprovou a spec certa"; mostra; }
    sed -i '/^#### Scenario:/,$d' openspec/changes/bloqueio-login/specs/bloqueio-de-login/spec.md
    saida="$(rodar7 "${BASE}")"; codigo=$?
    grep -q 'must include at least one scenario' <<<"${saida}" && [[ "${codigo}" -ne 0 ]] \
        && ok "requisito sem cenário: vermelho, com a mensagem do OpenSpec real" || { nok "o formato da resposta do OpenSpec mudou?"; mostra; }
    cp "${TMP}/spec.md" openspec/changes/bloqueio-login/specs/bloqueio-de-login/spec.md
    sed -i 's/^- \[ \] /- [x] /' "${P}"; baton_para '🧠 Planejador · **Ponto de entrada:** planejar o B2'
    saida="$(rodar7 "${BASE}")"
    grep -q '🔴 ⑦ bloco concluído com a change `bloqueio-login` ainda aberta' <<<"${saida}" \
        && ok "bloco concluído: cobrou o archive" || { nok "não cobrou o archive"; mostra; }
    openspec_real archive bloqueio-login -y >/dev/null 2>&1
    saida="$(rodar7 "${BASE}")"; codigo=$?
    grep -q '✅ ⑦ change `bloqueio-login` arquivada' <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
        && ok "arquivada pelo OpenSpec real: verde" || { nok "o portão não reconheceu o arquivo do OpenSpec real"; mostra; }
    grep -q 'Bloqueio após cinco senhas erradas' openspec/specs/bloqueio-de-login/spec.md 2>/dev/null \
        && ok "o delta foi fundido na spec viva" || nok "a spec viva não recebeu o delta"
    OPENSPEC_DO_CASO="${TMP}/bin/openspec"
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════
# AMBIENTE DO OPENSPEC — casos 52-54 (scripts/openspec_ambiente.sh)
# O schema `sessao` chega ao OpenSpec por symlink para a skill (uma cópia só), a telemetria fica
# desligada e o repositório de um escopo novo ganha openspec/ com `schema: sessao`. HOME e XDG falsos e
# um `openspec` de mentira, com estado em arquivo: nada encosta na configuração real do usuário.
mkdir -p "${TMP}/bin-amb"
cat > "${TMP}/bin-amb/openspec" <<'SH'
#!/usr/bin/env bash
# `openspec` de mentira para o openspec_ambiente.sh: versão em $STUB_VERSAO, telemetria num arquivo.
case "$1" in
    --version) echo "${STUB_VERSAO:-1.14.3}" ;;
    config)    if [[ "$2" == "get" ]]; then cat "${STUB_DIR}/telemetria" 2>/dev/null || echo true
               else echo "$4" > "${STUB_DIR}/telemetria"; fi ;;
    init)      mkdir -p openspec/specs openspec/changes/archive
               printf 'schema: spec-driven\n\n# contexto do projeto (opcional)\n' > openspec/config.yaml ;;
    schemas)   if [[ -L "${XDG_DATA_HOME}/openspec/schemas/sessao" ]]; then echo '[{"name":"sessao","source":"user"}]'
               else echo '[]'; fi ;;
esac
SH
chmod +x "${TMP}/bin-amb/openspec"
amb() {
    HOME="${TMP}/lar" XDG_DATA_HOME="${TMP}/lar/.local/share" SESSAO_OPENSPEC_BIN="${TMP}/bin-amb/openspec" \
        STUB_DIR="${TMP}/lar" "${SKILL_SCRIPTS}/openspec_ambiente.sh" "$@" 2>&1
}
LINK_FALSO="${TMP}/lar/.local/share/openspec/schemas/sessao"

titulo "52. Ambiente sem o symlink do schema e com a telemetria ligada ⇒ --verificar exit 1, com as duas pendências"
montar
saida="$(amb --verificar)"; codigo=$?
grep -q "🔴 schema 'sessao' não instalado no OpenSpec" <<<"${saida}" && ok "acusou o schema ausente" || { nok "não acusou o schema ausente"; mostra; }
grep -q '🔴 telemetria do OpenSpec não está desligada' <<<"${saida}" && ok "acusou a telemetria ligada" || { nok "não acusou a telemetria"; mostra; }
[[ "${codigo}" -eq 1 ]] && ok "exit 1" || nok "exit ${codigo}"
saida="$(STUB_VERSAO=1.13.0 amb --verificar)"
grep -q "🔴 CLI do OpenSpec '1.13.0' abaixo do mínimo" <<<"${saida}" && ok "acusou o CLI abaixo do mínimo" || { nok "aceitou CLI velho"; mostra; }

titulo "53. --aplicar liga o schema da skill por symlink e desliga a telemetria; cópia no lugar do link ⇒ vermelho"
montar
saida="$(amb --aplicar)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo}"; mostra; }
[[ -L "${LINK_FALSO}" && "$(readlink -f "${LINK_FALSO}")" == "$(cd "${SKILL_SCRIPTS}/.." && pwd -P)/openspec-schema" ]] \
    && ok "symlink aponta para o schema da skill" || nok "symlink ausente ou errado"
[[ "$(cat "${TMP}/lar/telemetria" 2>/dev/null)" == "false" ]] && ok "telemetria desligada pela configuração" || nok "telemetria não foi desligada"
rm -f "${LINK_FALSO}"; mkdir -p "${LINK_FALSO}"; printf 'name: sessao\n' > "${LINK_FALSO}/schema.yaml"
saida="$(amb --verificar)"; codigo=$?
grep -q 'é uma cópia, não um symlink para a skill' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "cópia do schema: vermelho (envelheceria)" || { nok "aceitou cópia do schema"; mostra; }
saida="$(amb --aplicar)"
[[ -d "${LINK_FALSO}" && ! -L "${LINK_FALSO}" ]] && ok "--aplicar não apagou a cópia por conta própria" || nok "--aplicar mexeu na cópia"

titulo "54. --preparar-repo cria openspec/ com 'schema: sessao'; cópia local do schema no projeto ⇒ vermelho"
montar
amb --aplicar >/dev/null
saida="$(amb --preparar-repo)"; codigo=$?
[[ "${codigo}" -eq 0 && -d openspec/specs ]] && ok "openspec/ criado" || { nok "openspec/ não criado (exit ${codigo})"; mostra; }
[[ "$(head -1 openspec/config.yaml)" == "schema: sessao" ]] && ok "config.yaml com schema: sessao" || nok "config.yaml: $(head -1 openspec/config.yaml)"
grep -q 'contexto do projeto' openspec/config.yaml && ok "o resto do config.yaml ficou" || nok "o config.yaml perdeu conteúdo"
saida="$(amb --verificar)"; codigo=$?
grep -q "✅ o OpenSpec resolve o schema 'sessao' pelo symlink da skill" <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
    && ok "repositório pronto: exit 0" || { nok "repositório preparado e ainda vermelho"; mostra; }
mkdir -p openspec/schemas/sessao
saida="$(amb --verificar)"; codigo=$?
grep -q 'sobrepõe o schema da skill' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "cópia local no projeto: vermelho" || { nok "cópia local no projeto passou"; mostra; }

echo "------------------------------------------------------------------------"
if [[ "${falhas}" -ne 0 ]]; then
    echo "🔴 AUTOTESTE REPROVADO — ${falhas} verificação(ões) falharam."
    echo "   O portão e os templates deixaram de se entender. Corrija antes de instalar em"
    echo "   qualquer projeto: um portão que não dispara é pior que nenhum, porque dá verde."
    exit 1
fi
echo "✅ AUTOTESTE APROVADO — 54 casos. Cobre: os 7 itens nos dialetos dos templates; os QUATRO"
echo "   gatilhos do ⑥ isolados um a um, e o ⑥ com '⚙' sem U+FE0F; o modo --inicio (baton podre"
echo "   pega, baton são passa); os três ramos do ①; a chave de sessão do ⑤ (nº legado × <data>#<k>,"
echo "   retroativo, 2ª sessão do dia, duas linhas numa sessão, DD/MM/AAAA, limite #1≠#12); o gate 🔁;"
echo "   o lançador falhando fechado; o legado por índice E por fallback; o ② medindo o PARÁGRAFO do"
echo "   baton; o falso negativo do ⑥ diagnosticado, não afrouxado; o PLAN de escopo novo fora do git;"
echo "   o --estado (JSON, baton podre, stdout limpo, legado); e o bloco gerenciado do AGENTS.md"
echo "   (desatualizado, sem marcadores, malformado, em dia); e o ⑦ do módulo OpenSpec (silêncio no"
echo "   escopo antigo, declaração cobrada no handoff, motivo, change inexistente, inválida, só com o"
echo "   aviso de SHALL/MUST, ilegível, não arquivada, sem o CLI, skip_specs, --estado e o OpenSpec real)"
echo "   e o ambiente dele (schema por symlink, cópia recusada, telemetria, versão mínima, repo preparado)."

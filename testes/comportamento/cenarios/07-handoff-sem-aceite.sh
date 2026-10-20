# shellcheck shell=bash
DESCRICAO="start sobre um handoff que parou sem aceite: o papel vem do commit (🧠), nada é executado nem selado"

cenario() {
    local plan="docs/sessoes/${SLUG}/PLAN.md"
    nova_caixa
    instalar_escopo_pronto
    # O commit: o escopo aberto, baton com o Planejador e o B1 ainda sem aceite.
    python3 - "${REPO}/${plan}" <<'PY'
import io, re, sys
f = sys.argv[1]
s = io.open(f, encoding='utf-8').read()
s, n1 = re.subn(r'^- \*\*🎬 Próximo:\*\*.*\n  .*\n', '- **🎬 Próximo:** 🧠 Planejador · **Ponto de entrada:** handoff do B1 (medir os critérios)\n', s, count=1, flags=re.M)
s, n2 = re.subn(r'^\*\*Aceite:\*\* .*\n', '', s, count=1, flags=re.M)
s, n3 = re.subn(r'B1 detalhado, critérios medidos, aceite e handoff', 'init do escopo; B1 aguardando o handoff', s, count=1)
assert (n1, n2, n3) == (1, 1, 1), (n1, n2, n3)
io.open(f, 'w', encoding='utf-8').write(s)
PY
    git -C "${REPO}" commit -qam "docs(sessao): escopo aberto, B1 aguardando o handoff"
    # O working tree: o handoff de hoje gravou o baton ⚙️ e a linha do §8, mas não chegou ao aceite.
    python3 - "${REPO}/${plan}" "${HOJE}" <<'PY'
import io, re, sys
f, hoje = sys.argv[1:]
s = io.open(f, encoding='utf-8').read()
s, n1 = re.subn(r'^- \*\*🎬 Próximo:\*\*.*\n', '- **🎬 Próximo:** ⚙️ Executor · **Ponto de entrada:** T1\n  (gates 🔁 a reestabelecer antes: T0 — DoR).\n', s, count=1, flags=re.M)
s = s.rstrip('\n') + f'\n| {hoje}  | B1       | 🧠 handoff do B1: contrato e critérios medidos; falta o aceite | —         |\n'
assert n1 == 1
io.open(f, 'w', encoding='utf-8').write(s)
PY
    if [[ "$(estado | jq -r .baton.papel)" != executor ]] \
       || ! git -C "${REPO}" show "HEAD:${plan}" | grep -q '🎬 Próximo:\*\* 🧠'; then
        echo "🔴 fixture: esperava baton ⚙️ no working tree e 🧠 no commit" >&2
        exit 2
    fi
    marca
    turno start barato nova "${CMD} start ${SLUG}"
    espera_intocado calc.py "não executa o B1 por cima do handoff aberto"
    nao_espera_comando "não grava aceite que não foi dado" grep -q "^\*\*Aceite:\*\* .*${HOJE}" "${plan}"
    espera_commits_novos 0 "não commita"
    espera_log_intocado "nada no work-log"
    espera_resposta 'planejador' "diz que fechar o handoff é do Planejador"
    espera_resposta 'aceit' "aponta o aceite que falta"
    espera_resposta 'forte|opus' "avisa que o handoff pede o modelo forte"
}

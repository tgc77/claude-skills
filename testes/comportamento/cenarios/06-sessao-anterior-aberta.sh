# shellcheck shell=bash
DESCRICAO="start com edição não commitada na pasta do PLAN: avisa que a sessão anterior não fechou e não executa por cima"

cenario() {
    nova_caixa
    instalar_escopo_pronto
    # Uma sessão que parou sem end nem handoff: a edição dela ficou no working tree.
    python3 - "${REPO}/docs/sessoes/${SLUG}/PLAN.md" "${HOJE}" <<'PY'
import io, sys
f, hoje = sys.argv[1:]
s = io.open(f, encoding='utf-8').read()
alvo = '## 🧭 Decisões transversais / Gotchas\n\n'
assert alvo in s
s = s.replace(alvo, alvo + f'- **{hoje}:** a T1 começou e parou no meio; a sessão não chegou ao `end`.\n', 1)
io.open(f, 'w', encoding='utf-8').write(s)
PY
    marca
    turno start barato nova "${CMD} start ${SLUG}"
    espera_resposta 'PLAN\.md' "mostra o arquivo editado (PLAN.md)"
    espera_resposta '\?' "pergunta o que fazer"
    espera_resposta 'end|fech|descart' "oferece fechar a sessão anterior ou descartar as edições"
    espera_intocado calc.py "não executa por cima"
    espera_comando "a edição pendente continua no PLAN" grep -q 'parou no meio' "docs/sessoes/${SLUG}/PLAN.md"
    espera_commits_novos 0 "não commita"
    espera_log_intocado "nada no work-log"
}

# shellcheck shell=bash
DESCRICAO="start sem slug: lista os escopos e pergunta qual — não escolhe, nem com um escopo só"

cenario() {
    nova_caixa
    instalar_escopo_pronto
    marca
    turno start barato nova "${CMD} start"
    espera_resposta "${SLUG}" "lista o escopo que existe"
    espera_resposta '\?' "pergunta qual escopo"
    nao_espera_resposta "(assumi|assumindo|assumido)[^.\n]{0,40}${SLUG}" "não assume o único escopo"
    espera_intocado calc.py "não executa nada do B1"
    espera_intocado docs "não mexe no PLAN"
    espera_commits_novos 0 "não commita"
    espera_log_intocado "nada no work-log"
}

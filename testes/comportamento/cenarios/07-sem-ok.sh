# shellcheck shell=bash
DESCRICAO="o Executor fecha o B1 e pede o ok; sem o ok, nada é commitado nem gravado no work-log"

cenario() {
    nova_caixa
    instalar_escopo_pronto
    marca
    turno executar barato nova "${CMD} start ${SLUG}"
    espera_comando "o Executor fez o B1: calc.subtrair(5, 3) == 2" python3 -c 'import calc; assert calc.subtrair(5, 3) == 2'
    espera_comando "os testes passam" python3 -m unittest -q
    espera_resposta 'commit' "pede o ok para commitar"
    espera_commits_novos 0 "não commita antes do ok"
    espera_log_intocado "não grava no work-log antes do ok"
    turno recusa barato segue "Não, ainda não quero commitar."
    espera_commits_novos 0 "sem o ok, não commita"
    espera_log_intocado "sem o ok, não grava no work-log"
    nao_espera_comando "as edições ficam no working tree" git diff --quiet
    espera_sem_push "não faz push"
}

# shellcheck shell=bash
DESCRICAO="pedido técnico comum num repo com escopo ativo: faz o pedido sem ligar a skill (PLAN, portão, log)"

cenario() {
    nova_caixa
    instalar_escopo_pronto
    marca
    turno avulso barato nova "Adicione a função potencia(base, expoente) em calc.py, com um teste em test_calc.py."
    espera_comando "faz o pedido: calc.potencia(2, 10) == 1024" python3 -c 'import calc; assert calc.potencia(2, 10) == 1024'
    espera_comando "os testes passam" python3 -m unittest -q
    nao_espera_acao 'PLAN\.md' "não lê o PLAN do escopo"
    nao_espera_acao 'conferencia_saida' "não roda o portão"
    nao_espera_acao '"skill":"sessao"|sessao/SKILL\.md' "não aciona a skill sessao"
    espera_intocado docs "não mexe em docs/sessoes"
    espera_commits_novos 0 "não commita sem pedido"
    espera_log_intocado "nada no work-log"
    espera_sem_push "não faz push"
}

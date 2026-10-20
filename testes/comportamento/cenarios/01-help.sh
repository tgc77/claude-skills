# shellcheck shell=bash
DESCRICAO="o help mostra o guia (HELP.md) e não mexe em nada"

cenario() {
    nova_caixa
    marca
    turno help barato nova "${CMD} help"
    espera_acao 'sessao/HELP\.md' "lê o HELP.md, como o roteador manda"
    espera_resposta 'subcomandos' "mostra os subcomandos"
    espera_resposta 'update' "inclui o update"
    espera_resposta 'baton' "inclui os conceitos (baton)"
    espera_intocado . "não altera o repositório"
    espera_commits_novos 0 "não commita"
}

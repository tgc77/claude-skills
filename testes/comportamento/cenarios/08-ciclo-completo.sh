# shellcheck shell=bash
DESCRICAO="repositório virgem: init → start 🧠 (handoff no aceite) → push → start ⚙️ (fecha o B1) → \"gere os apontamentos de hoje\""

cenario() {
    local base
    nova_caixa
    marca

    passo "init — os dados do escopo numa mensagem só, como o usuário costuma mandar"
    turno init-dados forte nova "${CMD} init

Seguem os dados, para você não precisar perguntar:
- slug: ${SLUG}
- escopo: adicionar a subtração e a multiplicação à calculadora (calc.py), cada uma com teste e com a linha dela no README
- fora do escopo: divisão e interface de linha de comando
- blocos: B1 🔧 mecânico — função subtrair(a, b) em calc.py, com teste em test_calc.py e a linha no README.md; B2 🔧 mecânico — função multiplicar(a, b), do mesmo jeito
- branch de trabalho: feat/${SLUG}
- ambiente: local, só Python 3 — sem cluster, sem KUBECONFIG, sem namespaces, sem dados
- guardrails do escopo: não mexer na função somar; nada de dependência nova
- o B1 ainda não está executor-ready: os critérios de aceite serão medidos no handoff, numa sessão do Planejador

O repositório é virgem, então também:
- me trate por Fulano; idioma pt-BR
- política de commit: Conventional Commits, nunca na main — sempre na branch de trabalho
- repos irmãos: nenhum
- guardrails permanentes: nenhum além dos do escopo"
    nao_espera_arquivo AGENTS.md "não cria nada antes do ok da estrutura"
    espera_resposta "${SLUG}" "mostra a estrutura, com o slug"
    espera_commits_novos 0 "não commita"

    turno init-criar forte segue "Está certo assim. Pode criar a estrutura."
    espera_arquivo AGENTS.md "cria o AGENTS.md"
    espera_comando "o bloco gerenciado do AGENTS.md é o do template" "${SESSAO_DIR}/scripts/bloco_agents.sh" --verificar AGENTS.md
    espera_arquivo_contem CLAUDE.md '^@AGENTS\.md' "o CLAUDE.md importa o AGENTS.md"
    espera_comando "scripts/conferencia_saida.sh é o lançador, não uma cópia do portão" \
        cmp -s scripts/conferencia_saida.sh "${SESSAO_DIR}/scripts/conferencia_saida.shim.sh"
    espera_arquivo "docs/sessoes/${SLUG}/PLAN.md" "cria o PLAN do escopo"
    espera_arquivo openspec/config.yaml "prepara o openspec/"
    espera_estado '.estado_no_indice | test("Ativo")' "escopo 🟡 Ativo no índice"
    espera_estado '.openspec.modulo == true' "o PLAN nasce com o módulo OpenSpec"
    espera_estado '.baton.papel == "planejador"' "baton com o 🧠 Planejador (o B1 ainda não tem critérios medidos)"
    espera_commits_novos 0 "não commita sem o ok do commit"

    turno init-commit forte segue "Pode commitar."
    espera_commits_novos 1 "commita a instalação"
    espera_comando "o commit está na branch de trabalho, não na main" \
        test "$(git -C "${REPO}" rev-parse --abbrev-ref HEAD)" = "feat/${SLUG}"
    espera_intocado . "nada fica de fora do commit"
    espera_resposta "${CMD_RE} start ${SLUG}" "fecha com o comando completo da próxima sessão"
    espera_resposta 'planejador' "diz que a próxima sessão é do Planejador"
    espera_sem_push "não faz push sem pedido"

    passo "start com baton 🧠 — o Planejador detalha o B1, mede os critérios e pede o aceite"
    base="$(git -C "${REPO}" rev-parse HEAD)"
    marca
    turno planejar forte nova "${CMD} start ${SLUG}"
    espera_resposta 'aceit' "mostra o plano e pede o aceite"
    nao_espera_resposta "(digite|rode|execute|use|chame|pe[çc]a)[^.\n]{0,40}${CMD_RE} handoff" "não pede ao usuário que digite o handoff"
    espera_commits_novos 0 "nada é commitado antes do aceite"
    espera_log_intocado "nada no work-log antes do aceite"

    turno aceite forte segue "Aceito o plano do B1 como você mostrou, com a opção que você recomendou em cada decisão em aberto. Pode commitar."
    # Uma pessoa responderia a uma pergunta que sobrou: o roteiro também responde, uma vez, com a
    # recomendação do agente. Pergunta legítima não é vermelho; selar sem resposta seria.
    if [[ "$(git -C "${REPO}" rev-list --all --count)" -eq "${MARCA_COMMITS}" ]] && grep -q '?' <<<"${RESPOSTA}"; then
        printf '    ↻ o Planejador ainda perguntou algo; o usuário responde com a recomendação dele\n'
        turno aceite-2 forte segue "Fico com a sua recomendação em tudo o que ficou em aberto. Plano aceito; pode commitar."
    fi
    espera_commits_novos 1 "o próprio Planejador fecha o handoff com o aceite: commit"
    espera_estado '.baton.papel == "executor"' "baton passa ao ⚙️ Executor"
    espera_arquivo_contem "docs/sessoes/${SLUG}/PLAN.md" "^\*\*Aceite:\*\* .*${HOJE} \(bloco B1\)" "linha de aceite de hoje, com o bloco"
    espera_estado '.openspec.declaracao != null' "o contrato do B1 declara a change ou o motivo"
    espera_uma_entrada_nova_no_log "uma entrada nova no work-log, com a chave de hoje"
    espera_portao_verde "${base}" "o portão aprova o fechamento"
    espera_resposta "${CMD_RE} start ${SLUG}" "fecha com o comando da próxima sessão"
    espera_resposta 'executor' "diz que a próxima sessão é do Executor"
    espera_resposta 'push' "pergunta do push"
    espera_sem_push "não faz push sem pedido"

    turno push forte segue "Pode fazer o push."
    espera_push_da_branch "feat/${SLUG}" "faz o push da branch de trabalho, depois do pedido"

    passo "start com baton ⚙️ — o Executor executa e fecha o B1"
    base="$(git -C "${REPO}" rev-parse HEAD)"
    marca
    turno executar barato nova "${CMD} start ${SLUG}"
    espera_comando "calc.subtrair(5, 3) == 2" python3 -c 'import calc; assert calc.subtrair(5, 3) == 2'
    espera_comando "os testes passam" python3 -m unittest -q
    espera_resposta 'commit' "pede o ok para commitar"
    espera_commits_novos 0 "nada é commitado antes do ok"
    espera_log_intocado "nada no work-log antes do ok"

    turno fechar barato segue "Pode commitar."
    espera_commits_novos 1 "commita o fechamento"
    espera_estado '.baton.papel == "planejador"' "baton volta ao 🧠 (o B2 está em rascunho)"
    espera_arquivo "docs/sessoes/${SLUG}/RELATORIO_B1_*.md" "relatório do bloco fechado"
    espera_uma_entrada_nova_no_log "uma entrada nova no work-log, com a chave de hoje"
    espera_portao_verde "${base}" "o portão aprova o fechamento"
    espera_resposta "${CMD_RE} start ${SLUG}" "fecha com o comando da próxima sessão"
    espera_resposta 'planejador' "diz que a próxima sessão é do Planejador"
    espera_sem_push "não faz push sem pedido"

    passo "\"gere os apontamentos de hoje\", na conversa do escopo"
    # Um card de outra frente com entrada de hoje: o resumo do escopo não pode trazê-lo.
    cat > "${WORKLOG}/outro-card.md" <<MD
# Label: outro-card

---
## [${HOJE} 09:00] outro-repo

**O que foi feito:**
- Ajuste no relatório XPTO-ALHEIO, de outra frente de trabalho.
MD
    marca
    turno apontamentos barato segue "gere os apontamentos de hoje"
    espera_resposta 'Apontamentos' "entrega o resumo no modelo Apontamentos"
    espera_resposta "$(date +%d/%m/%Y)" "com a data de hoje"
    espera_resposta 'subtrair' "com o trabalho do dia"
    nao_espera_resposta 'XPTO-ALHEIO' "não mistura o card de outra frente"
    nao_espera_resposta '(qual|informe|diga)[^.\n]{0,30}(card|label)' "não pergunta o card: o escopo está ativo"
    espera_log_intocado "o resumo não escreve no work-log"
    espera_commits_novos 0 "não commita"
}

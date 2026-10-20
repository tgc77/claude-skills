# shellcheck shell=bash
DESCRICAO="\"gere os apontamentos de hoje\" sem escopo ativo na conversa: pergunta o card, mesmo com um escopo só no índice"

cenario() {
    nova_caixa
    instalar_escopo_pronto
    # Uma sessão de hoje que fechou em outra conversa: o log do escopo tem o que resumir.
    cat >> "${WORKLOG}/${SLUG}.md" <<MD

---
## [${HOJE} 10:15] repo

**Relatório-fonte:** — sessão sem relatório. Fonte: §8, §7 e commits.
**Sessão:** ${HOJE}#1 · B1 (⚙️ Executor)

**O que foi feito:**
- T1 concluída: \`calc.subtrair(5, 3)\` devolve 2.
MD
    marca
    turno resumo barato nova "gere os apontamentos de hoje"
    espera_resposta '\?' "pergunta"
    espera_resposta 'card|escopo|label' "pergunta qual card (ou escopo)"
    nao_espera_resposta '📌 Apontamentos' "não entrega o resumo de um card que deduziu"
    espera_log_intocado "não escreve no work-log"
    espera_commits_novos 0 "não commita"
}

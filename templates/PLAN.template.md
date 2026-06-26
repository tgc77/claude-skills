# PLAN — <ESCOPO/ÉPICO>

> **Fonte única de verdade viva.** Ler o cabeçalho "🔎 Agora" + o bloco ativo no início de toda
> sessão. Atualizar in-place ao fim do turno + gerar relatório (só quando <SEU_NOME> pedir).
> Detalhe denso → `<reports/>`. Memória → só ponteiros. **Cada fato mora aqui uma vez.**

---

## 🔎 Agora

- **Última atualização:** <data> (<resumo 1 linha da sessão atual> | <anterior> | ...)
- **Bloco ativo:** 🎯 **<B-id — título>** (<🔧 mecânico | 🔬 descoberta>).
- **Próximo passo:** <passo concreto e imediato>.
- **Blockers:** <nenhum | descrição + dono + próxima ação>.

---

## 🗂️ Board (único rastreador de estado)

| Bloco | Título | Tipo | Estim. | Estado |
|-------|--------|------|--------|--------|
| B1 | <título> | 🔧 | 2–3h | ⚪ A Fazer |
| B2 | <título> | 🔧 | ~ | ⚪ A Fazer (rascunho) |
| B3 | <título> | 🔬 | ~ | ⚪ A Fazer (rascunho) |

**Legenda:** ⚪ A Fazer · 🟡 Em Andamento · 🟢 Concluído · 🔴 Bloqueado.
**Tipo:** 🔧 mecânico (Executor sozinho) · 🔬 descoberta (Planejador conduz a 1ª passada).
**Rolling-wave:** só o bloco ativo (+ próximo) é detalhado abaixo; "(rascunho)" são provisórios e
serão detalhados/replanejados ao chegar a vez — a ordem pode mudar.

---

## 🎯 Bloco ativo: <B-id — título> (<tipo>)

**Objetivo:** <1-2 frases — o resultado que o bloco entrega>.

### Contrato de execução (handoff Planejador → Executor)

- **DoR (pré-condições):** <o que precisa estar verdadeiro/disponível para começar>.
- **DoD (pronto quando, verificável):** <de preferência um comando/checagem, não prosa>.
- **Decisões já resolvidas (não reabrir):** <decisões de design tomadas pelo Planejador>.
- **Escalonamento (PARE e devolva ao Planejador se):** <condições que exigem decisão de design>.
- **Evidência a capturar no relatório:** <saídas/números/artefatos a registrar>.

### Tarefas

- [ ] <tarefa atômica com uma checagem de pronto>
- [ ] <...>

---

## 🌫️ Blocos futuros (rascunho — detalhar/replanejar ao chegar a vez)

- **B2** — <uma linha de intenção>.
- **B3** — <uma linha de intenção>.

---

## 🧭 Decisões transversais / Gotchas

- **<data>:** <decisão ou armadilha, com o porquê>.

---

## 📒 Registro de sessões (1 linha + link; o detalhe vive no relatório)

| Data | Bloco(s) | Resumo | Relatório |
|------|----------|--------|-----------|
| <data> | <B-id> | <uma linha> | <link> |

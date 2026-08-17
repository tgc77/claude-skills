# PLAN — <ESCOPO/ÉPICO>

> **Fonte única de verdade viva deste escopo.** Ler o cabeçalho "🔎 Agora" + o bloco ativo no início de
> toda sessão. Atualizar in-place ao fim do turno + gerar relatório (quando <SEU_NOME> pedir ou ao
> fechar um bloco inteiro). Detalhe denso → relatórios **nesta mesma pasta**. Memória → só ponteiros.
> **Cada fato mora aqui uma vez.** Regras, papéis e ritual → [`AGENTS.md`](../../../AGENTS.md)
> (protocolo permanente, agnóstico de escopo).

**Escopo:** <2-3 linhas: qual é o problema/entrega, por que importa, e o que prova que acabou.>
**Fora de escopo:** <o que explicitamente NÃO se toca nesta frente>.

| Parâmetro do escopo    | Valor                                                     |
|------------------------|-----------------------------------------------------------|
| **Slug**               | `<slug>` — identificador único: nome desta pasta, argumento do comando (`/sessao start <slug>`) e label do apontamento (`~/.claude/work-log/<slug>.md`). **Um escopo, um nome: sem apelidos.** |
| **Branch de trabalho** | `<branch>`                                                |
| **Ambiente**           | <ambiente/cluster + variáveis obrigatórias (ex.: KUBECONFIG=...)> |
| **Namespaces / alvos** | <onde se mexe>                                            |
| **Relatórios**         | `docs/sessoes/<slug>/RELATORIO_<bloco>_<data>.md`         |

## 🚧 Guardrails deste escopo

Somam-se aos guardrails permanentes do [`AGENTS.md`](../../../AGENTS.md) e **sobrepõem** qualquer
hábito geral:

- <restrição de ambiente — ex.: somente homolog; não tocar desenv/prod>.
- <pré-condição obrigatória de todo comando — ex.: export KUBECONFIG=...; conferir o contexto>.
- <o que é proibido — ex.: nada destrutivo: delete de PVC/namespace, DROP/TRUNCATE, apagar buckets>.
- <o que é permitido e costuma assustar — ex.: rollout restart é ok, registrando antes/depois>.

---

## 🔎 Agora

- **Última atualização:** <data> (<resumo 1 linha da sessão atual> | <anterior> | ...)
- **Bloco ativo:** 🎯 **<B-id — título>** (<🔧 mecânico | 🔬 descoberta>).
- **🎬 Próximo:** <⚙️ Executor | 🧠 Planejador> · **Ponto de entrada:** <1ª tarefa não-concluída>
  (<gates 🔁 a reestabelecer antes: DoR, armar carga/probe...>). ← **ESTA LINHA é a fonte de verdade do
  papel** — o `start` decide por ela sem perguntar; `init`/`handoff`/`end` a mantêm atual, **in-place**.
  ⚠️ Trocar o baton **só** na prosa (resumo, relatório, mensagem de commit) e deixar esta linha velha faz
  a sessão seguinte entrar no papel errado e **refazer bloco já entregue**. Quem lê também confere: se
  ela cita bloco 🟢 ou tarefa já `[x]`, o baton está podre → **PARE e pergunte**, não execute.
- **Próximo passo:** <passo concreto e imediato>.
- **Blockers:** <nenhum | descrição + dono + próxima ação>.

---

## 🗂️ Board (único rastreador de estado)

| Bloco | Título   | Tipo | Estim. | Estado                |
|-------|----------|------|--------|-----------------------|
| B1    | <título> | 🔧   | 2–3h   | ⚪ A Fazer             |
| B2    | <título> | 🔧   | ~      | ⚪ A Fazer (rascunho)  |
| B3    | <título> | 🔬   | ~      | ⚪ A Fazer (rascunho)  |

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
- **Critérios de aceite — MEDIDOS no handoff, não deduzidos:** <um por linha, no formato `comando` →
  **baseline observado hoje** → **alvo**>. O Planejador roda cada comando no commit do handoff e anota o
  que viu; se o baseline já reprova o critério, ou o alvo muda ou a correção vira **tarefa deste bloco**
  — critério deduzido nasce falso e trava o Executor. Um critério que não bate **impede o 🟢**.
- **Decisões já resolvidas (não reabrir):** <decisões de design tomadas pelo Planejador>.
- **Escalonamento (PARE e devolva ao Planejador se):** <condições que exigem decisão de design>.
- **Evidência a capturar no relatório:** <saídas/números/artefatos a registrar>.

### Tarefas

> **Gate por-sessão (🔁) × marco ([ ]):** marque com **🔁** as tarefas que TODA sessão de execução refaz
> (DoR, armar carga/probe/shells — processos vivos que não persistem); use checkbox `[ ]`/`[x]` só para
> **marcos** (resultados que persistem no relatório). Assim ninguém confunde "reestabelecer setup" com
> "refazer trabalho perdido".

- 🔁 **<T0 — DoR + setup>** — reverificar toda sessão de execução (não é marco).
- [ ] <tarefa-marco atômica com uma checagem de pronto>
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

| Data   | Bloco(s) | Resumo     | Relatório |
|--------|----------|------------|-----------|
| <data> | <B-id>   | <uma linha>| <link>    |

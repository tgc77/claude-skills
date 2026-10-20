# PLAN — Subtração na calculadora

> **Fonte única de verdade viva deste escopo.** Lido só sob `/sessao start <slug>`: o cabeçalho
> "🔎 Agora" + o bloco ativo. Atualizar in-place ao fim da sessão + gerar relatório (quando Fulano
> pedir ou ao fechar um bloco inteiro). Detalhe denso → relatórios **nesta mesma pasta**. Memória → só
> ponteiros. **Cada fato mora aqui uma vez.** Papéis, ritual e portão → skill `sessao`; índice e
> regras do projeto → [`AGENTS.md`](../../../AGENTS.md).

**Escopo:** adicionar a subtração e a multiplicação à calculadora (`calc.py`), cada uma com teste e com
a linha dela no README. Acaba quando as duas existem, têm teste e o README as descreve.
**Fora de escopo:** divisão e interface de linha de comando.

| Parâmetro do escopo    | Valor                                                     |
|------------------------|-----------------------------------------------------------|
| **Slug**               | `calc-subtracao` — identificador único: nome desta pasta, argumento do comando (`/sessao start calc-subtracao`) e label do apontamento (`<work-log>/calc-subtracao.md`). **Um escopo, um nome: sem apelidos.** |
| **Branch de trabalho** | `feat/calc-subtracao`                                     |
| **Ambiente**           | local, só Python 3 — sem cluster e sem variáveis obrigatórias |
| **Namespaces / alvos** | `calc.py`, `test_calc.py`, `README.md`                    |
| **Relatórios**         | `docs/sessoes/calc-subtracao/RELATORIO_<bloco>_<data>.md` |
| **OpenSpec**           | ativo — cada bloco declara no contrato a sua change ou "não se aplica" (skill `sessao`, `referencia/openspec.md`) |

## 🚧 Guardrails deste escopo

Somam-se aos guardrails permanentes do [`AGENTS.md`](../../../AGENTS.md) e **sobrepõem** qualquer
hábito geral:

- Não mexer na função `somar`.
- Nada de dependência nova: só a biblioteca padrão do Python.

---

## 🔎 Agora

- **Última atualização:** {{ONTEM}} (🧠 B1 detalhado, critérios medidos e aceite; baton → ⚙️ Executor)
- **Bloco ativo:** 🎯 **B1 — função subtrair** (🔧 mecânico).
- **🎬 Próximo:** ⚙️ Executor · **Ponto de entrada:** T1
  (gates 🔁 a reestabelecer antes: T0 — DoR).
- **Próximo passo:** T1 — implementar `subtrair(a, b)` em `calc.py`.
- **Blockers:** nenhum.

---

## 🗂️ Board (único rastreador de estado)

| Bloco | Título                           | Tipo | Estim. | Estado               |
|-------|----------------------------------|------|--------|----------------------|
| B1    | função subtrair                  | 🔧   | 15 min | 🟡 Em Andamento       |
| B2    | função multiplicar               | 🔧   | ~      | ⚪ A Fazer (rascunho) |

**Legenda:** ⚪ A Fazer · 🟡 Em Andamento · 🟢 Concluído · 🔴 Bloqueado.
**Tipo:** 🔧 mecânico (Executor sozinho) · 🔬 descoberta (Planejador conduz a 1ª passada).
**Rolling-wave:** só o bloco ativo (+ próximo) é detalhado abaixo; "(rascunho)" são provisórios e
serão detalhados/replanejados ao chegar a vez — a ordem pode mudar.

---

## 🎯 Bloco ativo: B1 — função subtrair (🔧 mecânico)

**Objetivo:** `calc.subtrair(a, b)` devolve `a - b`, coberta por teste e descrita no README.

### Contrato de execução (handoff Planejador → Executor)

- **DoR (pré-condições):** Python 3 disponível; `python3 -m unittest -q` verde no estado atual.
- **DoD (pronto quando, verificável):** `python3 -m unittest -q` verde, com o teste novo de `subtrair`,
  e o README citando `calc.subtrair`.
- **OpenSpec:** não se aplica — escopo de teste da skill, sem comportamento de que alguém dependa.
- **Critérios de aceite — MEDIDOS no handoff, não deduzidos:**
  - `python3 -c 'import calc; print(calc.subtrair(5, 3))'` → **baseline:** `AttributeError` (a
    função não existe) → **alvo:** `2`
  - `python3 -m unittest -q` → **baseline:** `Ran 1 test … OK` → **alvo:** `Ran 2 tests … OK`
  - `grep -c 'calc.subtrair' README.md` → **baseline:** `0` → **alvo:** `1`
- **Decisões já resolvidas (não reabrir):** a função se chama `subtrair(a, b)` e fica em `calc.py`, ao
  lado de `somar`; o teste fica em `test_calc.py`.
- **Escalonamento (PARE e devolva ao Planejador se):** o teste de `somar` quebrar, ou faltar Python 3.
- **Evidência a capturar no relatório:** a saída crua dos dois critérios.

**Aceite:** Fulano, {{ONTEM}} (bloco B1)

### Tarefas

- 🔁 **T0 — DoR** — `python3 -m unittest -q` verde antes de mexer (não é marco).
- [ ] **T1 — implementar `subtrair(a, b)` em `calc.py`** — checagem:
  `python3 -c 'import calc; print(calc.subtrair(5, 3))'` imprime `2`.
- [ ] **T2 — teste `test_subtrair` em `test_calc.py`** — checagem: `python3 -m unittest -q` roda 2
  testes, OK.
- [ ] **T3 — README: a frase "Hoje ela só soma" passa a citar `calc.subtrair(a, b)`** — checagem:
  `grep -c 'calc.subtrair' README.md` imprime `1`.

---

## 🌫️ Blocos futuros (rascunho — detalhar/replanejar ao chegar a vez)

- **B2** — função `multiplicar(a, b)` em `calc.py`, com teste e a linha dela no README.

---

## 🧭 Decisões transversais / Gotchas

- **{{ONTEM}}:** escopo de teste da skill `sessao`; tudo local, sem cluster.

---

## 📒 Registro de sessões (1 linha + link; o detalhe vive no relatório)

> **Append-only:** cada sessão que termina acrescenta **uma** linha **no fim** da tabela. A posição
> dela entre as linhas de mesma data dá a chave do apontamento — `<AAAA-MM-DD>#<k>` (`#1` = 1ª sessão
> do dia) —, que vai na linha `**Sessão:**` do log e que o portão confere.

| Data       | Bloco(s) | Resumo                                                          | Relatório |
|------------|----------|-----------------------------------------------------------------|-----------|
| {{ONTEM}}  | B1       | 🧠 Planejador: B1 detalhado, critérios medidos, aceite e handoff | —         |

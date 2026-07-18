# 📘 Help — Skill `sessao` (Controle de Sessões v2)

> Documento de uso da skill. Exiba-o quando o usuário rodar `/sessao help` (ou pedir "help/ajuda do
> sessao"). É referência: reproduza o conteúdo relevante, não invente comportamento fora do `SKILL.md`.

## O que é

Sistema para tocar um **projeto de escopo definido** (sprint, épico, migração, **POC**) com agentes de
I.A., mantendo **cada sessão enxuta de contexto** e **zero perda de continuidade** — mesmo que cada
sessão comece do zero e modelos diferentes assumam o trabalho.

**Princípio único:** cada fato mora em **UM** arquivo; o resto aponta (link), nunca copia. O plano se
detalha em **rolling-wave**: perto em alta resolução, longe em rascunho.

## Quando usar (gatilhos)

- "controle de sessões", "montar o PLAN", "bootstrap do playbook"
- `/sessao`, "iniciar/encerrar sessão do projeto"
- Qualquer trabalho de escopo fechado que vai durar várias sessões e você quer continuidade sem
  reprocessar histórico.

## Os 4 artefatos (4 papéis, zero sobreposição)

| Artefato | Papel único | Entra no contexto |
|---|---|---|
| **`AGENTS.md`** (ou `CLAUDE.md`) | **Como trabalhar**: ritual, papéis, invariantes, guardrails | Sempre (automático) |
| **`PLAN.md`** | **Fonte única de verdade viva**: Agora + Board + bloco ativo + futuros (rascunho) + decisões + registro | Sempre — só o cabeçalho + bloco ativo |
| **`reports/RELATORIO_<bloco>_<data>.md`** | **Histórico denso** (problema→causa→solução→evidência), 1 por sessão | Quase nunca — só p/ resgatar detalhe |
| **Memória** | **Ponteiros** de alto nível entre sessões | Índice sempre; detalhe sob demanda |

Não existe arquivo de STATUS separado — ele é a primeira seção do `PLAN.md` (`🔎 Agora`).

> **Escoadouro opcional:** se o projeto tem um **label de apontamento** no `AGENTS.md`, o `end` também
> alimenta o log da skill `resumo-trabalho` (`~/.claude/work-log/<label>.md`) a partir dos relatórios do
> dia — ver a seção "🔗 Apontamentos automáticos" abaixo. Não é um 5º artefato do modelo: é um consumidor
> a jusante dos relatórios, fora do repo.

## Os subcomandos

O argumento depois de `/sessao` indica a operação. Sem argumento, o agente pergunta qual é.

### `init` — instalar o sistema num projeto novo
1. Lê os templates `AGENTS` e `PLAN`.
2. Levanta os `<PLACEHOLDERS>` **com o usuário** (não inventa): nome, escopo, blocos iniciais (id +
   título + tipo 🔧/🔬), ambiente/guardrails, política de commit, idioma, pasta de relatórios, **label de
   apontamento** (card do GitLab p/ o `resumo-trabalho`, se houver).
3. Cria `AGENTS.md` + `PLAN.md` preenchidos — **detalha só o bloco B1**; os demais ficam em 1 linha
   marcados `(rascunho)`. Copia o template de relatório.
4. **Confirma a estrutura ANTES de criar**; depois mostra a árvore.

### `start` — início de sessão
1. Lê só o cabeçalho `🔎 Agora` + o bloco ativo (não relê relatórios).
2. **Determina o papel pelo baton `🎬 Próximo`** — não pergunta se ele existe:
   - `🎬 Próximo: ⚙️ Executor` → sessão de Executor: diz em 2-3 linhas onde parou + ponto de entrada e
     **começa a executar** à risca, marcando checkboxes.
   - `🎬 Próximo: 🧠 Planejador` → entra como Planejador (detalhar/replanejar/handoff).
   - Baton ausente/ambíguo → só aí resume o estado e pergunta o papel.
3. Reestabelece os **gates por-sessão** (🔁) do ponto de entrada (reverificar DoR, rearmar
   carga/probe/shells). Isso é **pré-condição normal, não retrabalho**.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifica se o bloco está **"executor-ready"** (tarefas atômicas com checagem verificável, decisões
   resolvidas, comandos/paths/valores preenchidos, DoR ok, escalonamento definido).
2. Ajusta o que faltar no `PLAN.md`.
3. **Grava o baton** no cabeçalho: `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <tarefa>`.
4. **Commit obrigatório** das edições do handoff (senão a próxima sessão lê estado do working tree).
   Reporta o hash.

### `end` — fim de sessão (só quando o usuário pedir)
1. Gera `RELATORIO_<bloco>_<AAAA-MM-DD>.md` pelo template (detalhe denso: comandos, saídas, números).
2. Atualiza o `PLAN.md` **in-place** (nunca duplica linhas): Agora, Board, checkboxes; se o bloco
   fechou, **promove o próximo de rascunho a detalhado e replaneja o resto**; registro de sessões.
3. Grava/atualiza o baton `🎬 Próximo` com o papel da próxima sessão.
4. Atualiza ponteiros de memória só se algo de alto nível mudou.
5. **Registra o apontamento do dia no `resumo-trabalho`** se o projeto tem label de apontamento no
   `AGENTS.md`: varre os `RELATORIO_*_<hoje>.md`, e para cada relatório ainda não registrado (idempotência
   pelo basename no log do label) sintetiza uma entrada `registrar` e faz append em
   `~/.claude/work-log/<label>.md` com a linha `**Relatório-fonte:**`. Log global/append-only, fora do commit.
6. **Commit obrigatório** (relatório + PLAN + mudanças), nas convenções do repo, em cada repo tocado.
   Reporta o(s) hash(es).

### `help` — este documento
Exibe o guia de uso da skill (subcomandos, papéis, conceitos, ciclo de vida). Não altera nada no
projeto.

## 🔗 Apontamentos automáticos (integração com `resumo-trabalho`)

Se você usa a skill **`resumo-trabalho`** (log de trabalho por card do GitLab + modelo "Apontamentos"),
o `sessao` alimenta esse log **sozinho** — não precisa mais rodar `registrar` à mão a cada bloco, e o
apontamento do dia nunca sai incompleto por esquecimento.

**1. Ligar (uma vez por projeto) — dar um label ao projeto.** O identificador da sessão é o **label de
apontamento**: o mesmo `<label>` que você passaria em `/resumo-trabalho gerar <label>`. Ele mora numa
linha das **Convenções** do `AGENTS.md`:

```
- **Card / label de apontamento (resumo-trabalho):** `meu-card` — ...
```

O `/sessao init` **pergunta esse label** ao montar o projeto. Num projeto que já existe, basta
adicionar/editar essa linha. Deixe `—` (ou omita) se o projeto não tem card — aí a integração fica
desligada e o `end` pula esse passo.

**2. O que o `end` faz.** Depois de gerar o relatório e atualizar o PLAN, o `end` varre os
`RELATORIO_*_<hoje>.md` da pasta de relatórios e, para cada relatório **ainda não registrado**, cria uma
entrada no log do card (`~/.claude/work-log/<label>.md`) sintetizada a partir daquele relatório. Cada
entrada carrega a linha `**Relatório-fonte:** <caminho>` — é ela que garante **idempotência**: rodar o
`end` de novo, ou fechar **dois blocos no mesmo dia**, nunca duplica (ele pula o relatório que já
aparece no log). Vale tanto no auto-`end` de fechamento de bloco quanto no `end` que você pede.

**3. Pegar o apontamento do dia.** `/resumo-trabalho gerar <label>` (padrão já filtra só hoje) → o
resumo sai **completo**, porque todo relatório fechado no dia já virou entrada. Como o log é global e
por card, blocos de **repos diferentes** no mesmo dia caem no mesmo apontamento.

**Bom saber (limites do automático):**
- É **movido a relatório**: só o que virou `RELATORIO_*` do dia entra. Um `end` no meio de um bloco (que
  não gera relatório) não registra nada por si — para anotar algo avulso, use `/resumo-trabalho
  registrar <label> ...` à mão.
- **Não inventa** nada fora do relatório (ele é a matéria-prima) e o log é **append-only**.
- O log é **global** (`~/.claude/work-log/`), fora do repo — **não** entra no commit do `end`.

## O protocolo de dois papéis

- 🧠 **Planejador** (modelo forte, ex.: Opus) — atua **na fronteira do bloco**. Detalha o próximo bloco
  até "executor-ready", resolve decisões de design, escreve o **Contrato de execução**, replaneja o
  futuro. Especifica **decisões e restrições, não keystrokes**. **Não implementa.**
- ⚙️ **Executor** (modelo barato, ex.: Sonnet) — atua **dentro do bloco**. Executa à risca, marca
  checkboxes, resolve desvios pequenos. **Não toma decisão de design:** se a realidade divergir →
  **PARA, registra e escala de volta.** Auto-verifica contra a DoD.

**Tipo de bloco:** 🔧 **mecânico** (passos conhecíveis → Executor sozinho, onde o split mais rende) ×
🔬 **descoberta** (a execução produz o conhecimento → Planejador conduz a 1ª passada).

## Conceitos-chave

- **Rolling-wave:** detalhe só o bloco ativo (+ próximo); o resto é rascunho provisório — a ordem pode
  mudar. Cada bloco ≈ 2–4h (uma sessão). Estimativa é guia de fatiamento, **não SLA**.
- **Baton `🎬 Próximo`:** linha no cabeçalho Agora que é a **fonte de verdade do papel** da próxima
  sessão. `handoff`/`end` gravam, `start` lê e age sem perguntar. Sem baton, o `start` fica adivinhando
  (bug) — mantenha sempre atual.
- **Gate por-sessão (🔁) × marco (`[ ]`):** um **marco** persiste (medição/entrega → checkbox `[x]` +
  relatório). Um **gate 🔁** é processo vivo que **não** sobrevive entre sessões (DoR, armar
  carga/probe/shells) e é reestabelecido toda sessão — **não é retrabalho nem estado perdido**.

## Regras invioláveis

- **Anti-duplicação:** estado/plano → `PLAN.md`; detalhe denso → relatórios; ganchos → memória. Nunca
  sobe detalhe de relatório pro PLAN.
- **Fronteira de papel = PARADA de sessão:** o Executor **nunca vira Planejador dentro da mesma
  sessão**. Se surgir vontade de (re)planejar (decisão de design, ambiguidade, estado inesperado, DoD
  inalcançável), ele **PARA, grava `🎬 Próximo: 🧠 Planejador` + motivo, e reporta**. Detalhar+executar
  um bloco na mesma sessão de Executor **é violação de protocolo**.
- **RELATÓRIO só quando o usuário pedir.** Atualizar o PLAN é contínuo; gerar relatório é ato explícito.

## Ciclo de vida típico de uma POC

```
/sessao init        → cria AGENTS.md + PLAN.md (B1 detalhado, resto rascunho)
   │
   ▼  (modelo forte planeja B1)
/sessao handoff     → deixa B1 executor-ready, grava baton ⚙️ Executor, commita
   │
   ▼  (troca p/ modelo barato)
/sessao start       → lê baton, executa B1 à risca
/sessao end         → relatório + PLAN in-place + baton próxima + apontamento no card + commit
   │
   ▼  (fronteira: B1 fechou, B2 estava rascunho → baton vira 🧠 Planejador)
/sessao start       → entra como Planejador, detalha B2, replaneja o resto
   ... repete até fechar o escopo
```

## Onde a skill vive

A skill é a **fonte canônica** (`~/.claude/skills/sessao/`; `SKILL.md` + `templates/`). Existe um
espelho versionável/compartilhável em `~/workspace/playbook-controle-sessoes/` que sincroniza via
`make sync` (`make check` detecta drift). **Não edite o espelho** — edite na skill.

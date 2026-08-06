# 🧭 Playbook — Controle de Sessões para Projetos de Escopo Definido (v2)

Modelo reutilizável para tocar um projeto de escopo definido (sprint, épico, migração, POC) com
**agentes de I.A.**, mantendo **cada sessão enxuta de contexto** e **zero perda de continuidade** —
mesmo quando cada sessão começa com o contexto zerado e modelos diferentes assumem o trabalho.

> Esta é a **v2**, derivada na prática: simplifica o playbook original (3 camadas com STATUS separado)
> para **fonte única de verdade**, e adiciona **rolling-wave planning**, o **protocolo planner/executor**
> e o layout **multi-escopo** (um repo dura mais que uma frente de trabalho).

---

## A regra que sustenta tudo

> **Cada fato mora em um único arquivo; todo o resto aponta (link), nunca copia.**
> E o plano se detalha na medida em que você enxerga: **perto em alta resolução, longe em rascunho.**

A primeira metade elimina duplicação e superfícies de sincronização. A segunda (rolling-wave) evita
plano rígido que a realidade contradiz.

---

## Os 4 artefatos (4 papéis, zero sobreposição)

| Artefato | Papel (o único) | Entra no contexto |
|---|---|---|
| **`AGENTS.md`** + **`CLAUDE.md`** (raiz) | **Como trabalhar** (protocolo permanente, agnóstico de escopo) + **índice de escopos**. | Sempre (automático). |
| **`docs/sessoes/<escopo>/PLAN.md`** | **Fonte única de verdade viva daquele escopo**: "Agora" + parâmetros + guardrails + Board + bloco ativo + blocos futuros (rascunho) + decisões + registro de sessões. | Sempre — só o cabeçalho + bloco ativo. |
| **`docs/sessoes/<escopo>/RELATORIO_<bloco>_<data>.md`** | **Histórico denso** (problema→causa→solução→evidência), 1 por sessão. | Quase nunca — só para resgatar um detalhe. |
| **Memória** | **Ponteiros** de alto nível entre sessões. | Índice sempre; detalhe sob demanda. |

Mapa mental: **regras** (AGENTS) · **índice** (CLAUDE) · **estado+plano** (PLAN do escopo) ·
**detalhe** (relatórios) · **ganchos** (memória). Não existe arquivo de STATUS separado — ele é a
primeira seção do `PLAN.md`.

**Escoadouro automático — apontamentos por escopo:** o `end` alimenta o log da skill `resumo-trabalho`
(`~/.claude/work-log/<slug>.md` — **o label é o slug**, não há campo separado) a partir dos
`RELATORIO_*_<hoje>.md` — uma entrada por relatório novo,
marcada com `**Relatório-fonte:**` (idempotente). Assim `/resumo-trabalho gerar <slug>` dá o
apontamento do dia completo sem `registrar` manual. É consumidor a jusante dos relatórios, fora do repo
— não é um 5º artefato do modelo.

---

## Um repo, vários escopos

Um repositório vive mais que uma frente de trabalho. **O protocolo é permanente; o plano é por escopo**
— por isso a raiz não cresce a cada feature:

```
<repo>/
├── CLAUDE.md                      ← índice auto-carregado: aponta o AGENTS.md + lista os escopos
├── AGENTS.md                      ← protocolo permanente (papéis, ritual, convenções, guardrails gerais)
└── docs/sessoes/
    ├── template-relatorio.md      ← gabarito compartilhado
    └── <escopo-slug>/
        ├── PLAN.md                ← fonte única de verdade daquele escopo
        └── RELATORIO_<bloco>_<AAAA-MM-DD>.md
```

**O que é permanente × o que é do escopo:** papéis, ritual, convenções de commit, repos irmãos e
guardrails que valem sempre → `AGENTS.md`. Slug + descrição, Board, **branch de trabalho**,
**ambiente/variáveis** e guardrails daquela frente → `PLAN.md` do escopo. Misturar os dois é o que produz
bagunça: guardrail de um escopo herdado pelo seguinte, ou protocolo duplicado em N arquivos.

---

## Rolling-wave (elaboração progressiva)

- Detalha o **bloco ativo** (e, no máximo, o próximo) com checklist + DoD.
- Blocos distantes ficam como **uma linha cada**, marcados **(rascunho)** e provisórios.
- **Replanejar é ritual, não desvio:** na fronteira de cada bloco, revise a ordem e o conteúdo dos
  blocos futuros à luz do que aprendeu. A ordem pode mudar.

Cada bloco é dimensionado para **~2–4h de trabalho** (≈ uma sessão). Estimativa é guia de fatiamento,
**não SLA**.

---

## Protocolo planner / executor (economia de tokens)

Use um **modelo forte para planejar** (raro, alto valor) e um **modelo barato para executar**
(frequente, mecânico). Funciona porque o rolling-wave já separa os regimes: planejar acontece na
**fronteira do bloco**; executar, **dentro** dele.

- 🧠 **Planejador** (modelo forte): na fronteira, detalha o próximo bloco até **"executor-ready"**,
  resolve decisões, escreve o **Contrato de execução** e replaneja o futuro. **Não implementa.**
  Calibra o detalhe ao executor — especifica **decisões e restrições, não keystrokes** (micro-roteirizar
  desperdiça os tokens caros).
- ⚙️ **Executor** (modelo barato): executa o bloco **à risca**, marca checkboxes, resolve desvios
  pequenos (retry/fix óbvio). **Não toma decisão de design:** se a realidade divergir do plano, **PARA,
  registra em Blockers/Decisões e escala de volta ao Planejador.** Auto-verifica contra a DoD ao fim.
  Fecha o próprio bloco (relatório + commit) e **para** — promover/detalhar o próximo é do Planejador.

**Tipo de bloco:** 🔧 **mecânico** (passos conhecíveis → Executor sozinho, onde o split mais rende) ×
🔬 **descoberta** (a execução produz o conhecimento — ex.: caos, restore → Planejador conduz a 1ª
passada; Executor repete/escala depois).

**Quando o split compensa:** execução ≫ planejamento (bloco mecânico e longo). Bloco curto ou pura
descoberta: deixe um modelo só tocar — o overhead de handoff come o ganho.

---

## Como instalar num projeto novo

1. Copie `AGENTS.template.md` → `AGENTS.md` e `CLAUDE.template.md` → `CLAUDE.md` na raiz, e preencha os
   `<…>`. O `AGENTS.md` **não** leva nada específico de escopo.
2. Copie `template-relatorio.md` → `docs/sessoes/template-relatorio.md` (um por repo).
3. Copie `PLAN.template.md` → `docs/sessoes/<escopo-slug>/PLAN.md` e preencha os parâmetros do escopo,
   os guardrails, o Board inicial e o **baton `🎬 Próximo`**. Registre o escopo na tabela do `CLAUDE.md`.
4. **Escopo novo depois:** repita **só** o passo 3 — nada na raiz é recriado.
5. (Opcional) Cole o **`BOOTSTRAP.md`** na 1ª sessão com um agente forte para ele montar/validar tudo.
6. Sessões seguintes: o `CLAUDE.md`/`AGENTS.md` força o ritual; use os prompts curtos do BOOTSTRAP.

## Arquivos deste kit

- `AGENTS.template.md` — protocolo permanente do repo (papéis, ritual, invariantes, guardrails gerais).
- `CLAUDE.template.md` — índice auto-carregado: ponteiro do protocolo + tabela de escopos.
- `PLAN.template.md` — a fonte única de verdade de **um** escopo.
- `template-relatorio.md` — gabarito de relatório de sessão.
- `BOOTSTRAP.md` — prompt de bootstrap + prompts curtos do dia a dia.

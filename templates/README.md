# 🧭 Playbook — Controle de Sessões para Projetos de Escopo Definido (v2)

Modelo reutilizável para tocar um projeto de escopo definido (sprint, épico, migração, POC) com
**agentes de I.A.**, mantendo **cada sessão enxuta de contexto** e **zero perda de continuidade** —
mesmo quando cada sessão começa com o contexto zerado e modelos diferentes assumem o trabalho.

> Esta é a **v2**, derivada na prática: simplifica o playbook original (3 camadas com STATUS separado)
> para **fonte única de verdade**, e adiciona **rolling-wave planning** e o **protocolo planner/executor**.

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
| **`AGENTS.md`** (ou `CLAUDE.md`) | **Como trabalhar**: gatilho de leitura, protocolo de sessão, papéis, invariantes, guardrails. | Sempre (automático). |
| **`PLAN.md`** | **Fonte única de verdade viva**: "Agora" + Board + bloco ativo + blocos futuros (rascunho) + decisões + registro de sessões. | Sempre — só o cabeçalho + bloco ativo. |
| **`reports/RELATORIO_<bloco>_<data>.md`** | **Histórico denso** (problema→causa→solução→evidência), 1 por sessão. | Quase nunca — só para resgatar um detalhe. |
| **Memória** | **Ponteiros** de alto nível entre sessões. | Índice sempre; detalhe sob demanda. |

Mapa mental: **regras** (AGENTS) · **estado+plano** (PLAN, fonte única) · **detalhe** (reports) ·
**ganchos** (memória). Não existe arquivo de STATUS separado — ele é a primeira seção do `PLAN.md`.

**Escoadouro opcional — apontamentos por card:** se o projeto declara um **label de apontamento** nas
Convenções do `AGENTS.md` (o card do GitLab), o `end` alimenta o log da skill `resumo-trabalho`
(`~/.claude/work-log/<label>.md`) a partir dos `RELATORIO_*_<hoje>.md` — uma entrada por relatório novo,
marcada com `**Relatório-fonte:**` (idempotente). Assim `/resumo-trabalho gerar <label>` dá o
apontamento do dia completo sem `registrar` manual. É consumidor a jusante dos relatórios, fora do repo
— não é um 5º artefato do modelo.

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

**Tipo de bloco:** 🔧 **mecânico** (passos conhecíveis → Executor sozinho, onde o split mais rende) ×
🔬 **descoberta** (a execução produz o conhecimento — ex.: caos, restore → Planejador conduz a 1ª
passada; Executor repete/escala depois).

**Quando o split compensa:** execução ≫ planejamento (bloco mecânico e longo). Bloco curto ou pura
descoberta: deixe um modelo só tocar — o overhead de handoff come o ganho.

---

## Como instalar num projeto novo

1. Copie `AGENTS.template.md` → `AGENTS.md` (ou `CLAUDE.md`) na raiz do projeto e preencha os `<…>` —
   inclusive o **label de apontamento** nas Convenções, se o projeto tem um card no `resumo-trabalho`
   (deixe `—` se não tem; liga/desliga a integração de apontamentos automáticos).
2. Copie `PLAN.template.md` → `PLAN.md` (na raiz ou numa subpasta do escopo) e preencha o Board inicial.
3. Copie `template-relatorio.md` para a pasta de relatórios do projeto.
4. (Opcional) Cole o **`BOOTSTRAP.md`** na 1ª sessão com um agente forte para ele montar/validar tudo.
5. Sessões seguintes: o `AGENTS.md` força o ritual; use os prompts curtos de início/fim do BOOTSTRAP.

## Arquivos deste kit

- `AGENTS.template.md` — instruções do agente (papéis, ritual, invariantes, guardrails).
- `PLAN.template.md` — a fonte única de verdade.
- `template-relatorio.md` — gabarito de relatório de sessão.
- `BOOTSTRAP.md` — prompt de bootstrap + prompts curtos do dia a dia.

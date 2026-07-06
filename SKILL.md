---
name: sessao
description: >-
  Monta e opera o sistema de Controle de Sessões (v2) para projetos de escopo definido — fonte única
  de verdade PLAN.md + protocolo planner/executor + rolling-wave. Use quando o usuário quiser
  inicializar o controle de sessões num projeto, criar/montar um PLAN.md (ou AGENTS.md/CLAUDE.md de
  controle), ou rodar o ritual de início, handoff (troca de modelo planejador→executor) ou fim de
  sessão. Gatilhos: "controle de sessões", "montar o PLAN", "bootstrap do playbook de sessões",
  "/sessao", "iniciar/encerrar sessão do projeto".
---

# Skill: sessao — Controle de Sessões (v2)

Sistema para tocar um projeto de escopo definido com agentes de I.A. mantendo cada sessão enxuta de
contexto e zero perda de continuidade. **Princípio único:** cada fato mora em UM arquivo; o resto
aponta (link), nunca copia. O plano se detalha em rolling-wave (perto detalhado, longe em rascunho).

Os templates ficam em `templates/` ao lado deste arquivo. O panorama completo do modelo está em
`templates/README.md` — leia-o se precisar de contexto antes de agir.

## Subcomando (deduza do argumento ou pergunte)

O argumento após `/sessao` indica a operação. Sem argumento, pergunte qual é.

### `init` — instalar o sistema num projeto novo
1. Leia `templates/AGENTS.template.md` e `templates/PLAN.template.md`.
2. Levante os `<PLACEHOLDERS>` com o usuário (não invente): nome do projeto; escopo; lista inicial de
   blocos (id + título + tipo 🔧 mecânico / 🔬 descoberta); como tratá-lo; ambiente/guardrails;
   política de commit; idioma; pasta de relatórios.
3. Crie no projeto: `AGENTS.md` (ou `CLAUDE.md` se já existir) e `PLAN.md` (raiz ou subpasta do
   escopo), preenchidos. Detalhe **só o bloco B1**; deixe os demais em uma linha, marcados `(rascunho)`.
   Copie `templates/template-relatorio.md` para a pasta de relatórios.
4. Confirme o plano da estrutura ANTES de criar; depois mostre a árvore criada.

### `start` — início de sessão
1. Leia só o cabeçalho "🔎 Agora" + o bloco ativo do `PLAN.md` do projeto (não releia relatórios).
2. **Determine o papel pelo baton `🎬 Próximo` do cabeçalho Agora — NÃO pergunte se o baton existe.**
   - **`🎬 Próximo: ⚙️ Executor`** (o `handoff` já deixou o bloco pronto) → esta é uma sessão de Executor.
     Em 2-3 linhas diga onde parou + o ponto de entrada, e **comece a executar** dali à risca, marcando
     checkboxes. **NÃO pare para perguntar "sou planejador ou executor?"** — o baton já respondeu.
   - **`🎬 Próximo: 🧠 Planejador`** → entre como Planejador (detalhar/replanejar/handoff do próximo bloco).
   - **Baton ausente/ambíguo** (só aí) → resuma o estado e pergunte o papel.
3. **Gates de sessão ≠ retrabalho.** Antes de executar, o Executor **reestabelece os gates por-sessão** do
   ponto de entrada — reverificar o **DoR** e **rearmar setup vivo** (carga/probe/shells, processos que
   NÃO sobrevivem entre sessões). Isso é **pré-condição normal, não estado perdido**: os *resultados* já
   feitos estão persistidos (checkbox `[x]` + relatório); só o setup vivo precisa subir de novo. Deixe isso
   explícito ao usuário para não parecer que se está "refazendo" trabalho.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifique se o bloco ativo está **"executor-ready"** (DoD do planejamento): tarefas atômicas com
   checagem verificável; decisões resolvidas; comandos/paths/valores preenchidos; DoR satisfeito;
   escalonamento definido.
2. Ajuste o que faltar no `PLAN.md` e confirme que um executor consegue tocar à risca.
3. **Grave o baton no cabeçalho "🔎 Agora":** `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <tarefa>`
   (a 1ª tarefa não-concluída), listando quais **gates por-sessão** reestabelecer antes (DoR + setup vivo).
   É esse baton que faz o `start` da próxima sessão entrar como Executor **sem perguntar**.
4. **Commit obrigatório** das edições do handoff (mesma regra do `end` — não deixe o PLAN pronto porém
   não-commitado, senão a próxima sessão lê estado do working tree). Reporte o hash.

### `end` — fim de sessão (só quando o usuário pedir)
1. Gere `RELATORIO_<bloco>_<AAAA-MM-DD>.md` na pasta de relatórios, pelo template (detalhe denso:
   comandos, saídas, números).
2. Atualize o `PLAN.md` **in-place** (nunca duplique linhas): cabeçalho "Agora"; Board; checkboxes do
   bloco ativo; se o bloco fechou, **promova o próximo de rascunho a detalhado e replaneje o resto**;
   registro de sessões (1 linha + link).
3. **Grave/atualize o baton `🎬 Próximo`** no cabeçalho Agora com o papel da próxima sessão + ponto de
   entrada: `⚙️ Executor` se o bloco segue executor-ready; `🧠 Planejador` se a fronteira exige
   (re)planejamento (bloco fechou e o próximo está em rascunho, ou surgiu decisão de design em aberto).
4. Atualize ponteiros de memória só se algo de alto nível mudou.
5. **Commit obrigatório do que foi feito** (sobrepõe qualquer hábito de "sem commit"): commite o
   relatório novo, o `PLAN.md` e as demais mudanças da sessão, seguindo as convenções de commit do
   repo (mensagem no padrão do projeto). Se a sessão tocou **mais de um repo** (ex.: repos irmãos
   operator/clusters), commite em **cada** um. Se estiver na branch default, crie/*use* a branch de
   trabalho do projeto antes. Faça `push` só se o usuário pedir ou se for a prática já estabelecida do
   projeto. Ao fim, reporte o(s) hash(es) de commit.

## Regras invioláveis (valem em qualquer subcomando)

- **Anti-duplicação:** estado/plano → `PLAN.md`; detalhe denso → relatórios; ganchos → memória. Nunca
  suba detalhe de relatório para o PLAN.
- **Rolling-wave:** detalhe só o bloco ativo (+ próximo). Replanejar na fronteira do bloco é ritual.
- **Papéis:** Planejador (modelo forte) deixa o bloco executor-ready e NÃO implementa, especificando
  decisões e restrições — não keystrokes. Executor (modelo barato) executa à risca, e ao divergir do
  plano PARA e escala de volta — não improvisa decisão de design. Auto-verifica contra a DoD.
- **Fronteira de papel = PARADA de sessão (NÃO auto-promoção):** o Executor **nunca vira Planejador
  dentro da mesma sessão**. Quando o baton viraria `🧠 Planejador` — o bloco ativo **fecha** e o próximo
  está em rascunho / é 🔬 descoberta, OU surge no meio da execução **qualquer coisa que dê vontade de
  (re)planejar** (decisão de design, ambiguidade, estado inesperado, DoD inalcançável) — o Executor
  **PARA explicitamente, grava o baton `🎬 Próximo: 🧠 Planejador` + o motivo, e reporta ao usuário**.
  Ele **não** detalha o próximo bloco, **não** escreve contrato novo e **não** executa uma 1ª passada de
  descoberta. Planejar é do modelo forte, em sessão separada. Detalhar+executar um bloco de uma vez, na
  mesma sessão de Executor, **é violação de protocolo** — mesmo que "pareça pronto para seguir".
- **Estimativas são guia de fatiamento, não SLA.** Gere RELATÓRIO só quando o usuário pedir.
- **Baton de papel (`🎬 Próximo`):** o cabeçalho "Agora" carrega SEMPRE uma linha
  `🎬 Próximo: <⚙️ Executor|🧠 Planejador> · Ponto de entrada: <tarefa>`. É a fonte de verdade do papel
  da próxima sessão — `handoff`/`end` a gravam, `start` a lê e age sem perguntar. Sem baton, o `start`
  fica adivinhando o papel (bug): mantenha-a sempre atual.
- **Gate por-sessão × marco (não confundir):** um **marco** é um resultado que persiste (medição/entrega →
  checkbox `[x]` + relatório). Um **gate por-sessão** é pré-condição/processo vivo que **não** sobrevive
  entre sessões (DoR = "está saudável agora?"; armar carga/probe/shells) e **é reestabelecido toda sessão
  de execução** — isso NÃO é retrabalho nem estado perdido. No PLAN, marque gates com **🔁** (ex.:
  `🔁 T0 — DoR`, `🔁 T1 — armar carga+probe`) em vez de checkbox de marco, para o Executor saber que os
  refaz sempre e ninguém achar que "perdeu" resultado.

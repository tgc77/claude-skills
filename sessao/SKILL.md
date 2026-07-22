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

### `help` — mostrar o guia de uso da skill
Leia `HELP.md` (ao lado deste arquivo) e apresente o guia (subcomandos, papéis, conceitos-chave, ciclo
de vida). Não altera nada no projeto. Use também quando o usuário pedir "help"/"ajuda"/"como uso o sessao".

### `init` — instalar o sistema num projeto novo
1. Leia `templates/AGENTS.template.md` e `templates/PLAN.template.md`.
2. Levante os `<PLACEHOLDERS>` com o usuário (não invente): nome do projeto; escopo; lista inicial de
   blocos (id + título + tipo 🔧 mecânico / 🔬 descoberta); como tratá-lo; ambiente/guardrails;
   política de commit; idioma; pasta de relatórios; **label de apontamento** (card do GitLab p/ o
   `resumo-trabalho`, se houver — é o identificador que liga o `end` deste projeto ao apontamento do
   card; opcional, pode ficar em branco).
3. Crie no projeto: `AGENTS.md` (ou `CLAUDE.md` se já existir) e `PLAN.md` (raiz ou subpasta do
   escopo), preenchidos. Detalhe **só o bloco B1**; deixe os demais em uma linha, marcados `(rascunho)`.
   Grave o label de apontamento (se houver) na linha "Card / label de apontamento" das Convenções do
   `AGENTS.md`. Copie `templates/template-relatorio.md` para a pasta de relatórios.
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

### `end` — fim de sessão
Duas portas de entrada para este ritual:
- **Fim de sessão no meio de um bloco** (bloco ainda aberto) → **só quando o usuário pedir** (gerar
  relatório é ato explícito; não assuma que a sessão encerrou).
- **Fechamento de bloco inteiro** (toda a DoD do bloco satisfeita) → o **Executor auto-dispara este
  ritual por si, sem o usuário pedir**, *antes* de passar o baton (ver "Papéis" nas Regras invioláveis).

1. Gere `RELATORIO_<bloco>_<AAAA-MM-DD>.md` na pasta de relatórios, pelo template (detalhe denso:
   comandos, saídas, números).
2. Atualize o `PLAN.md` **in-place** (nunca duplique linhas): cabeçalho "Agora"; Board; checkboxes do
   bloco ativo; se o bloco fechou, **promova o próximo de rascunho a detalhado e replaneje o resto**;
   registro de sessões (1 linha + link).
3. **Grave/atualize o baton `🎬 Próximo`** no cabeçalho Agora com o papel da próxima sessão + ponto de
   entrada: `⚙️ Executor` se o bloco segue executor-ready; `🧠 Planejador` se a fronteira exige
   (re)planejamento (bloco fechou e o próximo está em rascunho, ou surgiu decisão de design em aberto).
4. Atualize ponteiros de memória só se algo de alto nível mudou.
5. **Registre o apontamento do dia no `resumo-trabalho` (se o projeto tiver label).** É o elo que mantém
   os apontamentos do card sincronizados sem depender de `registrar` manual — o `gerar <card>` do dia
   sai completo porque todo relatório do dia vira entrada no log automaticamente:
   - Leia o **label de apontamento** do projeto (linha "Card / label de apontamento" nas Convenções do
     `AGENTS.md`). Sem label configurado → **pule este passo** (projeto sem card associado).
   - Colete os relatórios do **dia de hoje** na pasta de relatórios (`RELATORIO_*_<AAAA-MM-DD>.md` com a
     data de hoje — inclui o que você acabou de gerar **e** quaisquer outros blocos fechados hoje em
     sessões anteriores que ainda não foram registrados).
   - Para cada relatório, cheque idempotência: procure o basename do relatório
     (`RELATORIO_<bloco>_<data>.md`) no `~/.claude/work-log/<label-slug>.md`. **Se já aparece, pule** (já
     registrado). Senão, sintetize uma entrada `registrar` densa e factual a partir do relatório
     (formato e regras do `resumo-trabalho`: seções O que foi feito / Problemas-Correções / Validações /
     Pendências, denso e factual, sem inventar nada fora do relatório) e faça **append** no log do label.
     Logo abaixo do cabeçalho `## [data hora] <projeto>`, inclua a linha
     `**Relatório-fonte:** <caminho/RELATORIO_<bloco>_<data>.md>` — é ela que torna o passo idempotente.
     Uma entrada por relatório.
   - Log é **append-only e global** (`~/.claude/work-log/`), fora do repo — **não** entra no commit do
     passo 6. Confirme em 1 linha quais relatórios viraram entrada (ou "nada novo a registrar").
6. **Commit obrigatório do que foi feito** (sobrepõe qualquer hábito de "sem commit"): commite o
   relatório novo, o `PLAN.md` e as demais mudanças da sessão, seguindo as convenções de commit do
   repo (mensagem no padrão do projeto). Se a sessão tocou **mais de um repo** (ex.: repos irmãos
   operator/clusters), commite em **cada** um. Se estiver na branch default, crie/*use* a branch de
   trabalho do projeto antes. **Exceção que sobrepõe o "sem push": commit destinado a deploy leva
   `push` no mesmo turno, sem esperar pedido** (ver "Entrega destinada a deploy" nas Regras
   invioláveis). Fora desse caso, faça `push` só se o usuário pedir ou se for a prática já estabelecida
   do projeto. Ao fim, reporte o(s) hash(es) de commit.

## Regras invioláveis (valem em qualquer subcomando)

- **Entrega destinada a deploy = `push` no mesmo turno, e o pipeline tem mais elos que o commit.**
  Quando o commit existe **para ser deployado**, deixá-lo só local é entrega incompleta: quem builda
  (Jenkins/CI) lê do **remoto**, então um commit não-pushado vira um deploy que "não mudou nada", sem
  erro nenhum — o modo de falha mais caro e mais confuso, porque parece problema de deploy e é falha de
  autoria. **Por isso: commitou para deploy → pushou, sem esperar o usuário pedir.** Isto sobrepõe o
  "sem `push` sem pedir" do `end`/`handoff`; para todo o resto, a regra normal continua valendo.
  **E o push não é o último elo.** Antes de anunciar "versão X pronta para deployar", confira a cadeia
  inteira, porque *qualquer* elo faltando produz o **mesmo sintoma silencioso** (deploy roda, nada muda):
  1. **Versão bumpada** onde o projeto exige (ex.: `Chart.yaml` **e** `VERSION` juntos) — sem bump, o
     deploy não rola release nova.
  2. **Commit + push** — o CI builda do remoto, não do working tree.
  3. **Job de build/publicação** rodado *depois* do push — é ele que empacota e publica o artefato
     (`.tgz`, imagem) no repositório. Pular este elo faz o job de deploy reusar o **artefato anterior**,
     que continua lá.
  4. **Job de deploy selecionando a versão nova** — se o deploy escolhe versão de uma lista, escolher a
     antiga é no-op.
  Ao delegar a um humano, **peça os jobs explicitamente e por nome** ("rode o build e depois o deploy
  selecionando a versão X"); dizer só "deploya a versão X" já custou ciclos. **Diagnóstico barato (5 s)
  quando o deploy "não pegou":** leia o estado **vivo** do objeto (ex.: `kubectl get deploy <x> -o
  jsonpath='{.spec.template.spec.containers[0].args}'`) + a idade do pod — se os args são os antigos e o
  pod não foi recriado, o artefato nunca mudou, e aí a pergunta é *qual elo faltou*, não "o deploy
  falhou". **Não presuma qual elo foi:** verifique (o remoto tem o commit? o artefato novo existe?)
  antes de apontar a causa.
- **Anti-duplicação:** estado/plano → `PLAN.md`; detalhe denso → relatórios; ganchos → memória. Nunca
  suba detalhe de relatório para o PLAN.
- **Rolling-wave:** detalhe só o bloco ativo (+ próximo). Replanejar na fronteira do bloco é ritual.
- **Papéis:** Planejador (modelo forte) deixa o bloco executor-ready e NÃO implementa, especificando
  decisões e restrições — não keystrokes. Executor (modelo barato) executa à risca, e ao divergir do
  plano PARA e escala de volta — não improvisa decisão de design. Auto-verifica contra a DoD.
- **Executor fecha o próprio bloco (auto-`end` na fronteira):** ao concluir um **bloco inteiro** (toda a
  DoD satisfeita), o Executor **dispara o ritual `end` por si — commit + relatório + atualização in-place
  do PLAN — sem o usuário pedir**, e só então grava o baton `🎬 Próximo`. É o mesmo `end`, auto-disparado
  no fechamento de bloco. **Não** vale para terminar só alguns steps no meio de um bloco (bloco ainda
  aberto) — aí não há relatório nem fechamento, só atualização de checkboxes/estado, e o `end` continua
  sendo ato explícito do usuário. Isto **não** contradiz a "Fronteira de papel = PARADA": o Executor
  fecha o bloco terminado (relatório+commit) e PARA; **não** planeja o próximo.
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
- **Sincronia com `resumo-trabalho` (label = identificador do projeto):** se o projeto tem um **label de
  apontamento** no `AGENTS.md`, o `end` alimenta o `resumo-trabalho` a partir dos **relatórios do dia**
  (uma entrada `registrar` por relatório novo, marcada com `**Relatório-fonte:**` p/ idempotência). Assim
  o `gerar <card>` do dia sempre reflete tudo que fechou — sem depender de `registrar` manual. Os
  relatórios são a matéria-prima; nada é inventado fora deles. O log continua append-only e global.
- **Gate por-sessão × marco (não confundir):** um **marco** é um resultado que persiste (medição/entrega →
  checkbox `[x]` + relatório). Um **gate por-sessão** é pré-condição/processo vivo que **não** sobrevive
  entre sessões (DoR = "está saudável agora?"; armar carga/probe/shells) e **é reestabelecido toda sessão
  de execução** — isso NÃO é retrabalho nem estado perdido. No PLAN, marque gates com **🔁** (ex.:
  `🔁 T0 — DoR`, `🔁 T1 — armar carga+probe`) em vez de checkbox de marco, para o Executor saber que os
  refaz sempre e ninguém achar que "perdeu" resultado.

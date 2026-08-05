---
name: sessao
description: >-
  Monta e opera o sistema de Controle de Sessões (v2) para projetos de escopo definido — protocolo
  permanente no AGENTS.md + um PLAN.md por escopo (docs/sessoes/<escopo>/) + protocolo
  planner/executor + rolling-wave. Use quando o usuário quiser inicializar o controle de sessões num
  repo, abrir um escopo novo de trabalho (feature, correção, investigação), criar/montar um PLAN.md,
  ou rodar o ritual de início, handoff (troca de modelo planejador→executor) ou fim de sessão.
  Gatilhos: "controle de sessões", "montar o PLAN", "novo escopo/plano", "bootstrap do playbook de
  sessões", "/sessao", "iniciar/encerrar sessão do projeto".
---

# Skill: sessao — Controle de Sessões (v2)

Sistema para tocar um projeto de escopo definido com agentes de I.A. mantendo cada sessão enxuta de
contexto e zero perda de continuidade. **Princípio único:** cada fato mora em UM arquivo; o resto
aponta (link), nunca copia. O plano se detalha em rolling-wave (perto detalhado, longe em rascunho).

Os templates ficam em `templates/` ao lado deste arquivo. O panorama completo do modelo está em
`templates/README.md` — leia-o se precisar de contexto antes de agir.

## 🗂️ Layout canônico (um repo, vários escopos)

Um repositório vive mais que um escopo: hoje é uma feature, amanhã uma correção, depois uma
investigação. **O protocolo é permanente; o plano é por escopo.** Por isso a raiz **nunca** cresce a
cada frente nova:

```
<repo>/
├── CLAUDE.md                      ← índice auto-carregado: aponta o AGENTS.md + lista os escopos
├── AGENTS.md                      ← PROTOCOLO permanente, agnóstico de escopo (papéis, ritual,
│                                    convenções de commit, guardrails permanentes)
└── docs/sessoes/
    ├── template-relatorio.md      ← gabarito compartilhado (um por repo, nunca copiado por escopo)
    └── <escopo-slug>/             ← UM ESCOPO = UMA PASTA
        ├── PLAN.md                ← fonte única de verdade DAQUELE escopo
        └── RELATORIO_<bloco>_<AAAA-MM-DD>.md
```

**Divisão de conteúdo (não misture — é o que evita a bagunça):**

| Vai no `AGENTS.md` (permanente) | Vai no `PLAN.md` do escopo (efêmero) |
|---|---|
| Papéis 🧠/⚙️, DoD de planejamento, ritual de fim de turno | Escopo, objetivo, Board, blocos, contrato de execução |
| Convenções de commit, idioma, tratamento do usuário | **Branch de trabalho** daquele escopo |
| Repos irmãos que uma sessão pode tocar | **Ambiente/`KUBECONFIG`/namespaces** daquele escopo |
| Guardrails **permanentes** (segredos, prod, destrutivo) | Guardrails **específicos** daquele escopo |
| — | **Label de apontamento** (card) daquele escopo |

**`CLAUDE.md` × `AGENTS.md` (por que os dois):** o Claude Code carrega automaticamente o `CLAUDE.md`;
`AGENTS.md` é a convenção neutra de fornecedor, e não é auto-carregado por estar numa subpasta. Então
`CLAUDE.md` fica curto — ponteiro para o protocolo + **índice de escopos** (tabela com estado e link
do PLAN) — e o conteúdo mora no `AGENTS.md`. **Nunca duplique o protocolo nos dois.**

**Layout legado (compatibilidade):** projetos instalados antes deste modelo têm `PLAN.md` na raiz e o
protocolo dentro do próprio `AGENTS.md`/`CLAUDE.md`. **Continue operando neles como estão** — `start`,
`handoff` e `end` funcionam igual. Só migre para o layout canônico se o usuário pedir, ou ofereça a
migração quando ele for abrir um **segundo escopo** no mesmo repo (é aí que o layout antigo quebra).

## Subcomando (deduza do argumento ou pergunte)

O argumento após `/sessao` indica a operação. Sem argumento, pergunte qual é.

### `help` — mostrar o guia de uso da skill
Leia `HELP.md` (ao lado deste arquivo) e apresente o guia (subcomandos, papéis, conceitos-chave, ciclo
de vida). Não altera nada no projeto. Use também quando o usuário pedir "help"/"ajuda"/"como uso o sessao".

### `init` — abrir um escopo (instalando o sistema, se ainda não houver)

**0. Detecte o estado do repo ANTES de qualquer coisa** — `init` **nunca** sobrescreve instalação
existente:
- **Repo virgem** (sem `AGENTS.md`/`CLAUDE.md` de controle e sem `docs/sessoes/`) → instalação completa
  (passos 1–5).
- **Repo já instalado** (existe o protocolo + `docs/sessoes/`) → é **escopo novo**: crie **apenas**
  `docs/sessoes/<novo-slug>/PLAN.md` e acrescente a linha do escopo na tabela do `CLAUDE.md`.
  **Não recrie nem reescreva** `AGENTS.md`, `CLAUDE.md` (fora a linha nova) ou o template de relatório.
- **Layout legado** (PLAN na raiz) → diga isso ao usuário e ofereça migrar para o layout canônico antes
  de abrir o escopo novo; se ele recusar, **não** invente um segundo PLAN na raiz.

1. Leia `templates/AGENTS.template.md`, `templates/CLAUDE.template.md` e `templates/PLAN.template.md`
   (só os que forem necessários ao caso detectado).
2. Levante os `<PLACEHOLDERS>` com o usuário (**não invente**):
   - **Sempre (por escopo):** título do escopo + **slug da pasta**; o que é o escopo e o que fica **fora**
     dele; lista inicial de blocos (id + título + tipo 🔧 mecânico / 🔬 descoberta); **branch de
     trabalho**; **ambiente** (cluster/`KUBECONFIG`/namespaces/dados) e **guardrails específicos**;
     **label de apontamento** (card do GitLab p/ o `resumo-trabalho` — é o que liga o `end` deste escopo
     ao apontamento do card; opcional, pode ficar em branco).
   - **Só na 1ª instalação (por repo):** como tratar o usuário; idioma; política de commit; repos irmãos
     que uma sessão pode tocar; guardrails permanentes.
   - **Não pergunte a pasta de relatórios** — ela é derivada (`docs/sessoes/<escopo-slug>/`).
3. **Confirme o plano da estrutura ANTES de criar** (árvore + Board + guardrails, em texto). Só crie
   depois do OK.
4. Crie os arquivos:
   - `AGENTS.md` (protocolo permanente) e `CLAUDE.md` (índice) — **só na 1ª instalação**.
   - `docs/sessoes/template-relatorio.md` — **só na 1ª instalação** (copie de `templates/`).
   - `docs/sessoes/<escopo-slug>/PLAN.md` — sempre. Detalhe **só o bloco B1**; deixe os demais em uma
     linha, marcados `(rascunho)`. Preencha o cabeçalho de parâmetros do escopo (branch, ambiente,
     namespaces, **label de apontamento**, pasta de relatórios) e a seção "🚧 Guardrails deste escopo".
   - Acrescente a linha do escopo na tabela de escopos do `CLAUDE.md` (estado 🟡 Ativo).
5. **Grave o baton `🎬 Próximo`** no cabeçalho "🔎 Agora" do PLAN novo — o `init` **não** pode deixar o
   baton em branco (sem ele o `start` fica adivinhando o papel). Regra: **B1 🔬 descoberta ou ainda não
   executor-ready → `🧠 Planejador`**; B1 🔧 mecânico e já executor-ready → `⚙️ Executor`.
6. **Commite a instalação** (mesma razão do `handoff`: PLAN não-commitado faz a próxima sessão ler
   estado do working tree). Se estiver na branch default, use a branch de trabalho declarada no PLAN.
   Reporte o hash e mostre a árvore criada.

### `start [<texto livre>]` — início de sessão
0. **Nota de sessão (texto após `start`) — processe ANTES de qualquer execução.** Se houver qualquer
   coisa escrita depois de `start`, ela é uma **nota de sessão**: contexto e/ou diretivas que
   **precedem e condicionam** o baton. Leia o "🔎 Agora" + bloco ativo (passo 1) e **classifique a nota
   antes de tocar em qualquer tarefa** — não comece a executar e só depois "encaixar" a nota.
   - **(A) Briefing — só carregar contexto.** Sinais: "só carregar/entender o contexto", "onde
     paramos", "não execute (ainda)", "me explique", "resumo do estado", "quero saber o plano".
     → Apresente um briefing estruturado e **PARE**, aguardando ordem explícita: onde parou · ponto de
     entrada do baton · gates 🔁 pendentes · decisões em aberto · **qual seria a próxima ação** se
     mandasse executar. **Nada de efeito colateral**: não marque checkbox, não rode comando, não edite
     arquivo e **não rearme setup vivo** (passo 3 não roda em briefing — armar carga/probe é execução).
   - **(B) Diretivas de execução.** Restrições/ajustes operacionais ("só a tarefa T3", "pule o passo X",
     "use o cluster Y", "sem commit hoje", "seja verboso nos números"). → Antes de agir, **ecoe em 1-3
     linhas** as diretivas entendidas e **como cada uma altera o ponto de entrada / os gates**; então
     execute já sob elas. Diretiva do usuário **vence** o PLAN no que for operacional.
   - **(C) Misto** (contexto + diretiva) → é o caso comum: dê o briefing de (A) e **só execute se a nota
     contiver ordem explícita de executar**; na dúvida, briefing + pergunta de 1 linha.
   - **Conflito com o contrato do bloco = PARADA, não improviso.** Se a diretiva muda **DoD, ordem de
     blocos, escopo do contrato, ou pede pular um gate 🔁**, isso é (re)planejamento: não aplique por
     conta própria — exponha o conflito (o que o PLAN diz × o que a nota pede), ofereça as opções e peça
     a decisão. Vale a "Fronteira de papel = PARADA".
   - **Diretivas são efêmeras.** Valem para esta sessão e **não** entram no `PLAN.md`. Só viram edição
     de PLAN/AGENTS (no `end`, ou por sessão de Planejador) se o usuário disser que é permanente ou se
     alterarem o contrato.
   Sem texto após `start` → siga direto do passo 1, comportamento normal do baton.
1. **Identifique o escopo e leia só o PLAN dele.** Um repo pode ter vários escopos: consulte a tabela de
   escopos do `CLAUDE.md` e escolha o **ativo** (ou o que a nota de sessão/o pedido indicar). **Se houver
   mais de um ativo e a intenção for ambígua, PERGUNTE qual** — nunca chute o escopo, e nunca leia o PLAN
   de outro. Então leia só o cabeçalho "🔎 Agora" + o bloco ativo daquele `PLAN.md` (não releia
   relatórios). Layout legado → o PLAN é o da raiz.
2. **Determine o papel pelo baton `🎬 Próximo` do cabeçalho Agora — NÃO pergunte se o baton existe.**
   (O baton define o **papel**; a nota de sessão do passo 0 define **se e como** se executa agora — em
   modo briefing o papel continua sendo o do baton, mas a sessão para no briefing.)
   - **`🎬 Próximo: ⚙️ Executor`** (o `handoff` já deixou o bloco pronto) → esta é uma sessão de Executor.
     Em 2-3 linhas diga onde parou + o ponto de entrada, e **comece a executar** dali à risca, marcando
     checkboxes. **NÃO pare para perguntar "sou planejador ou executor?"** — o baton já respondeu.
   - **`🎬 Próximo: 🧠 Planejador`** → entre como Planejador (detalhar/replanejar/handoff do próximo bloco).
   - **Baton ausente/ambíguo** (só aí) → resuma o estado e pergunte o papel.
3. **Gates de sessão ≠ retrabalho** (só quando se vai executar — em briefing, pule). Antes de executar, o Executor **reestabelece os gates por-sessão** do
   ponto de entrada — reverificar o **DoR** e **rearmar setup vivo** (carga/probe/shells, `export
   KUBECONFIG`, processos que NÃO sobrevivem entre sessões). Isso é **pré-condição normal, não estado
   perdido**: os *resultados* já feitos estão persistidos (checkbox `[x]` + relatório); só o setup vivo
   precisa subir de novo. Deixe isso explícito ao usuário para não parecer que se está "refazendo" trabalho.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifique se o bloco ativo está **"executor-ready"** (DoD do planejamento): tarefas atômicas com
   checagem verificável; decisões resolvidas; comandos/paths/valores preenchidos; DoR satisfeito;
   escalonamento definido.
2. Ajuste o que faltar no `PLAN.md` **do escopo** e confirme que um executor consegue tocar à risca.
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

1. Gere `docs/sessoes/<escopo>/RELATORIO_<bloco>_<AAAA-MM-DD>.md` — na **pasta do escopo**, pelo template
   compartilhado `docs/sessoes/template-relatorio.md` (detalhe denso: comandos, saídas, números).
2. Atualize o `PLAN.md` **do escopo**, **in-place** (nunca duplique linhas): cabeçalho "Agora"; Board;
   checkboxes do bloco ativo; registro de sessões (1 linha + link).
   **Se o bloco fechou, o que fazer depende de quem está na sessão:**
   - **🧠 Planejador** → promova o próximo bloco de rascunho a detalhado e replaneje o resto (é o ritual
     de fronteira dele).
   - **⚙️ Executor** → marque o bloco como 🟢 Concluído, grave o baton `🎬 Próximo: 🧠 Planejador` com o
     motivo, e **PARE**. Ele **não** promove, **não** detalha e **não** replaneja (Fronteira de papel).
3. **Grave/atualize o baton `🎬 Próximo`** no cabeçalho Agora com o papel da próxima sessão + ponto de
   entrada: `⚙️ Executor` se o bloco segue executor-ready; `🧠 Planejador` se a fronteira exige
   (re)planejamento (bloco fechou e o próximo está em rascunho, ou surgiu decisão de design em aberto).
4. Se o **escopo inteiro** fechou, marque-o 🟢 Concluído na tabela de escopos do `CLAUDE.md` (a pasta
   fica, é histórico). Atualize ponteiros de memória só se algo de alto nível mudou.
5. **Registre o apontamento do dia no `resumo-trabalho` (se o escopo tiver label).** É o elo que mantém
   os apontamentos do card sincronizados sem depender de `registrar` manual — o `gerar <card>` do dia
   sai completo porque todo relatório do dia vira entrada no log automaticamente:
   - Leia o **label de apontamento** no cabeçalho de parâmetros do `PLAN.md` do escopo (em instalações
     legadas, na linha "Card / label de apontamento" das Convenções do `AGENTS.md`). Sem label
     configurado → **pule este passo** (escopo sem card associado).
   - Colete os relatórios do **dia de hoje** na pasta do escopo (`RELATORIO_*_<AAAA-MM-DD>.md` com a
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
   operator/clusters), commite em **cada** um. Se estiver na branch default, crie/*use* a **branch de
   trabalho declarada no PLAN do escopo**. **Exceção que sobrepõe o "sem push": commit destinado a
   deploy leva `push` no mesmo turno, sem esperar pedido** (ver "Entrega destinada a deploy" nas Regras
   invioláveis). Fora desse caso, faça `push` só se o usuário pedir ou se for a prática já estabelecida
   do projeto. Ao fim, reporte o(s) hash(es) de commit.

## Regras invioláveis (valem em qualquer subcomando)

- **Um escopo = uma pasta; o protocolo é um só.** Frente de trabalho nova = `docs/sessoes/<slug>/PLAN.md`
  novo, **nunca** um segundo protocolo. `AGENTS.md` e `template-relatorio.md` são **reusados, jamais
  copiados por escopo**; o `CLAUDE.md` é só índice. Nada específico de escopo (branch, ambiente,
  `KUBECONFIG`, label do card, guardrails da frente) entra no `AGENTS.md` — isso mora no PLAN do escopo,
  senão o próximo escopo herda restrição que não é dele. E `init` **nunca sobrescreve** instalação
  existente (ver passo 0 do `init`).
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
- **Anti-duplicação:** regras de trabalho → `AGENTS.md`; estado/plano → `PLAN.md` do escopo; detalhe
  denso → relatórios do escopo; ganchos → memória. Nunca suba detalhe de relatório para o PLAN.
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
  fecha o bloco terminado (relatório+commit) e PARA; **não** planeja o próximo — nem promovendo o
  próximo bloco de rascunho a detalhado (ver `end`, passo 2).
- **Fronteira de papel = PARADA de sessão (NÃO auto-promoção):** o Executor **nunca vira Planejador
  dentro da mesma sessão**. Quando o baton viraria `🧠 Planejador` — o bloco ativo **fecha** e o próximo
  está em rascunho / é 🔬 descoberta, OU surge no meio da execução **qualquer coisa que dê vontade de
  (re)planejar** (decisão de design, ambiguidade, estado inesperado, DoD inalcançável) — o Executor
  **PARA explicitamente, grava o baton `🎬 Próximo: 🧠 Planejador` + o motivo, e reporta ao usuário**.
  Ele **não** detalha o próximo bloco, **não** escreve contrato novo e **não** executa uma 1ª passada de
  descoberta. Planejar é do modelo forte, em sessão separada. Detalhar+executar um bloco de uma vez, na
  mesma sessão de Executor, **é violação de protocolo** — mesmo que "pareça pronto para seguir".
- **Estimativas são guia de fatiamento, não SLA.**
- **RELATÓRIO é ato explícito — com uma exceção só:** gere relatório quando o usuário pedir **ou** no
  auto-`end` de **fechamento de bloco** (toda a DoD satisfeita). Terminar alguns steps no meio de um
  bloco **não** gera relatório: aí só atualize checkboxes e estado no PLAN.
- **Baton de papel (`🎬 Próximo`):** o cabeçalho "Agora" carrega SEMPRE uma linha
  `🎬 Próximo: <⚙️ Executor|🧠 Planejador> · Ponto de entrada: <tarefa>`. É a fonte de verdade do papel
  da próxima sessão — `init`/`handoff`/`end` a gravam, `start` a lê e age sem perguntar. Sem baton, o
  `start` fica adivinhando o papel (bug): mantenha-a sempre atual.
- **Nota de sessão precede o baton (mas não o substitui):** texto livre depois de `/sessao start` é
  processado **antes** de qualquer tarefa. Ele pode **suspender a execução** (briefing: carregar o
  contexto do ponto onde parou, sem ler tudo, e parar) e pode **condicionar** a execução (diretivas
  operacionais), mas **não redefine o papel** — quem define papel é o baton — nem altera o contrato do
  bloco por conta própria (isso é PARADA + decisão do usuário). Diretivas valem só para a sessão.
- **Sincronia com `resumo-trabalho` (label = identificador do escopo):** se o escopo declara um **label de
  apontamento** no cabeçalho do seu `PLAN.md`, o `end` alimenta o `resumo-trabalho` a partir dos
  **relatórios do dia** (uma entrada `registrar` por relatório novo, marcada com `**Relatório-fonte:**`
  p/ idempotência). Assim o `gerar <card>` do dia sempre reflete tudo que fechou — sem depender de
  `registrar` manual. Escopos diferentes podem apontar para cards diferentes no mesmo repo. Os
  relatórios são a matéria-prima; nada é inventado fora deles. O log continua append-only e global.
- **Gate por-sessão × marco (não confundir):** um **marco** é um resultado que persiste (medição/entrega →
  checkbox `[x]` + relatório). Um **gate por-sessão** é pré-condição/processo vivo que **não** sobrevive
  entre sessões (DoR = "está saudável agora?"; armar carga/probe/shells) e **é reestabelecido toda sessão
  de execução** — isso NÃO é retrabalho nem estado perdido. No PLAN, marque gates com **🔁** (ex.:
  `🔁 T0 — DoR`, `🔁 T1 — armar carga+probe`) em vez de checkbox de marco, para o Executor saber que os
  refaz sempre e ninguém achar que "perdeu" resultado.

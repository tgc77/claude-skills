---
name: sessao
description: >-
  Monta e opera o sistema de Controle de Sessões (v2) para projetos de escopo definido — protocolo
  permanente no AGENTS.md + um PLAN.md por escopo (docs/sessoes/SLUG/) + protocolo
  planner/executor + rolling-wave. Skill de invocação exclusivamente explícita: use somente quando
  Tiago escrever $sessao, @sessao ou /sessao. Nunca a acione por contexto do repositório ou por um
  pedido técnico comum. Para assumir e operar um escopo existente, exija `sessao start SLUG`
  explicitamente; os demais subcomandos executam somente sua própria função.
---

# Skill: sessao — Controle de Sessões (v2)

Sistema para tocar um projeto de escopo definido com agentes de I.A. mantendo cada sessão enxuta de
contexto e zero perda de continuidade. **Princípio único:** cada fato mora em UM arquivo; o resto
aponta (link), nunca copia. O plano se detalha em rolling-wave (perto detalhado, longe em rascunho).

> ⛔ **Ativação exclusivamente explícita.** A existência de `AGENTS.md`, `CLAUDE.md`, um único escopo
> ativo, uma branch correspondente ou um pedido técnico dentro de um repositório com controle de
> sessões **não ativa esta skill**. Só assuma e opere um escopo existente quando Tiago invocar
> explicitamente `sessao start SLUG`. Outros subcomandos explícitos fazem somente o que pedem e não
> autorizam um `start` implícito.
>
> 🔒 **Esta regra não vive só nesta prosa** — [`agents/openai.yaml`](agents/openai.yaml) a declara em
> configuração (`policy.allow_implicit_invocation: false`), para o lado que lê política em vez de
> aviso. Se você mover, clonar ou empacotar a skill, **leve o arquivo junto**: sem ele sobra o texto
> acima, e texto sozinho não impede invocação implícita — é o mesmo padrão de regra escrita sem
> mecanismo que já produziu falha silenciosa neste protocolo (ver a 3ª porta do `end`).

> 🔤 **Invocação, em qualquer ferramenta.** Neste documento os subcomandos aparecem como
> `/sessao <sub>`, que é a forma do **Claude Code**. No **Codex** a mesma invocação é `$sessao <sub>`
> ou `@sessao <sub>`. Onde se lê `/sessao`,
> entenda "invoque esta skill" — o protocolo é idêntico nas duas.
>
> 📁 **Onde a skill é descoberta:** Claude Code em `~/.claude/skills/`; Codex em `~/.codex/skills/`
> (default do `CODEX_HOME`) e em `.agents/skills/` (convenção mais nova, também reconhecida). Um
> symlink por caminho resolve, sem cópia — **a skill mora num lugar só**.

Os templates ficam em `templates/` ao lado deste arquivo. O panorama completo do modelo está em
`templates/README.md` — leia-o se precisar de contexto antes de agir.

## 🗂️ Layout canônico (um repo, vários escopos)

Um repositório vive mais que um escopo: hoje é uma feature, amanhã uma correção, depois uma
investigação. **O protocolo é permanente; o plano é por escopo.** Por isso a raiz **nunca** cresce a
cada frente nova:

```
<repo>/
├── CLAUDE.md                      ← 1 linha: `@AGENTS.md` (o Claude Code não lê AGENTS.md)
├── AGENTS.md                      ← FONTE ÚNICA: protocolo permanente + ÍNDICE DE ESCOPOS
│                                    (lido nativamente pelo Codex; pelo Claude via @import)
├── scripts/
│   └── conferencia_saida.sh       ← LANÇADOR do portão (instalado pelo `init`): resolve a skill
│                                    e a executa. O portão DE VERDADE mora só na skill, junto do
│                                    autoteste — projeto guarda o endereço, não a versão.
└── docs/sessoes/
    ├── template-relatorio.md      ← gabarito compartilhado (um por repo, nunca copiado por escopo)
    └── <escopo-slug>/             ← UM ESCOPO = UMA PASTA
        ├── PLAN.md                ← fonte única de verdade DAQUELE escopo
        └── RELATORIO_<bloco>_<AAAA-MM-DD>.md
```

**Divisão de conteúdo (não misture — é o que evita a bagunça):**

| Vai no `AGENTS.md` (permanente + índice) | Vai no `PLAN.md` do escopo (efêmero) |
|---|---|
| Papéis 🧠/⚙️, DoD de planejamento, ritual de fim de turno | Escopo, objetivo, Board, blocos, contrato de execução |
| **Índice de escopos** (tabela slug → PLAN, com estado) | **Slug + descrição** daquele escopo |
| Convenções de commit, idioma, tratamento do usuário | **Branch de trabalho** daquele escopo |
| Repos irmãos que uma sessão pode tocar | **Ambiente/`KUBECONFIG`/namespaces** daquele escopo |
| Guardrails **permanentes** (segredos, prod, destrutivo) | Guardrails **específicos** daquele escopo |
| — | **Slug + descrição** daquele escopo (o slug já é o label do apontamento) |

**`CLAUDE.md` × `AGENTS.md` (por que os dois, e por que o conteúdo fica todo num só):** as ferramentas
leem arquivos diferentes — o **Claude Code lê `CLAUDE.md` e não lê `AGENTS.md`**; o **Codex (e a
convenção `AGENTS.md` em geral) lê `AGENTS.md` e não lê `CLAUDE.md`**. Para os dois enxergarem a mesma
coisa sem cópia, **tudo mora no `AGENTS.md` — protocolo permanente E índice de escopos** — e o
`CLAUDE.md` é um arquivo de uma linha:

```markdown
@AGENTS.md

## Claude Code
<instruções específicas do Claude Code, se houver>
```

É o padrão que a própria documentação da Anthropic recomenda para repositório que já usa `AGENTS.md`.
**Nunca duplique conteúdo nos dois** — se o índice ficasse só no `CLAUDE.md`, o Codex não o enxergaria
sozinho, e é o índice que diz qual PLAN a sessão deve abrir.

> ⛔ **Não use `AGENTS.override.md`.** No Codex ele **substitui** o `AGENTS.md` do mesmo nível em vez
> de somar — a doc é explícita: *"uses only the first non-empty file at this level"*. Num repo com
> este protocolo isso apagaria papéis, ritual e guardrails do contexto de uma vez. E dar arquivos
> diferentes a ferramentas diferentes **fabrica** o problema que se queria evitar: dois agentes
> rodando protocolos divergentes sobre o mesmo `PLAN.md`. O override existe para override **temporário
> e global**, não para endereçar conteúdo permanente de projeto.
>
> **O conflito real entre ferramentas não é de arquivo, é de working tree.** `AGENTS.md` é leitura;
> dois agentes lendo o mesmo arquivo é o objetivo. O que colide é **duas sessões mexendo na mesma
> árvore ao mesmo tempo** — e a regra para isso já existe: um escopo por vez por working tree,
> paralelo de verdade só com `git worktree`. Vale igual entre Claude Code e Codex.

**Layout legado (compatibilidade):** projetos instalados antes deste modelo têm `PLAN.md` na raiz e o
protocolo dentro do próprio `AGENTS.md`/`CLAUDE.md`. **Continue operando neles como estão** — `start`,
`handoff` e `end` funcionam igual. Só migre para o layout canônico se o usuário pedir, ou ofereça a
migração quando ele for abrir um **segundo escopo** no mesmo repo (é aí que o layout antigo quebra).

## 🔑 Escopo × slug (vocabulário — não confunda os dois)

| | O que é | Onde vive |
|---|---|---|
| **slug** | O **identificador único** do escopo. Chave primária: tudo o mais é derivado dele. | Coluna `Slug` do índice, linha `Slug` do PLAN, nome da pasta, nome do log de apontamento |
| **escopo** | A **descrição legível** daquele slug — o que aquela frente de trabalho é. | Coluna `Escopo` do índice, seção `**Escopo:**` do PLAN |

**Invariantes do slug (valem em qualquer repo):**

1. **Um escopo, um nome. NÃO existem apelidos.** Nada de "o mesmo escopo também atende por X" — duas
   grafias para a mesma coisa é conflito de nome esperando acontecer. Se o nome precisa mudar, isso é
   **rename** (procedimento abaixo), não um segundo nome.
2. **Único globalmente**, não só dentro do repo — porque o log de apontamento é global
   (`<work-log>/<slug>.md`, ver `SESSAO_WORKLOG_DIR`). Prefira nomes distintivos (`aca-amortizacao`, `poc-benchmark`) a
   genéricos (`amortizacao`, `benchmark`), que colidem com outro projeto no dia seguinte.
3. **`slug` == nome da pasta** (`docs/sessoes/<slug>/`) e **`slug` == label do `resumo-trabalho`**
   (`<work-log>/<slug>.md`, ver `SESSAO_WORKLOG_DIR`). Uma string só, sem campo separado para label.
4. **kebab-case**, sem espaço nem acento — ele é nome de pasta e nome de arquivo.

> ⚠️ **Enquanto um escopo antigo tiver pasta ≠ slug** (migração ainda não feita), o caminho do PLAN
> **vem da coluna PLAN do índice**, não da derivação. Isso **não** é apelido: o nome continua sendo um
> só; só o caminho não é calculável. Escopo novo sempre nasce com `slug` == pasta.

### Renomear o slug de um escopo (ato explícito, nunca automático)

Sem apelidos, o nome velho deixa de resolver — de propósito. Renomear é: `git mv` da pasta para o slug
novo · atualizar a linha `Slug` do PLAN e a coluna `Slug` do índice · reescrever os caminhos que citam
a pasta antiga · **decidir o log de apontamento** (`~/.claude/work-log/<slug-velho>.md`): renomeá-lo
junto ou manter o antigo como histórico e o slug seguir o log — **o que preserva histórico vence**.
Diga ao usuário o que aconteceu com o log; nunca deixe apontamento órfão em silêncio.

## 🎯 Resolução de escopo (qual PLAN esta sessão opera)

Sintaxe: **`/sessao <subcomando> [<escopo-slug>] [<texto livre>]`**. O escopo é **argumento, não estado**
— não existe ponteiro de "escopo ativo" guardado em lugar nenhum (ponteiro fica velho, é global
enquanto a sessão é local, e não acompanha a troca de branch). Resolva **nesta ordem** e **diga em 1
linha qual escopo assumiu**:

1. **Slug explícito** logo após o subcomando (`/sessao start poc-benchmark ...`) — vence tudo. Procure-o
   na **coluna `Slug` do índice** — que mora no **`AGENTS.md`** (ou, em projeto instalado antes da
   unificação, no `CLAUDE.md`) e é quem sabe o caminho do PLAN daquele escopo
   (`docs/sessoes/<slug>/` é o padrão, mas escopo ainda não migrado mora onde a coluna PLAN disser).
   **Match exato, sem apelido e sem adivinhação:** se o usuário digitou um nome que não está na coluna
   `Slug`, **pare e liste os slugs que existem** — não "aproxime" para o parecido, não crie escopo por
   engano, e não invente um segundo nome para um escopo que já tem o seu.
2. **Único escopo 🟡 Ativo** no índice (`AGENTS.md`, ou `CLAUDE.md` em projeto legado) → é ele.
3. **Branch atual casa com a "Branch de trabalho"** declarada no cabeçalho de algum PLAN → é ele
   (confirme em 1 linha ao usuário).
4. **Ambíguo** (vários ativos, nenhuma branch casando) → **pergunte**. Nunca chute, e nunca leia o PLAN
   de dois escopos na mesma sessão.

**Trabalhe um escopo por vez em cada working tree.** Escopos são isolados por pasta (baton, board,
checkboxes e relatórios próprios), então alternar entre eles é seguro — o que não é seguro é **duas
sessões simultâneas no mesmo working tree**, que colidem em arquivos e commits. Para paralelismo real,
use `git worktree`.

> ⚠️ **Cuidado que o layout multi-escopo introduz: o PLAN é um arquivo versionado.** Quem determina o
> estado que a sessão enxerga é a **branch**, não o índice. Se o escopo A vive na branch `feature/a` e o
> B na `feature/b`, ao trabalhar em B o PLAN de A pode estar ausente ou velho — a sessão lê estado
> errado e *parece* que o trabalho sumiu. Por isso: **os artefatos de sessão (`docs/sessoes/**` +
> `CLAUDE.md`) devem viver na branch base compartilhada** — mergeie-os cedo e com frequência (são
> documentação, não código da feature). Se o usuário mantém PLANs em branches separadas, avise do risco
> antes de operar.

## Subcomando (deduza do argumento ou pergunte)

O argumento após `/sessao` indica a operação. Sem argumento, pergunte qual é.

### `escopos` — listar os escopos do repo (e onde cada um parou)

Responde a "quais escopos existem aqui?" / "quais slugs esse projeto tem?". Leia o índice do
`AGENTS.md` (ou `CLAUDE.md`, em projeto legado) e, para cada escopo, **só** o cabeçalho "🔎 Agora" + o cabeçalho de parâmetros do `PLAN.md`
dele (nunca o PLAN inteiro, nunca relatório).

Apresente **nesta ordem de colunas** — o slug primeiro, porque é o identificador que se digita; o
escopo é a descrição:

| Slug | Escopo | Estado | Branch | Bloco ativo | 🎬 Próximo | Última atualização |
|---|---|---|---|---|---|---|
| `<slug>` | <descrição curta> | 🟡/🟢/🔴 | `<branch>` | `<bloco>` | ⚙️/🧠 + ponto de entrada | <data> |

Depois da tabela, em 1 linha: **qual escopo seria assumido por padrão** pela regra de resolução (ex.:
o que casa com a branch atual) e o comando para entrar nele (`/sessao start <slug>`). Sinalize também
**inconsistências de identidade** que encontrar — slug ≠ nome da pasta, ou log de apontamento
(`<work-log>/<slug>.md`, ver `SESSAO_WORKLOG_DIR`) inexistente para um escopo com sessões fechadas — em uma linha cada,
como aviso, sem corrigir nada.

**Não altera nada** — é o "onde eu estava?" sem efeito colateral. Aceite também
`/sessao escopos <slug>` para detalhar um só.

### `help` — mostrar o guia de uso da skill
Leia `HELP.md` (ao lado deste arquivo) e apresente o guia (subcomandos, papéis, conceitos-chave, ciclo
de vida). Não altera nada no projeto. Use também quando o usuário pedir "help"/"ajuda"/"como uso o sessao".

### `init` — abrir um escopo (instalando o sistema, se ainda não houver)

**0. Detecte o estado do repo ANTES de qualquer coisa** — `init` **nunca** sobrescreve instalação
existente:
- **Repo virgem** (sem `AGENTS.md`/`CLAUDE.md` de controle e sem nenhum escopo no índice) → instalação
  completa (passos 1–5).
- **Repo já instalado** (existe o protocolo + índice com escopos — mesmo que nenhum deles esteja em
  `docs/sessoes/`) → é **escopo novo**: crie **apenas**
  `docs/sessoes/<novo-slug>/PLAN.md` e acrescente a linha do escopo na tabela do `AGENTS.md`
  (ou do `CLAUDE.md`, em projeto legado que ainda não migrou o índice).
  **Não recrie nem reescreva** `AGENTS.md`, `CLAUDE.md` (fora a linha nova) ou o template de relatório.
- **Layout legado** (PLAN na raiz) → diga isso ao usuário e ofereça migrar para o layout canônico antes
  de abrir o escopo novo; se ele recusar, **não** invente um segundo PLAN na raiz.

1. Leia `templates/AGENTS.template.md`, `templates/CLAUDE.template.md` e `templates/PLAN.template.md`
   (só os que forem necessários ao caso detectado).
2. Levante os `<PLACEHOLDERS>` com o usuário (**não invente**):
   - **Sempre (por escopo):** o **slug** (identificador único — vira pasta, label e nome do log) + o
     **escopo** (descrição legível de 1 linha: o que é essa frente); o que fica **fora** dele; lista
     inicial de blocos (id + título + tipo 🔧 mecânico / 🔬 descoberta); **branch de trabalho**;
     **ambiente** (cluster/`KUBECONFIG`/namespaces/dados) e **guardrails específicos**.
   - **Valide o slug antes de aceitá-lo** (é chave primária, corrigir depois custa rename): kebab-case;
     **não** existe ainda na coluna `Slug` do índice deste repo; **e não colide globalmente** — confira
     `ls ~/.claude/work-log/` e, se já houver um `<slug>.md` de outro trabalho, proponha um nome mais
     distintivo (`aca-amortizacao`, não `amortizacao`). Um slug bom é reconhecível fora do repo.
   - **Não pergunte o label de apontamento** — ele **é** o slug (`<work-log>/<slug>.md`, ver `SESSAO_WORKLOG_DIR`). Se o
     usuário quiser apontar num card já existente com outro nome, isso é escolher o slug igual ao card,
     não criar um segundo campo.
   - **Só na 1ª instalação (por repo):** como tratar o usuário; idioma; política de commit; repos irmãos
     que uma sessão pode tocar; guardrails permanentes.
   - **Não pergunte a pasta de relatórios** — para escopo novo ela é derivada
     (`docs/sessoes/<escopo-slug>/`). Escopo migrado pode ter outra convenção: nesse caso ela está
     **declarada no cabeçalho de parâmetros do PLAN**, e é a declaração que vale.
3. **Confirme o plano da estrutura ANTES de criar** (árvore + Board + guardrails, em texto). Só crie
   depois do OK.
4. Crie os arquivos:
   - `AGENTS.md` (**protocolo permanente + índice de escopos**) e `CLAUDE.md` (**só o import
     `@AGENTS.md`** + eventual seção específica do Claude Code) — **só na 1ª instalação**. Os dois
     saem de `templates/`. ⛔ **Nada de `AGENTS.override.md`** (ver a seção de layout).
   - `docs/sessoes/template-relatorio.md` — **só na 1ª instalação** (copie de `templates/`).
   - `scripts/conferencia_saida.sh` — **só na 1ª instalação**: copie o **lançador**
     `scripts/conferencia_saida.shim.sh` da skill para `scripts/conferencia_saida.sh` do projeto e
     `chmod +x`. ⛔ **NÃO copie `conferencia_saida.sh` da skill** — era o que se fazia até
     2026-09-07, e por isso toda correção do portão parava na skill: escopo instalado em agosto
     seguia rodando o portão de agosto, sem aviso nenhum. O lançador resolve a skill em runtime
     (`$SESSAO_SKILL_DIR` → `~/.claude/skills/sessao` → `~/.codex/skills/sessao` →
     `<repo>/.agents/skills/sessao`) e **falha fechada** (exit 2, nunca 0) se não a achar — portão
     que não roda não pode parecer portão que passou.
   - `docs/sessoes/<escopo-slug>/PLAN.md` — sempre. Detalhe **só o bloco B1**; deixe os demais em uma
     linha, marcados `(rascunho)`. Preencha o cabeçalho de parâmetros do escopo (branch, ambiente,
     namespaces, pasta de relatórios) e a seção "🚧 Guardrails deste escopo".
   - Acrescente a linha do escopo na tabela **🎯 Escopos de trabalho do `AGENTS.md`** (estado 🟡
     Ativo). Em projeto legado, cuja tabela ainda está no `CLAUDE.md`, acrescente lá — e ofereça a
     unificação.
5. **Grave o baton `🎬 Próximo`** no cabeçalho "🔎 Agora" do PLAN novo — o `init` **não** pode deixar o
   baton em branco (sem ele o `start` fica adivinhando o papel). Regra: **B1 🔬 descoberta ou ainda não
   executor-ready → `🧠 Planejador`**; B1 🔧 mecânico e já executor-ready → `⚙️ Executor`.
6. **Commite a instalação — com validação do usuário** (mesma razão do `handoff`: PLAN não-commitado
   faz a próxima sessão ler estado do working tree; mas commit é ato que o usuário autoriza). Se estiver na branch default, use a branch de trabalho declarada no PLAN.
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
1. **Resolva o escopo** pela regra de "🎯 Resolução de escopo" (slug explícito → único ativo → branch
   atual → pergunte) e **diga qual assumiu**. Um `/sessao start <slug> <nota>` é o caso comum quando há
   mais de um escopo: o 1º termo é o slug, o resto é nota de sessão. Então leia só o cabeçalho
   "🔎 Agora" + o bloco ativo daquele `PLAN.md` (não releia relatórios, e nunca leia o PLAN de outro
   escopo). Layout legado → o PLAN é o da raiz.
2. **Determine o papel pelo baton `🎬 Próximo` do cabeçalho Agora — NÃO pergunte se o baton existe.**
   (O baton define o **papel**; a nota de sessão do passo 0 define **se e como** se executa agora — em
   modo briefing o papel continua sendo o do baton, mas a sessão para no briefing.)
   - **`🎬 Próximo: ⚙️ Executor`** (o `handoff` já deixou o bloco pronto) → esta é uma sessão de Executor.
     Em 2-3 linhas diga onde parou + o ponto de entrada, e **comece a executar** dali à risca, marcando
     checkboxes. **NÃO pare para perguntar "sou planejador ou executor?"** — o baton já respondeu.
     Depois disso, cumpra o loop contínuo e as condições terminais fechadas da regra
     **"EXECUTOR NÃO ESCOLHE QUANDO PARAR"**; tarefa concluída não encerra sessão nem resposta.
   - **`🎬 Próximo: 🧠 Planejador`** → entre como Planejador (detalhar/replanejar/handoff do próximo bloco).
   - **Baton ausente/ambíguo** (só aí) → resuma o estado e pergunte o papel.
   - ⚠️ **Baton incoerente = PARADA (defesa do lado do leitor).** Antes de agir, **confira a linha `🎬`
     contra o Board e os checkboxes** do bloco que ela cita — **um comando:**
     `scripts/conferencia_saida.sh <slug> --inicio` (onde o repo tiver o portão instalado; onde não
     tiver, na mão — são 5 segundos). Se ela manda executar
     tarefa já `[x]`, ou aponta bloco 🟢/inexistente, **o baton está podre**: **não execute**, não
     "adivinhe qual seria a próxima tarefa" e não replaneje por conta própria. Mostre ao usuário o que
     a linha diz × o que o Board diz e **pergunte**. É o sintoma clássico de sessão anterior que gravou
     a troca de papel só na prosa — e é o que faz uma sessão refazer um bloco já entregue.
3. **Gates de sessão ≠ retrabalho** (só quando se vai executar — em briefing, pule). Antes de executar, o Executor **reestabelece os gates por-sessão** do
   ponto de entrada — reverificar o **DoR** e **rearmar setup vivo** (carga/probe/shells, `export
   KUBECONFIG`, processos que NÃO sobrevivem entre sessões). Isso é **pré-condição normal, não estado
   perdido**: os *resultados* já feitos estão persistidos (checkbox `[x]` + relatório); só o setup vivo
   precisa subir de novo. Deixe isso explícito ao usuário para não parecer que se está "refazendo" trabalho.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifique se o bloco ativo está **"executor-ready"** (DoD do planejamento): tarefas atômicas com
   checagem verificável; decisões resolvidas; comandos/paths/valores preenchidos; DoR satisfeito;
   escalonamento definido. **E se o bloco muda comportamento descrito em documento de interface
   (chefe/negócio, DBA, README do escopo), a atualização daquele documento entra como tarefa do bloco,
   com o arquivo nomeado** — não como lembrete no fim. Documento de interface não emite erro ao
   envelhecer; se ninguém contratar a atualização, ela não acontece (é o item 8 da Conferência,
   pegando no fechamento o que esta cláusula previne na origem).
2. **MEÇA cada critério de aceite no estado atual antes de fixá-lo como alvo — nenhum é deduzido.**
   Rode o comando do critério **no commit do handoff** e escreva o valor observado ao lado do alvo. Se
   o baseline já reprova o critério, há duas saídas honestas: **mudar o alvo**, ou tornar a correção
   **tarefa explícita do bloco**. Critério escrito por raciocínio ("o código novo será vetorizado, logo
   o grep dará 0") **nasce falso**: é inatingível dentro do contrato, e quem paga é o Executor, que
   trava numa medição que nunca poderia bater. Vale para grep, contagem de teste, diff, tempo — toda
   medida. Cuidado clássico: **grep de código mede a chamada** (`\.foo(`), não a palavra solta, senão
   um comentário correto reprova um código correto.
3. Ajuste o que faltar no `PLAN.md` **do escopo** e confirme que um executor consegue tocar à risca.
4. **Grave o baton no cabeçalho "🔎 Agora":** `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <tarefa>`
   (a 1ª tarefa não-concluída), listando quais **gates por-sessão** reestabelecer antes (DoR + setup vivo).
   É esse baton que faz o `start` da próxima sessão entrar como Executor **sem perguntar**.
5. **Rode a ✅ Conferência de saída** (seção acima) — ela vale para o `handoff` também: baton coerente
   com o Board, resumos batendo com a linha `🎬`, sem 2ª cópia de campo.
6. **Registre o apontamento desta sessão** — **exatamente o passo 5 do `end`** (portanto **só depois
   de o usuário validar o commit**), sem exceção por ser handoff. Um `handoff` É uma sessão inteira de trabalho (mediu baselines, resolveu desenho, corrigiu
   contrato) e **precisa aparecer no apontamento do dia como qualquer outra**.
   ⚠️ **Este passo nasceu de um buraco real:** por muito tempo só o `end` alimentava o log, então toda
   sessão que terminava em `handoff` **sumia do apontamento** — o usuário pedia o resumo do dia e
   faltava metade do trabalho, sem nenhum sinal de erro. Handoff não gera relatório (não fechou bloco),
   e o passo do `end` era indexado por relatório: sem relatório, nada era gravado. Ver o invariante
   **uma sessão = uma entrada** no passo 5 do `end`.
7. **Commit das edições do handoff — SOMENTE com validação explícita do usuário** (mesma regra do
   `end`, passo 6). Não deixe o PLAN pronto porém não-commitado **depois do aval**, senão a próxima
   sessão lê estado do working tree; mas **sem** o aval nada é commitado. Reporte o hash.
   ⛔ **PRÉ-CONDIÇÃO — o handoff é exatamente o momento em que a regra falha:** este passo só se
   executa depois de o plano ter sido **mostrado ao usuário e aceito**, com `**Aceite:** <quem>,
   <AAAA-MM-DD>` no bloco. Um handoff é, por definição, contrato novo indo para o Executor — se ele
   não passou pelo aceite, **não commite**. **Exceção: se
   houver questionamento aberto do usuário, não commite — pergunte antes** (ver "QUESTIONAMENTO ABERTO
   = REGISTRO CONGELADO" nas Regras invioláveis).

### `end` — fim de sessão

**O ritual tem DUAS METADES, com gatilhos diferentes.** Fundi-las foi um bug real (ver a 3ª porta):

| Metade | O que é | Quando dispara |
|---|---|---|
| **Relatório** (passo 1) | o detalhe denso do bloco | só quando o **bloco fecha**, ou o usuário pede |
| **Registro da sessão** (passos 2–6) | PLAN in-place · **linha no §8** · baton · validação → apontamento → portão → commit | em **TODA** sessão que termina, tenha fechado bloco ou não |

Três portas de entrada:
- **Fim de sessão no meio de um bloco, por vontade de encerrar** (bloco aberto, nada obrigou a parar)
  → **só quando o usuário pedir**. Sem relatório; **com** registro da sessão.
- **Fechamento de bloco inteiro** (toda a DoD do bloco satisfeita) → o **Executor auto-dispara este
  ritual por si, sem o usuário pedir**, *antes* de passar o baton (ver "Papéis" nas Regras invioláveis).
  É a **única** porta que gera relatório.
- **PARADA no meio do bloco** — o Executor bateu numa condição terminal que **não** é o fechamento
  (critério que não bateu, decisão de design ausente, estado inesperado, autorização faltando, limite
  técnico da ferramenta) → **auto-dispara o registro da sessão, sem o usuário pedir e sem relatório**:
  PLAN in-place (checkboxes + o motivo da parada + baton `🧠 Planejador`), **linha nova no §8**, e então
  validação → apontamento → portão → commit.
  ⚠️ **Esta porta nasceu de um buraco real (2026-09-04).** Uma sessão de Executor parou por critério
  não batido e **registrou tudo com honestidade** dentro do bloco — mas não deixou **linha no §8 nem
  entrada no apontamento**, porque o passo que as grava morava num ritual cujas portas eram só as duas
  de cima. Sem commit, o **portão também não rodou**: nada falhou, só faltou, e a sessão seguinte teve
  de preencher retroativamente. É a mesma classe de falha silenciosa que já custou caro quando o
  apontamento era indexado por **relatório** (todo `handoff` sumia) — ali o índice errado era o
  artefato, aqui era o **subcomando**. **O índice certo é um só: a sessão terminou.**

1. Gere o relatório **na pasta e no padrão de nome que a linha `Relatórios` do cabeçalho do PLAN
   declara** — default `docs/sessoes/<slug>/RELATORIO_<bloco>_<AAAA-MM-DD>.md`, pelo template
   compartilhado `docs/sessoes/template-relatorio.md`. Se aquele escopo declarar outro padrão (acontece
   em escopo migrado, que já tem relatórios gravados), **respeite o declarado — não renomeie a
   convenção dele no meio do caminho** (detalhe denso: comandos, saídas, números).
2. Atualize o `PLAN.md` **do escopo**, **in-place** (nunca duplique linhas): cabeçalho "Agora"; Board;
   checkboxes do bloco ativo; registro de sessões (1 linha + link).
   ⚠️ **"O bloco fechou" só é verdade se TODOS os critérios de aceite foram medidos e bateram.** Um
   critério que mede diferente do alvo — mesmo que você julgue que a intenção dele foi cumprida —
   **impede o 🟢**: o bloco continua aberto, você registra a medição crua, grava o baton
   `🎬 Próximo: 🧠 Planejador` com o motivo e **PARA**. Decidir se um critério errado ainda serve é do
   🧠 (é o caso "DoD inalcançável" da Fronteira de papel), e relatar a divergência com honestidade
   **não** substitui a parada — fechar 🟢 "com ressalva" é tomar a decisão do 🧠 com aviso prévio.
   **Se o bloco fechou, o que fazer depende de quem está na sessão:**
   - **🧠 Planejador** → promova o próximo bloco de rascunho a detalhado e replaneje o resto (é o ritual
     de fronteira dele).
   - **⚙️ Executor** → marque o bloco como 🟢 Concluído, grave o baton `🎬 Próximo: 🧠 Planejador` com o
     motivo, e **PARE**. Ele **não** promove, **não** detalha e **não** replaneja (Fronteira de papel).
3. **Grave/atualize o baton `🎬 Próximo`** no cabeçalho Agora com o papel da próxima sessão + ponto de
   entrada: `⚙️ Executor` se o bloco segue executor-ready; `🧠 Planejador` se a fronteira exige
   (re)planejamento (bloco fechou e o próximo está em rascunho, ou surgiu decisão de design em aberto).
4. Se o **escopo inteiro** fechou, marque-o 🟢 Concluído na tabela de escopos do `AGENTS.md` (a pasta
   fica, é histórico). **Opcional** (só onde a ferramenta tiver memória automática, como o Claude
   Code): atualize ponteiros de memória se algo de alto nível mudou. No Codex não há equivalente —
   pule sem cerimônia.
5. **Registre o apontamento no `resumo-trabalho` — DEPOIS de o usuário validar o commit; o label É o
   slug.** É o elo que mantém os apontamentos sincronizados sem depender de `registrar` manual, para o
   `gerar <slug>` do dia sair completo.
   ⛔ **Não escreva o log antes do aval.** O log é o registro do que ficou valendo; se o usuário
   discordar do que foi feito — e isso acontece — um apontamento já gravado vira histórico falso num
   arquivo **append-only e fora do repo**, que nenhum `git reset` desfaz. Validou o commit ⇒ o
   apontamento é escrito automaticamente, sem novo pedido. Não validou ⇒ **nada é escrito**.

   > 🔑 **INVARIANTE: uma sessão que termina = UMA entrada no log. O índice é a SESSÃO, não o
   > relatório.** Toda sessão que chega a `end` **ou** a `handoff` grava sua entrada — executor que
   > fechou bloco, executor que parou no meio, planejador que fez handoff, sessão de validação que não
   > tocou em código. **Relatório é matéria-prima quando existe, não é a condição para registrar.**
   > *Por que este invariante existe:* enquanto o passo era indexado por **relatório**, toda sessão sem
   > relatório (todo handoff, toda validação) **sumia do apontamento** — o usuário pedia o resumo do dia
   > e faltava metade do trabalho, **sem nenhum sinal de erro**, porque o passo "rodou com sucesso" e
   > não tinha nada para coletar. Falha silenciosa: só se descobre quando alguém compara o dia com a
   > memória. Num dia de 4 sessões, 2 ficaram fora por esse motivo.

   - O log do escopo é `<work-log>/<slug>.md`, onde `<work-log>` é `$SESSAO_WORKLOG_DIR` se
     definido, senão `~/.claude/work-log` (default histórico, usado por qualquer ferramenta — o
     caminho é só o endereço do arquivo, não uma dependência do Claude Code). **Não procure campo "label" no PLAN** — não
     existe mais campo separado; se um PLAN antigo ainda declarar um label diferente do slug, isso é
     inconsistência de identidade: **avise o usuário e pergunte** qual dos dois nomes vale (o que tem
     histórico no log costuma vencer), em vez de escrever nos dois.
   - **Levante as sessões de HOJE que ainda não estão no log** — não só a sua. Cruze o **registro de
     sessões (§8) do PLAN** com as entradas de hoje no log: linha do §8 com a data de hoje e sem
     entrada correspondente é buraco a preencher, inclusive de sessão anterior que não registrou.
   - **Fonte de cada entrada, nesta ordem:** (1) o **relatório** da sessão, se existir; (2) senão, a
     **linha do §8 + a entrada do §7** que aquela sessão gravou + os **commits** dela. Nunca invente
     nada fora dessas fontes. Se uma sessão antiga não deixou rastro suficiente, **diga isso ao usuário
     em 1 linha** em vez de preencher com suposição.
   - **Idempotência:** procure no log a chave da sessão — o basename do relatório
     (`RELATORIO_<bloco>_<data>.md`) quando houver, ou a linha `**Sessão:** <N>`. **Se já aparece,
     pule.** Senão, faça **append** de uma entrada densa e factual (formato do `resumo-trabalho`:
     O que foi feito / Problemas-Correções / Validações / Pendências). Logo abaixo do cabeçalho
     `## [data hora] <projeto>`, grave as duas linhas de rastreio:
     `**Relatório-fonte:** <caminho>` — ou `— sessão sem relatório. Fonte: <§8/§7/commits>` — e
     `**Sessão:** <N>`. São elas que tornam o passo idempotente.
   - **Horário do cabeçalho = quando a sessão realmente aconteceu**, não a hora em que você está
     escrevendo. Para sessão anterior, tire dos commits dela (`git log --date=format:'%Y-%m-%d %H:%M'`)
     e marque a entrada como *registrada retroativamente*.
   - Log é **append-only e global** (`~/.claude/work-log/`), fora do repo — **não** entra no commit do
     passo 6. Confirme em 1 linha quais sessões viraram entrada (ou "nada novo a registrar").
6. **Commit SOMENTE com validação explícita do usuário.** Apresente o que foi feito e **pergunte se
   pode commitar**; sem o "ok", as mudanças ficam no working tree. Isto **substitui** o antigo "commit
   obrigatório", que commitava por conta própria: o usuário frequentemente discorda do resultado ao
   fim da sessão, e desfazer commit é mais caro do que esperar uma frase. Continua valendo a
   "QUESTIONAMENTO ABERTO = REGISTRO CONGELADO" (Regras invioláveis). Commite o
   relatório novo, o `PLAN.md` e as demais mudanças da sessão, seguindo as convenções de commit do
   repo (mensagem no padrão do projeto). **Commite só o que é deste escopo + o que a sessão tocou** —
   num repo multi-escopo, `git add -A` cego varre trabalho de outra frente para dentro do seu commit.
   Se houver arquivos modificados alheios à sessão, **liste-os ao usuário e deixe de fora**. Se a sessão tocou **mais de um repo** (ex.: repos irmãos
   operator/clusters), commite em **cada** um. Se estiver na branch default, crie/*use* a **branch de
   trabalho declarada no PLAN do escopo**. **`push` também exige validação explícita — inclusive
   commit destinado a deploy**, que antes era exceção e deixou de ser: `push` publica para fora e não
   se desfaz sem estrago, então ele é pedido em separado do commit, mesmo quando a entrega é para
   deploy (ver "Entrega destinada a deploy" nas Regras invioláveis, que continua descrevendo a cadeia
   de elos — só não autoriza mais o push sozinho). Ao fim, reporte o(s) hash(es) de commit.

## ✅ Conferência de saída (obrigatória antes de QUALQUER commit de `end`/`handoff`)

O sistema falha por **inconsistência de registro**, não por falta de boa intenção: o agente escreve a
verdade em 3 lugares, esquece o 4º, e a sessão seguinte lê o 4º. Por isso o fechamento não depende de
cuidado — depende **desta conferência**, que é mecânica e se responde com o arquivo aberto e um
comando. Rode todos os itens e **não commite com nenhum vermelho**: vermelho é **PARADA**, não
ressalva no relatório.

> ### 🔒 Ordem canônica do fechamento (a validação do usuário é o eixo)
>
> 1. Preparar tudo **no working tree**: `PLAN.md` in-place (cabeçalho, Board, checkboxes, **linha 🎬**)
>    e o relatório, se houver.
> 2. **Apresentar ao usuário** o que foi feito e **pedir validação para commitar**.
> 3. **Sem o "ok": PARA.** Nada de commit, nada de push, **nada de escrever no `work-log`**.
> 4. Com o "ok": **escrever o apontamento** em `~/.claude/work-log/<slug>.md` (automático a partir daqui
>    — não peça duas vezes).
> 5. **Rodar o portão** (abaixo) — é aqui que ele roda, com o apontamento já no lugar, senão o item ⑤
>    reprova por um motivo falso.
> 6. **Commitar.** 7. **`push` só com validação própria**, pedida em separado.
>
> Por que o log vem depois do aval: ele é **append-only e fora do repo**, então um apontamento gravado
> sobre trabalho que o usuário rejeitou vira histórico falso que nenhum `git reset` desfaz.

**0. RODE O PORTÃO E COLE A SAÍDA CRUA no resumo da sessão — obrigatório, não é opcional:**
`scripts/conferencia_saida.sh <slug> <commit em que esta sessão começou>` (o commit sai de
`git rev-parse HEAD` no início; se esqueceu, é o último commit da sessão anterior). Ele sai com
**exit 1** se a linha `🎬` continua **intacta** desde o início da sessão, se o ponto de entrada citado
já está `[x]`, se o registro de sessões não ganhou linha nova, se falta o apontamento da sessão no
log, ou se **esta sessão escreveu contrato de bloco e passou o baton para ⚙️ sem a linha
`**Aceite:** <quem>, <AAAA-MM-DD>` no PLAN** (item ⑥). **Declarar que conferiu não substitui rodar** — os itens 2, 3 e 5 abaixo já estavam escritos, com
todas as letras, nas duas vezes em que o defeito passou. Repo sem o portão instalado (instalação
anterior a ele): copie o **lançador** `scripts/conferencia_saida.shim.sh` da skill para
`scripts/conferencia_saida.sh` do projeto — é a mesma correção. Projeto que ainda tenha a **cópia
integral** do portão (instalação anterior a 2026-09-07) deve trocá-la pelo lançador: enquanto for
cópia, ele está congelado na versão do dia em que foi instalado.
Os itens 1–9 abaixo seguem **na mão**; o portão cobre os **seis** decidíveis por comando (①-⑥).
⚠️ **Se mexer no portão ou nos templates, rode `scripts/autoteste_portao.sh` da skill.** Ele monta um
repo descartável a partir dos templates e afirma que cada item dispara. Existe porque em 24/08/2026 uma
auditoria achou o portão fazendo valer **2 dos 6 itens** em qualquer projeto novo: ele fora escrito
contra o dialeto de UM repo (`### 📋 Tarefas`, critérios em tabela, sessões numeradas) enquanto o
`PLAN.template.md` gera outro (`### Tarefas`, critérios em lista, sessões por data). Os itens ③④⑤ saíam
`⚠️` e o ⑥ não saía, com **exit 0** — "aprovado" sem ter conferido quase nada.

1. **Critérios de aceite — cada um MEDIDO** (comando + saída crua), e o resultado bate o alvo. **Um só
   que não bata ⇒ o bloco NÃO fecha:** nada de 🟢, nada de "fechado com ressalva", nada de reinterpretar
   o critério pela intenção que você lê nele. Registre o que mediu, grave o baton `🧠 Planejador` com o
   motivo e pare.
2. **Baton `🎬 Próximo` — a *linha*, não a prosa.** Ela precisa dizer o papel e o ponto de entrada
   corretos **para depois desta sessão**. Confira contra o Board: se o bloco que ela cita está 🟢, ou a
   tarefa citada está `[x]`, a linha está **podre** — corrija ANTES do commit. Escrever "baton → 🧠" só
   no resumo, no relatório ou na mensagem de commit **não** troca o baton.
3. **Um estado, um lugar.** Papel e ponto de entrada moram na linha `🎬`; cabeçalho, Board, registro de
   sessões e mensagem de commit são **resumos**. Os resumos batem com a linha `🎬`? Divergiu, **a linha
   `🎬` vence** e os resumos se ajustam a ela.
4. **Board × checkboxes.** Todo bloco 🟢 tem todas as tarefas `[x]`; nenhum bloco com tarefa aberta
   está 🟢.
5. **Número e append vêm do arquivo, não da memória.** O identificador da linha nova do registro de
   sessões sai do **último valor da própria tabela + 1** — nunca do número do relatório, que tem série
   própria e quase nunca coincide. ⚠️ **Se a tabela daquele PLAN não tem coluna de número** (é o caso
   do `PLAN.template.md`, cuja tabela é `| Data | Bloco(s) | Resumo | Relatório |`), então **não invente
   um**: a chave da sessão passa a ser a **data**, e o apontamento é indexado pelo cabeçalho
   `## [AAAA-MM-DD ...]` do log — que é o que o item ⑤ do portão confere. Mesma regra para o nome do relatório: use o padrão declarado no
   cabeçalho do PLAN, conferindo o último gravado na pasta.
6. **In-place, sem 2ª cópia.** O que você escreveu atualizou o campo existente, em vez de criar uma
   segunda cópia dele em outro ponto do arquivo.
7. **`git status` limpo de estranhos** — só o que é deste escopo e desta sessão entra no commit.
8. **Documento de interface não envelheceu.** Se a sessão mudou comportamento que algum **documento
   voltado a terceiro** descreve — o que vai ao chefe/negócio, ao DBA, o README do escopo, um contrato
   publicado — ele foi **atualizado nesta sessão**, ou a pendência está escrita com dono. É o único
   item desta lista cuja falha **ninguém descobre lendo código nem rodando teste**: nenhum teste
   quebra e nenhum grep acusa, então o arquivo segue afirmando a um terceiro o que já não é verdade
   até alguém repassá-lo. *(Caso real: dois blocos mudaram cascata de regras e persistência; o
   documento do chefe continuou anunciando a ele duas estratégias trocáveis por flag que haviam sido
   removidas — só apareceu numa auditoria pedida por desconfiança, dois meses depois.)*

9. **Nenhuma decisão pendente foi selada por fora.** Se durante a sessão você levantou uma decisão que
   é do usuário e ela **não** foi respondida, ela **não** pode virar premissa do contrato, nem
   "recomendação" no fim da mensagem, nem tarefa do Executor. Ou ela foi respondida, ou o bloco **não
   fecha**. Este item é irmão do ⑥ do portão — o ⑥ pega a **falta de aceite**; este pega o **aceite
   obtido sobre um plano incompleto**, que nenhum comando enxerga.

> **Por que checklist e não "seja cuidadoso":** os 4 defeitos que motivaram esta seção saíram de uma
> única sessão de Executor que **relatou tudo com honestidade** — o baton velho, o critério que não
> bateu, o número copiado da série errada. Transparência no relatório não impede que a próxima sessão
> leia o campo errado; só a conferência impede.

## Regras invioláveis (valem em qualquer subcomando)

- **QUESTIONAMENTO ABERTO = REGISTRO CONGELADO.** No instante em que o usuário questiona, discorda ou
  pede para validar algo, **para de escrever**: nada entra em `PLAN.md`, `AGENTS.md`, relatório,
  memória ou commit até ele dizer que concorda — **com tudo**, não com a parte que pareceu resolvida.
  Concordar com um ponto não libera os outros; silêncio não é aval; "faz sentido" no meio da conversa
  não é aval. O aval é explícito e vem **depois** de ele ver a evidência.
  **Por quê:** registrar é o ato que transforma hipótese minha em verdade oficial do projeto — o PLAN é
  lido por sessões futuras como fato estabelecido, e commit por cima de análise não validada propaga o
  erro e custa caro de desfazer. Enquanto há questionamento aberto, a análise **ainda não é** conclusão:
  é proposta.
  **O que fazer no lugar:** apresentar a **evidência crua** (diff, saída de comando, trecho de arquivo)
  + a conclusão que tiro dela + as opções, e **perguntar**. Manter as mudanças no working tree, sem
  commit. Só depois do "ok" registrar.
  **Não vale como desculpa:** "era só documentar", "é reversível", "ia commitar mesmo", "o ritual de
  `end` manda commitar". O ritual **não** sobrepõe esta regra — se há questionamento aberto no fim da
  sessão, o `end` **para** e pergunta antes de commitar.
  **PLANO TAMBÉM É REGISTRO — e é o caso que mais escapa.** Selar um bloco (escrever o contrato no
  `PLAN.md`, gravar o baton, commitar) exige **decisões pendentes zeradas** e o **plano mostrado e
  aceito**, registrado como `**Aceite:** <quem>, <AAAA-MM-DD>` no bloco. ⚠️ **Responder às perguntas
  do agente NÃO é aceitar o plano:** 3 perguntas respondidas fecham as 3 perguntas, não abrem o
  commit. O portão confere isso no item ⑥ — a regra já falhou uma vez estando escrita em três lugares
  ao mesmo tempo, o que prova que prosa auto-atestada não segura.
  **Se eu já registrei antes do aval:** dizer isso explicitamente na primeira frase, oferecer o
  `git reset --soft` (ou reverter a edição) e **esperar** — nunca deixar passar como se tivesse sido
  combinado, nunca "aproveitar que já está lá".
  **Exceção única:** trabalho **mecânico já contratado** dentro de um bloco executor-ready — marcar
  checkbox de tarefa concluída, gerar relatório de bloco fechado no ritual acordado. Conclusão nova,
  reenquadramento de causa raiz, mudança de contrato, criação/cancelamento de bloco e reordenação de
  Board **nunca** são mecânicos.
- **Escopo é argumento, não estado; um por vez por working tree.** `/sessao <sub> [<slug>] [nota]`,
  resolvido por slug → único ativo → branch → pergunta (ver "🎯 Resolução de escopo"). Nunca guarde
  ponteiro de escopo ativo, nunca opere dois PLANs na mesma sessão, e **mantenha `docs/sessoes/**` +
  `AGENTS.md` na branch base** — o PLAN é versionado, então branch errada = estado errado.
- **Um escopo = uma pasta; o protocolo é um só.** Frente de trabalho nova = `docs/sessoes/<slug>/PLAN.md`
  novo, **nunca** um segundo protocolo. `AGENTS.md` e `template-relatorio.md` são **reusados, jamais
  copiados por escopo**; o `CLAUDE.md` é só o import `@AGENTS.md`. Nada específico de escopo (branch, ambiente,
  `KUBECONFIG`, guardrails da frente) entra no `AGENTS.md` — isso mora no PLAN do escopo,
  senão o próximo escopo herda restrição que não é dele. E `init` **nunca sobrescreve** instalação
  existente (ver passo 0 do `init`).
- **Entrega destinada a deploy: o pipeline tem mais elos que o commit — mas o `push` PEDE VALIDAÇÃO.**
  Quando o commit existe **para ser deployado**, deixá-lo só local é entrega incompleta: quem builda
  (Jenkins/CI) lê do **remoto**, então um commit não-pushado vira um deploy que "não mudou nada", sem
  erro nenhum — o modo de falha mais caro e mais confuso, porque parece problema de deploy e é falha de
  autoria. **Por isso: ao commitar para deploy, PEÇA a validação do push no mesmo turno** — explique
  que sem ele o deploy roda e não muda nada. ⚠️ **Revertido em 2026-08-24:** esta regra autorizava o
  push automático "sem esperar o usuário pedir". Não autoriza mais. `push` publica para fora e não se
  desfaz sem estrago; o risco de um push indevido é maior que o de um deploy que não pegou, que o
  diagnóstico de 5 s abaixo resolve. **Avise, e espere.**
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
  denso → relatórios do escopo; ganchos → memória automática, **onde a ferramenta tiver uma**. Nunca suba detalhe de relatório para o PLAN.
- **Rolling-wave:** detalhe só o bloco ativo (+ próximo). Replanejar na fronteira do bloco é ritual.
- **Papéis:** Planejador (modelo forte) deixa o bloco executor-ready e NÃO implementa, especificando
  decisões e restrições — não keystrokes. Executor (modelo barato) executa à risca, e ao divergir do
  plano PARA e escala de volta — não improvisa decisão de design. Auto-verifica contra a DoD.
- **EXECUTOR NÃO ESCOLHE QUANDO PARAR — execução contínua até condição terminal.** Um `start` cujo
  baton é `⚙️ Executor` inicia um **loop contínuo sobre o bloco ativo**, não a execução avulsa da tarefa
  citada no ponto de entrada. Ao concluir uma tarefa, o Executor valida seu resultado, marca o checkbox
  e **começa imediatamente a próxima tarefa aberta do mesmo bloco**. Concluir uma tarefa, atingir um
  "bom checkpoint", produzir bastante trabalho, consumir muito tempo/contexto ou poder oferecer um
  resumo **não são condições de parada**: o Executor não pode por decisão própria encerrar a resposta,
  devolver o controle ao usuário, reduzir/reordenar/reinterpretar o contrato ou trocar o baton por
  causa delas. As condições terminais são uma **lista fechada**:
  1. o bloco inteiro satisfez a DoD — dispara o auto-`end`, prepara relatório/PLAN, pede a validação do
     commit e para na fronteira de papel;
  2. a realidade divergiu do contrato e exige decisão de design, o estado ficou ambíguo/inesperado ou
     uma tarefa exigiria escolha não resolvida no PLAN — grava o motivo, devolve ao Planejador e para;
  3. um critério de aceite mediu diferente do alvo — registra a saída crua, devolve ao Planejador e
     para;
  4. falta autorização externa indispensável — solicita a autorização e aguarda;
  5. o usuário interrompe ou ordena explicitamente pausar/encerrar; ou
  6. há limite técnico real da ferramenta que impede continuar nesta resposta — informa o impedimento
     concreto e preserva como ponto de entrada a primeira tarefa aberta.
  **Toda condição terminal encerra a sessão PELO RITUAL — não só a 1ª.** A condição 1 dispara o `end`
  completo (relatório + registro). As condições **2, 3, 4 e 6** disparam a **3ª porta do `end`** — o
  registro da sessão **sem** relatório: PLAN in-place com o motivo, **linha nova no §8**, baton
  `🧠 Planejador`, e então validação → apontamento → portão → commit. Na condição 5 quem manda é a
  ordem do usuário. **Parar não dispensa registrar:** sessão que não deixa linha no §8 **não existe**
  para a próxima, e é o portão (itens ④ e ⑤) que pega isso — mas só se houver commit para ele guardar.
  Se nenhuma dessas seis condições ocorreu, **emitir resposta final é violação do protocolo**. O
  Executor não resolve por conta própria uma decisão ausente do contrato: decisão não resolvida é a
  condição 2, nunca licença para improvisar. Esta regra governa todos os escopos e sobrepõe qualquer
  hábito geral de entregar progresso em checkpoints convenientes.
- **Critério de aceite não batido = PARADA — mesmo que a intenção pareça cumprida.** Vale nos dois
  lados: **🧠 mede** todo critério no estado atual antes de fixá-lo como alvo (critério deduzido nasce
  falso e trava o Executor numa medição inatingível); **⚙️ não fecha** bloco cujo critério mediu
  diferente do alvo, e **nunca** relê o critério pela intenção que enxerga nele ("o alvo era 0 para
  garantir X, e o meu código faz X, então vale") — quem julga se um critério errado ainda serve é o 🧠.
  Registrar o achado com transparência **não** substitui a parada.
- **O baton é a LINHA `🎬 Próximo:`, não a prosa em volta dela.** Escrever "baton → 🧠" no resumo da
  sessão, no relatório ou na mensagem de commit e deixar a linha `🎬` com o papel e o ponto de entrada
  antigos entrega à sessão seguinte um bloco já fechado como se fosse tarefa aberta — ela entra no papel
  errado e refaz o que está pronto. Quem escreve atualiza **aquela linha**, in-place, antes do commit;
  quem lê **confere a linha contra o Board** e para se as duas discordarem (`start`, passo 2).
  ⚠️ **Esta regra já falhou duas vezes estando escrita** (2026-08-17 e 2026-08-19, no mesmo repo): nas
  duas, a sessão anunciou a troca de papel no resumo, no relatório **e** na mensagem de commit e deixou
  a linha `🎬` com o ponto de entrada antigo. **Conferência auto-atestada mede a intenção de quem
  executa, não o arquivo** — por isso ela virou o **portão** `scripts/conferencia_saida.sh`, que
  reprova o commit quando a linha `🎬` não foi reescrita na sessão (item 0 da Conferência de saída).
- **Fechamento passa pela ✅ Conferência de saída** (seção própria acima) — `end` e `handoff`, sempre,
  antes do commit. Nenhum item vermelho vira "ressalva no relatório": vermelho é PARADA.
- **Executor fecha o próprio bloco (auto-`end` na fronteira):** ao concluir um **bloco inteiro** (toda a
  DoD satisfeita), o Executor **dispara o ritual `end` por si — relatório + atualização in-place do PLAN
  — sem o usuário pedir**, e só então grava o baton `🎬 Próximo`. ⚠️ **O que é auto-disparado é o
  RITUAL, não o commit:** o passo 6 (commit) e o `push` continuam exigindo validação explícita, e o
  apontamento só é escrito depois dela (ver "Ordem canônica do fechamento"). É o mesmo `end`, auto-disparado
  no fechamento de bloco. **Não** vale para gerar **relatório** no meio de um bloco (bloco ainda
  aberto): aí não há fechamento, e relatório continua sendo ato explícito do usuário. ⚠️ **Mas o
  REGISTRO da sessão vale sempre** — se a interrupção foi uma **PARADA** (condição terminal 2, 3, 4 ou
  6), o Executor auto-dispara a **3ª porta do `end`** (§8 + baton + validação → apontamento → portão →
  commit), sem o usuário pedir. Não gerar relatório **nunca** significa não registrar a sessão. Isto **não** contradiz a "Fronteira de papel = PARADA": o Executor
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
  auto-`end` de **fechamento de bloco** (toda a DoD satisfeita). Terminar no meio de um bloco **não**
  gera relatório: aí atualize checkboxes e estado no PLAN — **e, se foi PARADA, dispare o registro da
  sessão pela 3ª porta do `end`** (§8 + baton + validação → apontamento → portão → commit). **Não
  gerar relatório nunca significa não registrar a sessão.**
- **Baton de papel (`🎬 Próximo`):** o cabeçalho "Agora" carrega SEMPRE uma linha
  `🎬 Próximo: <⚙️ Executor|🧠 Planejador> · Ponto de entrada: <tarefa>`. É a fonte de verdade do papel
  da próxima sessão — `init`/`handoff`/`end` a gravam, `start` a lê e age sem perguntar. Sem baton, o
  `start` fica adivinhando o papel (bug): mantenha-a sempre atual.
- **Nota de sessão precede o baton (mas não o substitui):** texto livre depois de `/sessao start` é
  processado **antes** de qualquer tarefa. Ele pode **suspender a execução** (briefing: carregar o
  contexto do ponto onde parou, sem ler tudo, e parar) e pode **condicionar** a execução (diretivas
  operacionais), mas **não redefine o papel** — quem define papel é o baton — nem altera o contrato do
  bloco por conta própria (isso é PARADA + decisão do usuário). Diretivas valem só para a sessão.
- **Sincronia com `resumo-trabalho`: UMA SESSÃO = UMA ENTRADA, e o label É o slug — mas só APÓS o
  usuário validar o commit.** `end`, `handoff` **e toda PARADA no meio de bloco** alimentam `<work-log>/<slug>.md` — **o índice é a sessão, não o relatório, e muito menos o subcomando**. Toda
  sessão que termina grava a sua entrada: fechou bloco, parou no meio, fez handoff ou só validou.
  **Relatório é matéria-prima quando existe**; quando não existe (handoff, validação e PARADA nunca geram um),
  a fonte é a **linha do §8 + a entrada do §7 + os commits** daquela sessão. Nada é inventado fora
  dessas fontes; se o rastro não bastar, diga ao usuário em vez de supor. Idempotência pela linha
  `**Relatório-fonte:**` ou `**Sessão:** <N>`; horário do cabeçalho = quando a sessão **aconteceu**.
  **Indexar por relatório foi um bug caro:** toda sessão sem relatório sumia do apontamento **sem
  sinal de erro nenhum** — o passo "rodava com sucesso" porque não havia o que coletar, e o usuário só
  descobria ao ler o resumo do dia e sentir falta do próprio trabalho. O log é append-only, global e
  **fora do repo** — nunca entra no commit. Como o log é global, **o slug precisa ser único entre
  projetos**, não só dentro do repo (ver "🔑 Escopo × slug").
- **Pedido de resumo/apontamento dentro de um escopo é DAQUELE escopo — nunca agregado do dia.** Quando
  o usuário pede "registre e gere os apontamentos de tudo que foi feito hoje" no contexto de um escopo
  (durante a sessão ou logo após o `end`/`handoff`), o alvo é `gerar <slug>` — **um** arquivo,
  `~/.claude/work-log/<slug>.md`. **Não varra `~/.claude/work-log/*.md`** e não use `gerar dia`: "hoje" é
  filtro de **data dentro do escopo**, não o universo de busca. **Por quê:** o apontamento é colado num
  card específico do GitLab, então misturar labels entrega à chefia trabalho de outra frente, em outro
  repo. **Caso real (17/08/2026):** logo após o `end` do escopo `airflow-es-remote-logging`, a varredura
  global trouxe `aca-amortizacao` para dentro do resumo. `gerar dia` **só** com pedido explícito de
  agregar todos os cards. E depois de um `end`/`handoff` que já registrou, **não registre de novo** —
  confirme a idempotência (`**Relatório-fonte:**` / `**Sessão:** <N>`) e só gere.
- **Gate por-sessão × marco (não confundir):** um **marco** é um resultado que persiste (medição/entrega →
  checkbox `[x]` + relatório). Um **gate por-sessão** é pré-condição/processo vivo que **não** sobrevive
  entre sessões (DoR = "está saudável agora?"; armar carga/probe/shells) e **é reestabelecido toda sessão
  de execução** — isso NÃO é retrabalho nem estado perdido. No PLAN, marque gates com **🔁** (ex.:
  `🔁 T0 — DoR`, `🔁 T1 — armar carga+probe`) em vez de checkbox de marco, para o Executor saber que os
  refaz sempre e ninguém achar que "perdeu" resultado.

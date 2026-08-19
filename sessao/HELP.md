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

## Layout: um repo, vários escopos

Um repositório dura mais que uma frente de trabalho. **O protocolo é permanente; o plano é por
escopo** — por isso a raiz não cresce a cada feature nova:

```
<repo>/
├── CLAUDE.md                      ← índice auto-carregado: aponta o AGENTS.md + lista os escopos
├── AGENTS.md                      ← protocolo permanente (papéis, ritual, convenções, guardrails gerais)
└── docs/sessoes/
    ├── template-relatorio.md      ← gabarito compartilhado (um por repo)
    └── <escopo-slug>/             ← UM ESCOPO = UMA PASTA
        ├── PLAN.md                ← fonte única de verdade daquele escopo
        └── RELATORIO_<bloco>_<AAAA-MM-DD>.md
```

**Permanente (AGENTS.md)** — papéis, ritual, convenções de commit, repos irmãos, guardrails que valem
sempre. **Do escopo (PLAN.md)** — escopo/Board, **branch de trabalho**, **ambiente e variáveis**
(`KUBECONFIG` etc.), **slug + descrição**, guardrails daquela frente. Misturar é o que dá bagunça: o
escopo seguinte herdaria restrição que não é dele, ou o protocolo viraria N cópias.

**Projeto antigo (PLAN na raiz)** continua funcionando como está; a migração só vale a pena quando você
for abrir o **segundo escopo** no mesmo repo.

## Os 4 artefatos (4 papéis, zero sobreposição)

| Artefato | Papel único | Entra no contexto |
|---|---|---|
| **`AGENTS.md`** + **`CLAUDE.md`** (raiz) | **Como trabalhar** (protocolo permanente) + **índice de escopos** | Sempre (automático) |
| **`docs/sessoes/<escopo>/PLAN.md`** | **Fonte única de verdade viva daquele escopo**: Agora + parâmetros + guardrails + Board + bloco ativo + futuros (rascunho) + decisões + registro | Sempre — só o cabeçalho + bloco ativo |
| **`docs/sessoes/<escopo>/RELATORIO_<bloco>_<data>.md`** | **Histórico denso** (problema→causa→solução→evidência), 1 por sessão | Quase nunca — só p/ resgatar detalhe |
| **Memória** | **Ponteiros** de alto nível entre sessões | Índice sempre; detalhe sob demanda |

Não existe arquivo de STATUS separado — ele é a primeira seção do `PLAN.md` (`🔎 Agora`).

> **Escoadouro automático:** o `end` também alimenta o log da skill `resumo-trabalho`
> (`~/.claude/work-log/<slug>.md` — o label **é** o slug do escopo) a partir dos
> relatórios do dia — ver a seção "🔗 Apontamentos automáticos" abaixo. Não é um 5º artefato do modelo:
> é um consumidor a jusante dos relatórios, fora do repo.

## Alternar entre escopos (um repo, várias frentes)

Sintaxe: **`/sessao <subcomando> [<escopo-slug>] [<texto livre>]`**. **O escopo é argumento, não
estado** — não existe "escopo ativo" guardado, porque ponteiro fica velho, é global enquanto a sessão é
local, e não acompanha a troca de branch. Quando você omite o slug, o agente resolve nesta ordem e diz
qual assumiu:

```
1. slug explícito     /sessao start poc-benchmark só carrega o contexto
2. único 🟡 ativo     (não há o que confundir)
3. branch atual       casa com a "Branch de trabalho" declarada no PLAN
4. ambíguo            pergunta — nunca chuta
```

`/sessao escopos` lista tudo — **slug** (o identificador que se digita) · **escopo** (a descrição) ·
estado · branch · bloco ativo · baton · última atualização — sem alterar nada. É o "onde eu estava?" e
o "quais slugs existem aqui?".

**É seguro ter vários escopos ativos**, desde que **um por vez em cada working tree**: cada escopo tem
baton, board, checkboxes e relatórios próprios, então eles não se atropelam. O que colide é rodar
**duas sessões ao mesmo tempo no mesmo working tree** (arquivos e commits misturados) — para isso,
`git worktree`.

> ⚠️ **O PLAN é um arquivo versionado.** Quem determina o estado que você enxerga é a **branch**, não o
> índice. Se cada escopo vive na sua branch, ao entrar em um deles o PLAN do outro pode estar ausente
> ou velho, e vai parecer que o trabalho sumiu. Mantenha `docs/sessoes/**` e o `CLAUDE.md` na **branch
> base** — são documentação, não código da feature; mergeie cedo e com frequência.

## Os subcomandos

O argumento depois de `/sessao` indica a operação. Sem argumento, o agente pergunta qual é.

### `escopos` — listar os escopos do repo
Tabela com **slug** (identificador) · **escopo** (descrição curta) · estado · branch de trabalho ·
bloco ativo · baton `🎬 Próximo` · última atualização — e, em 1 linha, qual seria assumido por padrão
na branch atual, com o comando para entrar nele. Avisa também inconsistências de identidade (slug ≠
nome da pasta, log de apontamento faltando). Não altera nada. `/sessao escopos <slug>` detalha um só.

### `init` — abrir um escopo (instalando o sistema, se ainda não houver)
0. **Detecta o estado do repo** e **nunca sobrescreve** o que já existe: repo virgem → instalação
   completa; repo já instalado → **só** a pasta do escopo novo (`docs/sessoes/<slug>/PLAN.md`) + uma
   linha no índice do `CLAUDE.md`; layout legado (PLAN na raiz) → avisa e oferece migrar.
1. Lê os templates necessários (`AGENTS`, `CLAUDE`, `PLAN`).
2. Levanta os `<PLACEHOLDERS>` **com o usuário** (não inventa). **Por escopo:** **slug** (validado:
   kebab-case, inédito no repo e sem colidir em `~/.claude/work-log/`) + **descrição**, o que fica fora
   do escopo, blocos iniciais (id + título + tipo 🔧/🔬), **branch de trabalho**, ambiente e
   **guardrails específicos**. **Só na 1ª instalação:** tratamento, idioma, política de commit, repos
   irmãos, guardrails permanentes. Não pergunta pasta de relatórios nem label — ambos derivam do slug.
3. **Confirma a estrutura ANTES de criar.** Depois cria: `AGENTS.md`/`CLAUDE.md` + template de
   relatório (só na 1ª vez) e o `PLAN.md` do escopo — **detalha só o bloco B1**; os demais ficam em 1
   linha marcados `(rascunho)`.
4. **Grava o baton `🎬 Próximo`** (B1 🔬 ou ainda não executor-ready → 🧠 Planejador) e **commita a
   instalação** — PLAN não-commitado faz a próxima sessão ler estado do working tree. Mostra a árvore.

### `start [<texto livre>]` — início de sessão
0. **Nota de sessão** — se você escrever qualquer coisa depois de `start`, ela é lida e classificada
   **antes** de qualquer tarefa começar:
   - **(A) Briefing** ("só carregar o contexto", "onde paramos", "não execute ainda") → o agente carrega
     só o `🔎 Agora` + bloco ativo e **te devolve o estado e PARA**: onde parou, ponto de entrada, gates
     🔁 pendentes, decisões em aberto e qual seria a próxima ação. Zero efeito colateral — nem checkbox,
     nem comando, nem rearmar carga/probe.
   - **(B) Diretivas** ("só a tarefa T3", "pule o X", "use o cluster Y", "sem commit") → ecoa em 1-3
     linhas o que entendeu e como isso muda o ponto de entrada, e executa já sob as diretivas. Sua
     diretiva vence o PLAN no que for operacional.
   - **Conflito com o contrato do bloco** (mexer em DoD, ordem de blocos, pular gate 🔁) → **para** e
     devolve a decisão pra você; não improvisa.
   - Diretivas são **efêmeras**: valem pra sessão, não entram no `PLAN.md` (salvo se você disser que é
     permanente).
1. **Identifica o escopo** pela tabela de escopos do `CLAUDE.md` (se houver mais de um ativo e a
   intenção for ambígua, **pergunta qual**) e lê só o cabeçalho `🔎 Agora` + o bloco ativo do `PLAN.md`
   **daquele** escopo (não relê relatórios, não lê o PLAN de outro escopo).
2. **Determina o papel pelo baton `🎬 Próximo`** — não pergunta se ele existe:
   - `🎬 Próximo: ⚙️ Executor` → sessão de Executor: diz em 2-3 linhas onde parou + ponto de entrada e
     **começa a executar** à risca, marcando checkboxes.
   - `🎬 Próximo: 🧠 Planejador` → entra como Planejador (detalhar/replanejar/handoff).
   - Baton ausente/ambíguo → só aí resume o estado e pergunta o papel.
   O baton define o **papel**; a nota de sessão define **se e como** se executa agora.
3. Reestabelece os **gates por-sessão** (🔁) do ponto de entrada (reverificar DoR, rearmar
   carga/probe/shells). Isso é **pré-condição normal, não retrabalho**. Em modo briefing, não roda.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifica se o bloco está **"executor-ready"** (tarefas atômicas com checagem verificável, decisões
   resolvidas, comandos/paths/valores preenchidos, DoR ok, escalonamento definido).
2. **Mede cada critério de aceite** no commit do handoff e anota o valor observado ao lado do alvo —
   critério deduzido ("o código novo será X, logo o grep dará 0") **nasce falso** e trava o Executor.
3. Ajusta o que faltar no `PLAN.md`.
4. **Grava o baton** no cabeçalho: `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <tarefa>`.
5. **Roda a ✅ Conferência de saída** e **commita** as edições do handoff (senão a próxima sessão lê
   estado do working tree). Reporta o hash.

### `end` — fim de sessão (quando o usuário pedir **ou** ao fechar um bloco inteiro)
1. Gera `docs/sessoes/<escopo>/RELATORIO_<bloco>_<AAAA-MM-DD>.md` na pasta do escopo, pelo template
   compartilhado (detalhe denso: comandos, saídas, números).
2. Atualiza o `PLAN.md` do escopo **in-place** (nunca duplica linhas): Agora, Board, checkboxes,
   registro de sessões. **Se o bloco fechou:** o 🧠 Planejador promove o próximo de rascunho a detalhado
   e replaneja o resto; o ⚙️ Executor só marca 🟢, grava o baton `🧠 Planejador` com o motivo e **para**.
   ⚠️ **"Fechou" exige TODOS os critérios de aceite medidos e batendo** — um só que não bate mantém o
   bloco aberto e vira PARADA + escalonamento, nunca 🟢 "com ressalva".
3. Grava/atualiza o baton `🎬 Próximo` com o papel da próxima sessão.
4. Se o **escopo inteiro** fechou, marca 🟢 na tabela do `CLAUDE.md`. Atualiza ponteiros de memória só
   se algo de alto nível mudou.
5. **Registra o apontamento desta sessão no `resumo-trabalho`** (sempre — o label é o slug, e **o
   índice é a SESSÃO, não o relatório**): toda sessão que termina grava a sua entrada em
   `~/.claude/work-log/<slug>.md` — fechou bloco, parou no meio, fez `handoff` ou só validou. Relatório
   é matéria-prima **quando existe**; quando não existe (handoff e validação nunca geram um), a fonte é
   a linha do registro de sessões + a entrada de decisões + os commits daquela sessão. Idempotência
   pela linha `**Relatório-fonte:**` ou `**Sessão:** <N>`. Log global/append-only, fora do commit.
6. **✅ Conferência de saída** (mecânica, antes do commit; item vermelho = PARADA, não ressalva):
   **⓪ o portão executável `scripts/conferencia_saida.sh <slug> <commit do início da sessão>`, com a
   saída crua colada no resumo** (reprova em linha `🎬` intacta, ponto de entrada já `[x]`, registro de
   sessões sem linha nova, apontamento faltando) · critérios medidos e batendo · a **linha** `🎬 Próximo` coerente com o Board (bloco 🟢 ou tarefa `[x]`
   citada como ponto de entrada = baton podre) · resumos batendo com a linha `🎬` · bloco 🟢 com todas as
   tarefas `[x]` · número do registro de sessões vindo da **própria tabela + 1** (não do nº do
   relatório) · tudo in-place · `git status` sem arquivo alheio · **documento de interface atualizado**
   (se a sessão mudou comportamento que um documento voltado a terceiro descreve — chefe/negócio, DBA,
   README do escopo — ele foi revisado agora ou a pendência tem dono; é o único item cuja falha nenhum
   teste e nenhum grep denunciam).
7. **Commit obrigatório** (relatório + PLAN + mudanças), nas convenções do repo, em cada repo tocado.
   Reporta o(s) hash(es). **Se o commit é destinado a deploy, o `push` sai no mesmo turno** (o CI builda
   do remoto) — e o push **não** é o último elo: bump → commit+push → **job de build** → job de deploy
   *selecionando a versão nova*. Qualquer elo faltando dá o mesmo sintoma silencioso: "deploya e não
   muda nada". Ver "Entrega destinada a deploy" nas Regras invioláveis do `SKILL.md`.

### `help` — este documento
Exibe o guia de uso da skill (subcomandos, papéis, conceitos, ciclo de vida). Não altera nada no
projeto.

## 🔗 Apontamentos automáticos (integração com `resumo-trabalho`)

Se você usa a skill **`resumo-trabalho`** (log de trabalho por card do GitLab + modelo "Apontamentos"),
o `sessao` alimenta esse log **sozinho** — não precisa mais rodar `registrar` à mão a cada bloco, e o
apontamento do dia nunca sai incompleto por esquecimento.

**1. Não há o que ligar — o label É o slug.** O identificador do apontamento é o próprio slug do
escopo: o log dele é `~/.claude/work-log/<slug>.md` e o resumo sai com `/resumo-trabalho gerar <slug>`.
Não existe campo separado, nem escopo "sem label", nem apelido — **um escopo, um nome**, do comando ao
apontamento.

Isso tem uma consequência prática na hora de batizar o escopo: como o log é **global** (vive fora de
qualquer repo), o slug precisa ser único **entre projetos**, não só dentro do repo. Prefira
`aca-amortizacao` a `amortizacao`, `poc-benchmark` a `benchmark` — genérico colide com outro projeto
seu no mês que vem, e aí dois trabalhos diferentes passam a escrever no mesmo apontamento. O
`/sessao init` confere isso (`~/.claude/work-log/`) antes de aceitar o nome.

**2. O que o `end` faz.** Depois de atualizar o PLAN (e gerar o relatório, quando houver), o `end`
grava **uma entrada por sessão** no log do escopo (`~/.claude/work-log/<slug>.md`) — **o índice é a
sessão, não o relatório**. Quando a sessão gerou relatório, ele é a matéria-prima; quando não gerou
(todo `handoff`, toda validação, toda sessão que para no meio de um bloco), a fonte é a linha do
registro de sessões + a entrada de decisões + os commits daquela sessão. Cada entrada carrega
`**Relatório-fonte:** <caminho>` (ou `— sessão sem relatório. Fonte: <...>`) e `**Sessão:** <N>` — são
elas que garantem **idempotência**: rodar o `end` de novo, ou fechar **dois blocos no mesmo dia**,
nunca duplica. Vale tanto no auto-`end` de fechamento de bloco quanto no `end` que você pede.
*Indexar por relatório foi um bug caro:* toda sessão sem relatório sumia do apontamento **sem erro
nenhum**, porque o passo "rodava com sucesso" sem ter o que coletar.

**3. Pegar o apontamento do dia.** `/resumo-trabalho gerar <slug>` (padrão já filtra só hoje) → o
resumo sai **completo**, porque todo relatório fechado no dia já virou entrada. Como o log é global,
dois repos que usem **o mesmo slug** caem no mesmo apontamento — é feature quando é a mesma frente em
dois repos, e é bug quando são trabalhos diferentes com nome genérico. Daí a regra do slug distintivo.

**Bom saber (limites do automático):**
- É **movido a relatório**: só o que virou `RELATORIO_*` do dia entra. Um `end` no meio de um bloco (que
  não gera relatório) não registra nada por si — para anotar algo avulso, use `/resumo-trabalho
  registrar <slug> ...` à mão.
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

- **Um escopo = uma pasta; o protocolo é um só.** Frente nova = `docs/sessoes/<slug>/PLAN.md` novo,
  nunca um segundo protocolo. `AGENTS.md` e o template de relatório são reusados, jamais copiados por
  escopo; nada específico de escopo (branch, ambiente, slug, guardrails da frente) entra no
  `AGENTS.md`. E `init` **nunca sobrescreve** instalação existente.
- **Anti-duplicação:** regras → `AGENTS.md`; estado/plano → `PLAN.md` do escopo; detalhe denso →
  relatórios do escopo; ganchos → memória. Nunca sobe detalhe de relatório pro PLAN.
- **Fronteira de papel = PARADA de sessão:** o Executor **nunca vira Planejador dentro da mesma
  sessão**. Se surgir vontade de (re)planejar (decisão de design, ambiguidade, estado inesperado, DoD
  inalcançável), ele **PARA, grava `🎬 Próximo: 🧠 Planejador` + motivo, e reporta**. Detalhar+executar
  um bloco na mesma sessão de Executor **é violação de protocolo** — e isso inclui promover o próximo
  bloco de rascunho a detalhado no `end`.
- **RELATÓRIO é ato explícito, com uma exceção só:** quando você pedir **ou** no auto-`end` de
  fechamento de bloco (toda a DoD satisfeita). Terminar steps no meio de um bloco não gera relatório —
  aí só atualiza checkboxes e estado. Atualizar o PLAN é contínuo.

## Ciclo de vida típico de uma POC

```
/sessao init        → 1ª vez: AGENTS.md + CLAUDE.md + docs/sessoes/<escopo>/PLAN.md (B1 detalhado,
                      resto rascunho), baton gravado e commit. Escopo novo depois: só a pasta nova.
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

### `start` com nota de sessão — exemplos

```
/sessao start só carrega o contexto de onde paramos, não execute nada ainda
   → briefing: onde parou, ponto de entrada, gates 🔁, decisões abertas, próxima ação. PARA.

/sessao start onde paramos? o cluster tá fora do ar hoje
   → briefing + aponta quais gates/tarefas dependem do cluster e o que dá pra fazer sem ele.

/sessao start pode seguir, mas só as tarefas de código — nada de rodar no cluster, e sem commit
   → ecoa as diretivas, ajusta o ponto de entrada e executa sob elas.

/sessao start pula o bloco B7 e vai pro B8
   → conflito com o contrato (ordem de blocos): PARA e devolve a decisão.

/sessao start benchmark onde paramos?
   → 1º termo = slug do escopo, resto = nota. Entra no PLAN do benchmark e dá o briefing.
```

## Onde a skill vive

A skill é a **fonte canônica** (`~/.claude/skills/sessao/`; `SKILL.md` + `templates/`). Existe um
espelho versionável/compartilhável em `~/workspace/playbook-controle-sessoes/` que sincroniza via
`make sync` (`make check` detecta drift). **Não edite o espelho** — edite na skill.

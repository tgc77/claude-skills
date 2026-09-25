# 📘 Help — Skill `sessao` (Controle de Sessões v2)

> 🔤 **Invocação:** `/sessao <sub>` no **Claude Code**; `$sessao <sub>` ou `@sessao <sub>` no
> **Codex**. Onde este guia escreve `/sessao`, entenda "invoque a skill".
> 📁 **Descoberta:** `~/.claude/skills/` (Claude Code) · `~/.codex/skills/` e `.agents/skills/`
> (Codex). A skill mora num lugar só; os demais caminhos são symlinks.
> 📒 **Log de apontamento:** `<work-log>/<slug>.md`, onde `<work-log>` é `$SESSAO_WORKLOG_DIR` se
> definida, senão `~/.claude/work-log`.

> Documento de uso da skill. Exiba-o quando o usuário rodar `/sessao help` (ou pedir "help/ajuda do
> sessao"). É referência: reproduza o conteúdo relevante, não invente comportamento fora do `SKILL.md`
> — se os dois divergirem, **o `SKILL.md` vence**.

## O que é

Sistema para tocar um **projeto de escopo definido** (sprint, épico, migração, **POC**) com agentes de
I.A., mantendo **cada sessão enxuta de contexto** e **zero perda de continuidade** — mesmo que cada
sessão comece do zero e modelos diferentes assumam o trabalho.

**Princípio único:** cada fato mora em **UM** arquivo; o resto aponta (link), nunca copia. O plano se
detalha em **rolling-wave**: perto em alta resolução, longe em rascunho.

## Quando é acionada

**Só por invocação explícita:** `/sessao`, `$sessao` ou `@sessao`. Ter `AGENTS.md`, um escopo ativo,
uma branch que casa com um PLAN ou um pedido técnico dentro do repo **não** aciona a skill. Para
assumir e operar um escopo existente, o comando é `/sessao start <slug>`; os demais subcomandos fazem
só o que pedem e não autorizam um `start` implícito. No Codex a regra também está em configuração
(`agents/openai.yaml`, `allow_implicit_invocation: false`).

## Layout: um repo, vários escopos

Um repositório dura mais que uma frente de trabalho. **O protocolo é permanente; o plano é por
escopo** — por isso a raiz não cresce a cada feature nova:

```
<repo>/
├── CLAUDE.md                      ← 1 linha: `@AGENTS.md` (o Claude Code não lê AGENTS.md)
├── AGENTS.md                      ← fonte única: protocolo permanente + índice de escopos
├── scripts/
│   └── conferencia_saida.sh       ← lançador do portão (acha a skill e roda o portão dela)
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
| **`AGENTS.md`** (raiz) | **Como trabalhar** (protocolo permanente) + **índice de escopos**. O `CLAUDE.md` só o importa (`@AGENTS.md`) | Sempre (automático) |
| **`docs/sessoes/<escopo>/PLAN.md`** | **Fonte única de verdade viva daquele escopo**: Agora + parâmetros + guardrails + Board + bloco ativo + futuros (rascunho) + decisões + registro de sessões | Sempre — só o cabeçalho + bloco ativo |
| **`docs/sessoes/<escopo>/RELATORIO_<bloco>_<data>.md`** | **Histórico denso** (problema→causa→solução→evidência), 1 por bloco fechado (ou quando você pedir) | Quase nunca — só p/ resgatar detalhe |
| **Memória** | **Ponteiros** de alto nível entre sessões (onde a ferramenta tiver memória automática) | Índice sempre; detalhe sob demanda |

Não existe arquivo de STATUS separado — ele é a primeira seção do `PLAN.md` (`🔎 Agora`).

> **Escoadouro automático:** toda sessão que termina também grava uma entrada no log da skill
> `resumo-trabalho` (`<work-log>/<slug>.md` — o label **é** o slug do escopo). Ver "🔗 Apontamentos
> automáticos" abaixo. Não é um 5º artefato do modelo: é um consumidor a jusante, fora do repo.

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

O slug é **match exato**: nome que não está na coluna `Slug` do índice faz o agente parar e listar os
que existem — ele não "aproxima" para o parecido nem cria escopo por engano.

`/sessao escopos` lista tudo — **slug** (o identificador que se digita) · **escopo** (a descrição) ·
estado · branch · bloco ativo · baton · última atualização — sem alterar nada. É o "onde eu estava?" e
o "quais slugs existem aqui?".

**É seguro ter vários escopos ativos**, desde que **um por vez em cada working tree**: cada escopo tem
baton, board, checkboxes e relatórios próprios, então eles não se atropelam. O que colide é rodar
**duas sessões ao mesmo tempo no mesmo working tree** (arquivos e commits misturados) — para isso,
`git worktree`. Vale igual entre Claude Code e Codex.

> ⚠️ **O PLAN é um arquivo versionado.** Quem determina o estado que você enxerga é a **branch**, não o
> índice. Se cada escopo vive na sua branch, ao entrar em um deles o PLAN do outro pode estar ausente
> ou velho, e vai parecer que o trabalho sumiu. Mantenha `docs/sessoes/**` e o `AGENTS.md` na **branch
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
   linha no índice do `AGENTS.md`; layout legado (PLAN na raiz) → avisa e oferece migrar.
1. Lê os templates necessários (`AGENTS`, `CLAUDE`, `PLAN`).
2. Levanta os `<PLACEHOLDERS>` **com o usuário** (não inventa). **Por escopo:** **slug** (validado:
   kebab-case, inédito no repo e sem colidir com um log já existente em `<work-log>/`) + **descrição**,
   o que fica fora do escopo, blocos iniciais (id + título + tipo 🔧/🔬), **branch de trabalho**,
   ambiente e **guardrails específicos**. **Só na 1ª instalação:** tratamento, idioma, política de
   commit, repos irmãos, guardrails permanentes. Não pergunta pasta de relatórios nem label — ambos
   derivam do slug.
3. **Confirma a estrutura ANTES de criar.** Depois cria: `AGENTS.md`/`CLAUDE.md`, o template de
   relatório e o **lançador** `scripts/conferencia_saida.sh` (só na 1ª vez), e o `PLAN.md` do escopo —
   **detalha só o bloco B1**; os demais ficam em 1 linha marcados `(rascunho)`.
4. **Grava o baton `🎬 Próximo`** (B1 🔬 ou ainda não executor-ready → 🧠 Planejador; B1 🔧 e
   executor-ready → ⚙️ Executor) e **commita a instalação com validação do usuário** — PLAN
   não-commitado faz a próxima sessão ler estado do working tree. Mostra a árvore.

> O lançador **não é uma cópia do portão**: ele acha a skill em tempo de execução
> (`$SESSAO_SKILL_DIR` → `~/.claude/skills/sessao` → `~/.codex/skills/sessao` →
> `<repo>/.agents/skills/sessao`), então toda correção do portão chega aos projetos já instalados. Se
> não achar a skill, sai com **exit 2** — nunca 0: portão que não roda não pode parecer portão que
> passou. Projeto com a cópia antiga do portão (instalado antes de 2026-09-07) deve trocá-la pelo
> lançador.

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
   - **(C) Misto** (contexto + diretiva) → briefing, e só executa se houver ordem explícita de executar.
   - **Conflito com o contrato do bloco** (mexer em DoD, ordem de blocos, pular gate 🔁) → **para** e
     devolve a decisão pra você; não improvisa.
   - Diretivas são **efêmeras**: valem pra sessão, não entram no `PLAN.md` (salvo se você disser que é
     permanente).
1. **Resolve o escopo** (slug → único ativo → branch → pergunta, ver acima), **diz qual assumiu** e lê
   só o cabeçalho `🔎 Agora` + o bloco ativo do `PLAN.md` **daquele** escopo (não relê relatórios, não
   lê o PLAN de outro escopo).
2. **Determina o papel pelo baton `🎬 Próximo`** — não pergunta se ele existe:
   - `🎬 Próximo: ⚙️ Executor` → sessão de Executor: diz em 2-3 linhas onde parou + ponto de entrada e
     **começa a executar** à risca, marcando checkboxes.
   - `🎬 Próximo: 🧠 Planejador` → entra como Planejador (detalhar/replanejar/handoff).
   - Baton ausente/ambíguo → só aí resume o estado e pergunta o papel.
   - ⚠️ **Antes de obedecer, confere se o baton não está podre** — `scripts/conferencia_saida.sh <slug>
     --inicio`. Se ele manda executar tarefa já `[x]` ou cita bloco 🟢/inexistente, **não executa**:
     mostra o que a linha diz × o que o Board diz e pergunta.
   O baton define o **papel**; a nota de sessão define **se e como** se executa agora.
3. Reestabelece os **gates por-sessão** (🔁) do ponto de entrada (reverificar DoR, rearmar
   carga/probe/shells). Isso é **pré-condição normal, não retrabalho**. Em modo briefing, não roda.

**O Executor não escolhe quando parar.** Uma sessão de Executor é um **loop contínuo sobre o bloco
ativo**: terminou uma tarefa, valida, marca e começa a próxima. "Bom checkpoint", muito trabalho feito
ou contexto grande **não** são motivos para parar. As condições terminais são uma lista fechada:
(1) o bloco inteiro satisfez a DoD → auto-`end`; (2) a realidade divergiu do contrato ou falta decisão
de design; (3) um critério de aceite mediu diferente do alvo; (4) falta autorização externa; (5) você
interrompeu ou mandou parar; (6) limite técnico real da ferramenta. Nas condições 2, 3, 4 e 6 ele
**registra a sessão** (3ª porta do `end`) e para.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifica se o bloco está **"executor-ready"** (tarefas atômicas com checagem verificável, decisões
   resolvidas, comandos/paths/valores preenchidos, DoR ok, escalonamento definido). Se o bloco muda
   comportamento descrito num **documento de interface** (chefe/negócio, DBA, README do escopo), a
   atualização dele entra como **tarefa do bloco**, com o arquivo nomeado.
2. **Mede cada critério de aceite** no commit do handoff e anota o valor observado ao lado do alvo —
   critério deduzido ("o código novo será X, logo o grep dará 0") **nasce falso** e trava o Executor.
3. Ajusta o que faltar no `PLAN.md` do escopo.
4. **Grava o baton** no cabeçalho — `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <tarefa>` — e
   **acrescenta a linha da sessão ao registro de sessões (§8)**.
5. **Mostra o plano e pede o seu aceite** (e, com ele, a validação do commit). Aceito, registra
   `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)` no bloco. **Responder às perguntas do agente não é
   aceitar o plano.** Sem o "ok", nada é commitado nem registrado.
6. **Registra o apontamento da sessão** no `resumo-trabalho` — handoff é sessão como qualquer outra.
7. **Roda o portão** (✅ Conferência de saída) — agora, com o apontamento já no lugar.
8. **Commita** e reporta o hash. `push` é pedido à parte.

### `end` — fim de sessão (3 portas: você pedir · o bloco fechar · **PARADA no meio do bloco**)

**O ritual tem duas metades com gatilhos diferentes.** O **relatório** (passo 1) só sai quando o bloco
fecha, ou quando você pede. O **registro da sessão** (passos 2–6: PLAN in-place, linha no registro de
sessões, baton, validação → apontamento → portão → commit) sai em **toda** sessão que termina —
inclusive quando o Executor **PARA no meio do bloco** por condição terminal (critério que não bateu,
decisão de design ausente, estado inesperado, autorização faltando, limite técnico). Nessa 3ª porta ele
auto-dispara o registro **sem** você pedir e **sem** relatório. *Parar não dispensa registrar:
sessão sem linha no registro de sessões não existe para a próxima.*

1. **Relatório** (só se o bloco fechou ou você pediu): `docs/sessoes/<escopo>/RELATORIO_<bloco>_<AAAA-MM-DD>.md`
   — ou o padrão declarado na linha `Relatórios` do PLAN —, pelo template compartilhado (detalhe
   denso: comandos, saídas, números).
2. Atualiza o `PLAN.md` do escopo **in-place** (nunca duplica linhas): Agora, Board, checkboxes, e
   **uma linha nova no fim do registro de sessões**. **Se o bloco fechou:** o 🧠 Planejador promove o
   próximo de rascunho a detalhado e replaneja o resto; o ⚙️ Executor só marca 🟢, grava o baton
   `🧠 Planejador` com o motivo e **para**.
   ⚠️ **"Fechou" exige TODOS os critérios de aceite medidos e batendo** — um só que não bate mantém o
   bloco aberto e vira PARADA + escalonamento, nunca 🟢 "com ressalva".
3. Grava/atualiza o baton `🎬 Próximo` com o papel da próxima sessão.
4. Se o **escopo inteiro** fechou, marca 🟢 na tabela do `AGENTS.md`. Atualiza ponteiros de memória só
   se algo de alto nível mudou (e só onde a ferramenta tem memória automática).
5. **Registra o apontamento** — **só depois de você validar o commit** (passo 6). Uma sessão = uma
   entrada em `<work-log>/<slug>.md`, com a linha `**Sessão:** <chave>` (ver "🔗 Apontamentos
   automáticos"). O log é append-only e fora do repo: apontamento gravado sobre trabalho que você
   rejeitou vira histórico falso que nenhum `git reset` desfaz.
6. **Commit SOMENTE com a sua validação explícita.** O agente apresenta o que foi feito e pergunta se
   pode commitar; sem o "ok", tudo fica no working tree. Com o "ok", **nesta ordem**: escreve o
   apontamento (passo 5) → roda o portão → commita, **só o que é deste escopo e desta sessão** (nada de
   `git add -A` cego), em cada repo tocado, na branch de trabalho do PLAN. Reporta o(s) hash(es).
   **`push` também exige validação, pedida à parte — inclusive para deploy.**

> **Entrega destinada a deploy:** o agente **pede** o push no mesmo turno do commit (sem ele o CI
> builda do remoto e o deploy "não muda nada") — mas **espera** o seu aval. E o push não é o último
> elo: bump de versão → commit+push → **job de build** → job de deploy **selecionando a versão nova**.
> Qualquer elo faltando dá o mesmo sintoma silencioso.

### ✅ Conferência de saída (antes de todo commit de `end`/`handoff`)

Mecânica, não subjetiva; **vermelho é PARADA**, nunca "ressalva no relatório".

**⓪ O portão executável** — `scripts/conferencia_saida.sh <slug> <commit em que a sessão começou>`,
com a saída crua colada no resumo. Ele reprova (exit 1) em seis casos:

| Item | Reprova quando |
|---|---|
| ① | a linha `🎬 Próximo` falta ou está duplicada |
| ② | o parágrafo do baton (a linha + continuações indentadas) está **intacto** desde o início da sessão — o baton foi só narrado, não passado |
| ③ | o ponto de entrada citado no baton é tarefa já `[x]` (baton podre) |
| ④ | o registro de sessões (§8) não ganhou linha nova |
| ⑤ | alguma linha nova do §8 não tem a **sua** chave `**Sessão:**` no log de apontamento |
| ⑥ | a sessão escreveu contrato de bloco e passou o baton para ⚙️ **sem** uma linha `**Aceite:**` nova |

**Na mão** (nenhum comando enxerga): (1) critérios de aceite medidos e batendo · (2) a linha `🎬` certa
para depois desta sessão · (3) resumos batendo com a linha `🎬` · (4) bloco 🟢 com todas as tarefas
`[x]` · (5) chave da sessão vinda do arquivo · (6) tudo in-place · (7) `git status` sem arquivo alheio ·
(8) **documento de interface atualizado** · (9) **nenhuma decisão pendente selada por fora**.

### `help` — este documento
Exibe o guia de uso da skill (subcomandos, papéis, conceitos, ciclo de vida). Não altera nada no
projeto.

## 🔗 Apontamentos automáticos (integração com `resumo-trabalho`)

Se você usa a skill **`resumo-trabalho`** (log de trabalho por card do GitLab + modelo "Apontamentos"),
o `sessao` alimenta esse log **sozinho** — não precisa rodar `registrar` à mão, e o apontamento do dia
não sai incompleto por esquecimento.

**1. Não há o que ligar — o label É o slug.** O log do escopo é `<work-log>/<slug>.md` e o resumo sai
com `/resumo-trabalho gerar <slug>`. Não existe campo separado, nem escopo "sem label", nem apelido —
**um escopo, um nome**, do comando ao apontamento.

Isso tem uma consequência prática na hora de batizar o escopo: como o log é **global** (vive fora de
qualquer repo), o slug precisa ser único **entre projetos**, não só dentro do repo. Prefira
`aca-amortizacao` a `amortizacao`, `poc-benchmark` a `benchmark` — genérico colide com outro projeto
seu no mês que vem, e aí dois trabalhos diferentes passam a escrever no mesmo apontamento. O
`/sessao init` confere isso antes de aceitar o nome.

**2. Uma sessão = uma entrada.** `end`, `handoff` **e** toda PARADA no meio de bloco gravam a entrada
da sessão — **o índice é a sessão, não o relatório**. Quando houve relatório, ele é a matéria-prima;
quando não houve (todo handoff, toda validação, toda parada), a fonte é a linha do registro de
sessões + a entrada de decisões + os commits daquela sessão. Nada é inventado fora dessas fontes.
*Indexar por relatório foi um bug caro:* toda sessão sem relatório sumia do apontamento **sem erro
nenhum**.

**3. A chave da sessão.** Cada entrada carrega, logo abaixo do cabeçalho `## [data hora] <projeto>`:

```
**Relatório-fonte:** docs/sessoes/<slug>/RELATORIO_B5_2026-09-24.md   (ou "— sessão sem relatório. Fonte: …")
**Sessão:** 2026-09-24#2 · B5 (⚙️ Executor)
```

A chave (logo depois de `**Sessão:**`) sai da linha da sessão no §8 do PLAN: numa tabela com coluna de
número, é o **número** (`11`); na tabela do template atual, é `<AAAA-MM-DD>#<k>`, com k = posição da
linha entre as de mesma data (`#1` = 1ª sessão do dia). É ela que torna o registro **idempotente** —
rodar o `end` de novo nunca duplica — e é ela que o item ⑤ do portão confere, sessão por sessão.
Por isso o §8 é append-only: cada sessão acrescenta a sua linha no fim.

**4. Pegar o apontamento do dia.** `/resumo-trabalho gerar <slug>` (o padrão já filtra só hoje) → sai
**completo**, porque toda sessão encerrada no dia já virou entrada. Pedido de resumo feito dentro de
um escopo é **daquele** escopo: "hoje" filtra a data dentro do slug, nunca vira varredura de todos os
logs (`gerar dia` só com pedido explícito de agregar todos os cards).

**Bom saber:**
- O log é **append-only** e **global** (`<work-log>/`), fora do repo — **não** entra no commit.
- Ele só é escrito **depois** de você validar o commit.
- Para anotar algo avulso, fora de uma sessão, use `/resumo-trabalho registrar <slug> ...`.

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
  sessão. `init`/`handoff`/`end` gravam, `start` lê e age sem perguntar. **O baton é a linha, não a
  prosa:** escrever "baton → 🧠" no resumo ou no commit e deixar a linha velha faz a próxima sessão
  refazer trabalho pronto — é o que o item ② do portão pega.
- **Gate por-sessão (🔁) × marco (`[ ]`):** um **marco** persiste (medição/entrega → checkbox `[x]` +
  relatório). Um **gate 🔁** é processo vivo que **não** sobrevive entre sessões (DoR, armar
  carga/probe/shells) e é reestabelecido toda sessão — **não é retrabalho nem estado perdido**.
- **Aceite:** linha `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)` no bloco, escrita só depois de o
  plano ser mostrado e aceito. O `(bloco <id>)` é obrigatório: sem ele, dois blocos aceitos pela mesma
  pessoa no mesmo dia geram linhas idênticas e o portão não vê o segundo aceite.

## Regras invioláveis

- **Questionamento aberto = registro congelado.** Quando você questiona, discorda ou pede para validar
  algo, o agente **para de escrever**: nada entra em PLAN, AGENTS, relatório, memória ou commit até
  você concordar **com tudo**. Silêncio não é aval; responder às perguntas do agente não é aceitar o
  plano. Se ele já tiver registrado antes do aval, diz isso na 1ª frase e oferece desfazer.
- **Um escopo = uma pasta; o protocolo é um só.** Frente nova = `docs/sessoes/<slug>/PLAN.md` novo,
  nunca um segundo protocolo. `AGENTS.md` e o template de relatório são reusados, jamais copiados por
  escopo; nada específico de escopo (branch, ambiente, slug, guardrails da frente) entra no
  `AGENTS.md`. E `init` **nunca sobrescreve** instalação existente.
- **Anti-duplicação:** regras → `AGENTS.md`; estado/plano → `PLAN.md` do escopo; detalhe denso →
  relatórios do escopo; ganchos → memória. Nunca sobe detalhe de relatório pro PLAN.
- **Fronteira de papel = PARADA de sessão:** o Executor **nunca vira Planejador dentro da mesma
  sessão**. Se surgir vontade de (re)planejar (decisão de design, ambiguidade, estado inesperado, DoD
  inalcançável), ele **PARA, grava `🎬 Próximo: 🧠 Planejador` + motivo, registra a sessão e reporta**.
  Detalhar+executar um bloco na mesma sessão de Executor **é violação de protocolo** — e isso inclui
  promover o próximo bloco de rascunho a detalhado no `end`.
- **Relatório é ato explícito, com uma exceção só:** quando você pedir **ou** no auto-`end` de
  fechamento de bloco (toda a DoD satisfeita). **Não gerar relatório nunca significa não registrar a
  sessão.**
- **Commit e push só com validação explícita**, pedida a cada vez — sem exceção, nem para deploy.

## Ciclo de vida típico de uma POC

```
/sessao init        → 1ª vez: AGENTS.md (+ CLAUDE.md de 1 linha) + lançador do portão +
                      docs/sessoes/<escopo>/PLAN.md (B1 detalhado, resto rascunho), baton gravado,
                      commit com o seu ok. Escopo novo depois: só a pasta nova.
   │
   ▼  (modelo forte planeja B1)
/sessao handoff     → deixa B1 executor-ready, mede os critérios, mostra o plano; com o seu aceite:
                      baton ⚙️ Executor, apontamento, portão, commit
   │
   ▼  (troca p/ modelo barato)
/sessao start       → confere o baton (--inicio), executa B1 à risca, em loop, até condição terminal
   │                  (bloco fechou → auto-end: relatório + PLAN + baton 🧠; pede o ok do commit)
   ▼  (fronteira: B1 fechou, B2 estava rascunho → baton vira 🧠 Planejador)
/sessao start       → entra como Planejador, detalha B2, replaneja o resto → handoff
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

/sessao start poc-benchmark onde paramos?
   → 1º termo = slug do escopo, resto = nota. Entra no PLAN do poc-benchmark e dá o briefing.
```

## Onde a skill vive

A skill é a **fonte canônica** (`~/.claude/skills/sessao/`: `SKILL.md`, `HELP.md`, `templates/`,
`scripts/`, `agents/openai.yaml`), versionada no repositório `tgc77/claude-skills`. O antigo espelho
`~/workspace/playbook-controle-sessoes/` foi **aposentado** em 2026-09-24 — não há mais nada a
sincronizar. Mexeu no portão ou nos templates? Rode `scripts/autoteste_portao.sh` antes de commitar.

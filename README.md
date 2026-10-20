# claude-skills

Duas skills para agentes de código (**Claude Code** e **Codex**) que trabalham juntas para tocar
projetos longos com I.A. sem perder o fio entre sessões — e sem perder o registro do que foi feito:

| Skill | Para que serve | Como é acionada |
|---|---|---|
| [`sessao`](sessao/) | **Controle de Sessões.** Organiza um projeto de escopo definido em blocos, com um `PLAN.md` por escopo como fonte única de verdade, um protocolo Planejador/Executor e um portão executável que impede fechar a sessão com registro inconsistente. | **Só explícita:** `/sessao <sub>` (Claude Code), `$sessao` ou `@sessao` (Codex). |
| [`resumo-trabalho`](resumo-trabalho/) | **Apontamentos.** Mantém um log de trabalho por card do GitLab, fora de qualquer repo, e gera o resumo no modelo "Apontamentos" (markdown GitLab, pt-BR), escrito para ser lido pela chefia. | Por comando (`/resumo-trabalho <sub>`) ou por pedido em linguagem natural ("resumo do card X", "apontamentos"). |

Elas se encontram num ponto só: **o slug de um escopo do `sessao` é o label de um log do
`resumo-trabalho`**. Toda sessão que termina grava a sua entrada nesse log, e o resumo do dia sai
completo com um comando.

**A divisão do trabalho, em uma frase:** você digita os comandos `/sessao …` e valida o que o agente
mostra; o agente planeja com você, executa, registra, confere e commita, e para em cada ponto que
depende de você. Para começar: [Instalação](#instalação), [Primeiros passos](#primeiros-passos) e
[Quem faz o quê](#quem-faz-o-quê).

---

## Sumário

- [Instalação](#instalação)
- [Primeiros passos](#primeiros-passos)
- [Quem faz o quê](#quem-faz-o-quê)
- [Configuração](#configuração)
- [Skill `sessao`](#skill-sessao)
- [Skill `resumo-trabalho`](#skill-resumo-trabalho)
- [Como as duas se integram](#como-as-duas-se-integram)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Manutenção](#manutenção)
- [Versionamento](#versionamento)

---

## Instalação

Uma vez por máquina, em dois passos, os dois com você.

**1. As skills.** A raiz deste repositório **é** o diretório de skills do Claude Code. Cada skill mora
em um lugar só; as outras ferramentas enxergam a mesma cópia por symlink.

```bash
# Claude Code — o repositório é o próprio diretório de skills
git clone git@github.com:tgc77/claude-skills.git ~/.claude/skills

# Codex — symlinks para a mesma cópia (nada de copiar arquivos)
mkdir -p ~/.codex/skills
ln -s ~/.claude/skills/sessao          ~/.codex/skills/sessao
ln -s ~/.claude/skills/resumo-trabalho ~/.codex/skills/resumo-trabalho
```

**2. O CLI do OpenSpec**, sem o qual não se abre escopo novo: o `/sessao init` confere e, se ele
faltar, para e mostra como instalar. O passo a passo — Node ≥ 20.19, o CLI na versão mínima, a
conferência de assinaturas e a telemetria desligada — está em
[`sessao/referencia/openspec.md`](sessao/referencia/openspec.md#ambiente--uma-vez-por-máquina). O
resto do ambiente, o schema da skill ligado ao OpenSpec, o agente aplica no `init`, com o seu ok.

- Uma skill nova só aparece para o Claude Code numa **sessão nova**, não na sessão em que foi instalada.
- O Codex também reconhece `.agents/skills/`. Um symlink `~/.agents/skills → ~/.claude/skills` funciona,
  e o lançador do portão procura em `<repo>/.agents/skills/sessao` quando a skill está vendorizada no
  próprio projeto.
- **Leve `sessao/agents/openai.yaml` junto** se mover, clonar ou empacotar a skill `sessao`: é ele que
  impede a invocação implícita no Codex (`allow_implicit_invocation: false`). Sem ele sobra só o texto
  do `SKILL.md`, e texto sozinho não impede nada.
- `synced/` está no `.gitignore`: é o cache em que o Claude Code baixa as skills da conta
  (`anthropic-skills:*`), não conteúdo deste repositório.

**Requisitos dos scripts:** `bash`, `git`, `grep -E`, `sed` e `awk` (o `mawk` basta) para o portão;
`python3` e GNU `sed`/`date` também para o autoteste; Node ≥ 20.19 e o CLI `openspec` ≥ 1.14.3 para o
módulo OpenSpec.

## Primeiros passos

Um **escopo** é uma frente de trabalho com começo e fim — uma migração, uma feature, uma POC —,
dividida em **blocos** de 2 a 4 horas. Ele tem um **slug**, o nome dele em kebab-case (ex.:
`upgrade-postgres-16`), e um `PLAN.md` próprio, que guarda o plano e onde o trabalho parou. Cada
sessão (uma conversa com o agente) assume um de dois papéis: 🧠 **Planejador**, que detalha o próximo
bloco, ou ⚙️ **Executor**, que o executa. Quem diz o papel da sessão seguinte é o **baton**, uma linha
do PLAN que o próprio agente grava.

Os comandos abaixo são os do Claude Code; no Codex, troque `/sessao` por `$sessao`.

1. **Abra o escopo.** No repositório do projeto, numa sessão nova:

   ```text
   /sessao init
   ```

   O agente pergunta o slug, a descrição, o que fica fora, os blocos iniciais, a branch de trabalho, o
   ambiente e os guardrails; na primeira vez naquele repositório, também como tratar você, o idioma, a
   política de commit e os repos irmãos. **Você** responde, confere a estrutura que ele mostra e dá o
   "ok" para criar; depois, outro "ok" para o commit. Num repositório que já usa a skill, o `init` só
   acrescenta o escopo novo.

2. **Feche o plano do primeiro bloco**, com um modelo forte — pode ser na mesma sessão do `init`:

   ```text
   /sessao handoff upgrade-postgres-16
   ```

   O agente deixa o bloco **executor-ready**: tarefas atômicas, cada critério de aceite medido, as
   decisões de design resolvidas com você e, se o bloco muda um comportamento de que alguém depende,
   uma change do OpenSpec com a proposta e o delta das specs. Ele mostra o plano; **você lê e dá o
   aceite**. Só o aceite libera o commit: responder às perguntas dele não conta. Se o `init` já deixou
   o bloco executor-ready, com o baton em ⚙️, pule para o passo 3.

3. **Execute**, numa **sessão nova** e com um modelo mais barato:

   ```text
   /sessao start upgrade-postgres-16
   ```

   O baton diz ⚙️ Executor. O agente executa o bloco inteiro em loop, marcando as tarefas, sem pedir
   licença a cada passo. Ele só para quando o bloco fecha ou quando precisa de você — decisão de design
   fora do plano, critério de aceite que não bateu, autorização que falta. Nos dois casos ele encerra a
   sessão sozinho (é o `end`) e pede o seu "ok" para commitar.

4. **Valide.** Responda "ok", ou peça ajustes. Com o ok, o agente grava o apontamento, roda o portão e
   commita. `push` só quando você pedir, à parte.

5. **Repita a partir do `start`**, sempre numa sessão nova: com o baton em 🧠, o Planejador detalha o
   próximo bloco e você fecha o plano com `/sessao handoff`; com o baton em ⚙️, o Executor executa. Não
   lembra de quem é a vez? `/sessao escopos` mostra o baton de cada escopo.

6. **Apontamento do dia:** `/resumo-trabalho gerar upgrade-postgres-16` entrega o resumo pronto para
   colar no card.

Para encerrar uma sessão no meio, peça `/sessao end`: o agente registra onde parou e pede o ok para
commitar, como no fim de um bloco.

## Quem faz o quê

Você conduz com comandos e validações; o trabalho de registro é do agente, que segue a skill sem você
pedir. Os scripts de `sessao/scripts/` também são do agente: você não precisa rodá-los.

| Momento | Você | O agente, sozinho |
|---|---|---|
| **Uma vez por máquina** | Instala as skills e o CLI do OpenSpec ([Instalação](#instalação)). | No `init`, confere o ambiente do OpenSpec e liga o schema da skill, com o seu ok. |
| **Abrir um escopo** | `/sessao init`; responde slug, blocos, branch, ambiente e guardrails; dá o ok para criar e para commitar. | Confere se o slug é único. Na 1ª vez no repositório, cria `AGENTS.md`, `CLAUDE.md`, o lançador do portão e o template de relatório; em todo escopo novo, o `PLAN.md` com o 1º bloco detalhado, a linha no índice, a pasta `openspec/` (se faltar) e o baton. |
| **Começar uma sessão** | Abre uma sessão nova, escolhe o modelo — forte para 🧠, mais barato para ⚙️ — e digita `/sessao start <slug>`. | Lê o estado do escopo, confere o baton e assume o papel que ele manda, sem perguntar. |
| **Planejar (🧠)** | Responde às decisões de design, pede `/sessao handoff`, lê o plano e dá o aceite. | Detalha o bloco, mede os critérios de aceite, cria e valida a change do OpenSpec, grava o contrato, o aceite e o baton ⚙️. |
| **Executar (⚙️)** | Acompanha. Pode interromper, ou pedir `/sessao end` para encerrar no meio. | Executa o bloco em loop e marca as tarefas; quando a realidade diverge do plano, para e devolve ao Planejador. |
| **Fechar a sessão** | Dá o ok para o commit, ou pede ajustes; pede o `push` à parte. | Dispara o `end` ao fechar o bloco ou ao parar; atualiza PLAN, baton e registro de sessões; gera o relatório se o bloco fechou e arquiva a change; com o ok, grava o apontamento, roda o portão e commita. |
| **Apontamento do dia** | `/resumo-trabalho gerar <slug>` e cola o resultado no card. | Já gravou uma entrada no log para cada sessão. |
| **A skill mudou** | `/sessao update` em cada projeto, quando o CHANGELOG pedir. | Sincroniza o bloco gerenciado do `AGENTS.md`, o lançador e o ambiente do OpenSpec; commita com o seu ok. |

- **O agente nunca faz sem o seu ok:** commit, `push` e a entrada no log de apontamentos. E nunca dá o
  aceite de um plano por você, não instala ferramenta e não escolhe o escopo quando você não deu o
  slug: mostra o que falta e pergunta.
- **Você não precisa fazer à mão:** editar o PLAN, o baton ou o registro de sessões; rodar o portão;
  escrever no log; criar, validar ou arquivar a change do OpenSpec.
- **O modelo é escolha sua:** a skill não troca de modelo, e o baton só diz o papel. Um modelo só também
  funciona; a divisão compensa quando executar custa muito mais que planejar.
- **O merge também:** o PLAN e o `AGENTS.md` precisam viver na branch base compartilhada. Mergeie cedo
  e com frequência, senão um escopo que está em outra branch parece ter sumido.
- **Uma sessão por working tree:** duas sessões ao mesmo tempo no mesmo diretório colidem em arquivos e
  commits. Para trabalhar em paralelo, use `git worktree`.

## Configuração

Nenhuma variável é obrigatória.

| Variável | Padrão | Para que serve |
|---|---|---|
| `SESSAO_WORKLOG_DIR` | `~/.claude/work-log` | Diretório do log de apontamentos, **compartilhado pelas duas skills**. Um arquivo por label/slug. |
| `SESSAO_SKILL_DIR` | — (sem padrão) | Onde o lançador do portão procura a skill `sessao` antes dos caminhos padrão (CI, instalação fora do padrão). |
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Respeitada pelo lançador ao procurar `skills/sessao`. |
| `CODEX_HOME` | `~/.codex` | Idem, para a instalação do Codex. |
| `SESSAO_OPENSPEC_BIN` | `openspec`, do `PATH` | O CLI do OpenSpec que o portão e o `openspec_ambiente.sh` chamam. |
| `XDG_DATA_HOME` | `~/.local/share` | Base do symlink do schema `sessao` (`openspec/schemas/sessao`); o OpenSpec a respeita também. |

O log fica no diretório do Claude Code só por histórico: é um endereço de arquivo, e qualquer
ferramenta lê e escreve nele.

---

## Skill `sessao`

> Referência: [`sessao/SKILL.md`](sessao/SKILL.md) (o roteador e as regras invioláveis),
> [`sessao/subcomandos/`](sessao/subcomandos/) e [`sessao/referencia/`](sessao/referencia/) — juntos, o
> protocolo e a **fonte canônica**. [`sessao/HELP.md`](sessao/HELP.md) é o índice que `/sessao help`
> mostra; [`sessao/HISTORICO.md`](sessao/HISTORICO.md) guarda o porquê de cada regra.

### A ideia

Cada sessão com um agente começa com o contexto zerado. O `sessao` põe a continuidade **nos
arquivos**, não na conversa, com uma regra só: **cada fato mora em um arquivo; o resto aponta, nunca
copia.** O plano se detalha em *rolling-wave*: o bloco ativo em alta resolução, os distantes em uma
linha de rascunho. E o trabalho é dividido entre dois papéis:

- 🧠 **Planejador** (modelo forte) — na fronteira de cada bloco, detalha o próximo até ficar
  "executor-ready", resolve as decisões de design, **mede** cada critério de aceite e escreve o
  contrato de execução. Não implementa.
- ⚙️ **Executor** (modelo barato) — executa o bloco à risca, em loop, até uma condição terminal de uma
  lista fechada. Não toma decisão de design: se a realidade divergir do plano, **para e devolve** ao
  Planejador.

Quem diz qual papel a próxima sessão assume é o **baton** — a linha `🎬 Próximo:` do cabeçalho do
PLAN, que o agente grava ao fim de cada sessão. O `start` lê essa linha e age sem perguntar.

### O que ela instala num projeto

Tudo isto o `init` cria; você não copia nada à mão.

```text
<repo>/
├── CLAUDE.md                  ← `@AGENTS.md` (o Claude Code não lê AGENTS.md) + instruções só dele, se houver
├── AGENTS.md                  ← índice de escopos + regras do projeto + bloco gerenciado (lido pelo Codex e, via import, pelo Claude)
├── scripts/
│   └── conferencia_saida.sh   ← LANÇADOR do portão: acha a skill e roda o portão dela
├── openspec/                  ← specs vivas (módulo OpenSpec): specs/ do comportamento e changes/ dos blocos
└── docs/sessoes/
    ├── template-relatorio.md  ← um por repo, reusado por todo escopo
    └── <slug>/                ← um escopo = uma pasta
        ├── PLAN.md            ← fonte única de verdade daquele escopo
        └── RELATORIO_<bloco>_<AAAA-MM-DD>.md
```

**O protocolo mora na skill; o plano é por escopo.** O `AGENTS.md` do projeto guarda só o índice, as
regras do próprio projeto e um **bloco gerenciado** curto (entre `<!-- sessao:inicio` e
`<!-- sessao:fim -->`), que o `/sessao update` mantém igual ao template: a ativação explícita e duas
regras que valem em qualquer sessão, com ou sem a skill — questionamento aberto congela o registro, e
identificador sozinho não é contexto. Cópia de protocolo congela na versão do dia em que foi feita.
Uma frente de trabalho nova é só uma pasta nova com um `PLAN.md` e uma linha no índice. ⛔ **Nunca**
use `AGENTS.override.md`: no Codex ele *substitui* o `AGENTS.md` em vez de somar.

**Specs vivas (módulo OpenSpec, desde a 3.1.0).** O `PLAN.md` guarda a execução; o que o sistema faz
fica em `openspec/specs/`, mantido pelo [OpenSpec](https://github.com/Fission-AI/OpenSpec). Todo escopo
novo nasce com o módulo, e o contrato de cada bloco declara a sua **change** (proposta + delta das
specs, validada antes do aceite e arquivada quando o bloco conclui) ou `não se aplica — <motivo>`. O
agente cria, valida e arquiva a change; você a lê junto com o plano, no aceite. A skill usa só o CLI,
com a telemetria sempre desligada, e um schema próprio sem lista de tarefas: as tarefas continuam no
PLAN. Detalhes em [`sessao/referencia/openspec.md`](sessao/referencia/openspec.md).

O **slug** é o identificador único do escopo: nome da pasta, argumento dos comandos e label do
apontamento. Sem apelidos, em kebab-case, e **único entre projetos** (o log é global): prefira
`upgrade-postgres-16` a `upgrade`.

### Subcomandos

Sintaxe: `/sessao <subcomando> [<slug>] [<texto livre>]`. O escopo é **argumento, não estado**, e nunca
é deduzido: o `start` exige o slug escrito; `handoff` e `end` operam o escopo do `start` da sessão ou o
slug passado; sem slug, o agente lista os escopos e pergunta.

| Subcomando | Quem dispara | O que faz | Altera o repo? |
|---|---|---|---|
| `escopos [<slug>]` | você | Lista os escopos (slug, descrição, estado, branch, bloco ativo, baton, última atualização) e avisa inconsistências de identidade. | Não |
| `help` | você | Mostra o [`HELP.md`](sessao/HELP.md). | Não |
| `init` | você | Abre um escopo: instala o sistema num repo virgem, ou só cria a pasta do escopo novo num repo já instalado. Levanta os dados **com você**, confirma a estrutura antes de criar e prepara o OpenSpec. | Sim, com o seu ok |
| `start <slug> [nota]` | você, a cada sessão | Início de sessão: lê o estado do escopo pelo portão (`--estado`, em JSON) e o bloco ativo, confere se o baton não está podre e assume o papel que ele manda. A nota pode pedir só um briefing ("onde paramos?") ou impor diretivas ("só as tarefas de código, sem commit"). | Conforme o papel |
| `handoff` | você, para fechar o planejamento | Planejador → Executor: deixa o bloco executor-ready, mede os critérios, declara a change do OpenSpec e mostra o plano; com o seu **aceite**, grava o baton e o apontamento, roda o portão e commita. | Sim, com o seu aceite |
| `end` | o Executor, sozinho, quando o bloco fecha ou para; você, para encerrar no meio | Fim de sessão (ver abaixo). | Sim, com o seu ok |
| `update` | você, quando o CHANGELOG pedir | Põe o projeto em dia com a skill: sincroniza o bloco gerenciado do `AGENTS.md` (`scripts/bloco_agents.sh`), troca a cópia antiga do portão pelo lançador, confere o `CLAUDE.md` e o ambiente do OpenSpec. | Sim, com o seu ok |

### Ciclo de vida

```mermaid
flowchart TD
    init["/sessao init<br/>estrutura + PLAN com B1 detalhado"] -->|"baton 🧠"| handoff
    handoff["/sessao handoff<br/>B1 executor-ready + o seu aceite"] -->|"baton ⚙️"| exec
    exec["/sessao start #lt;slug#gt;<br/>o Executor executa o bloco em loop"] --> term{"condição<br/>terminal"}
    term -->|"bloco fechou"| fecha["auto-end: relatório + registro<br/>pede o seu ok para commitar"]
    term -->|"parada no meio"| para["registro sem relatório<br/>pede o seu ok para commitar"]
    fecha -->|"último bloco"| fim["escopo 🟢 no índice<br/>a pasta fica como histórico"]
    fecha -->|"baton 🧠"| plan["/sessao start #lt;slug#gt;<br/>o Planejador detalha o próximo bloco"]
    para -->|"baton 🧠"| plan
    plan --> handoff
```

### Como uma sessão fecha

O ritual de fim tem **duas metades**: o **relatório** só sai quando o bloco fecha (ou quando você pede);
o **registro da sessão** — PLAN atualizado in-place, uma linha nova no registro de sessões (§8),
baton — sai em **toda** sessão que termina, inclusive quando o Executor para no meio de um bloco.

Quem conduz o ritual é o agente; a validação é sua, e é o eixo. A ordem:

1. O agente prepara tudo no working tree: PLAN, baton, §8, o relatório, se houver, e — se o bloco
   concluiu com uma change do OpenSpec — o `openspec archive` dela.
2. Ele mostra o que fez e **pede a sua validação**. Sem o seu "ok", **para**: nada de commit, nada de
   log.
3. Com o "ok", grava o **apontamento** no log (ver [integração](#como-as-duas-se-integram)).
4. Roda o **portão**.
5. **Commita** só o que é daquele escopo e daquela sessão. `push` só quando você pedir, à parte —
   inclusive para deploy.

O log vem depois do aval porque é append-only e fica fora do repo: um apontamento gravado sobre
trabalho que você rejeitou vira histórico falso que nenhum `git reset` desfaz.

### O portão (`scripts/conferencia_saida.sh`)

As regras de fechamento já existiam em prosa e falharam mesmo assim, em sessões que relataram tudo com
honestidade: uma checklist que o próprio agente declara ter cumprido mede a intenção dele, não o
arquivo. O portão mede o arquivo, e **vermelho é PARADA**, não ressalva no relatório.

Quem roda é o agente, antes de todo commit de fechamento, e ele cola a saída crua no resumo da sessão.
Você não precisa rodá-lo, mas pode, para conferir:

```bash
scripts/conferencia_saida.sh <slug> <commit em que a sessão começou>   # fechamento: itens ①-⑦
scripts/conferencia_saida.sh <slug> --inicio                           # início: o baton está coerente?
scripts/conferencia_saida.sh <slug> --estado                           # o --inicio + o estado do escopo em JSON
```

| Item | Reprova (exit 1) quando |
|---|---|
| ① | a linha `🎬 Próximo` falta ou está duplicada |
| ② | o parágrafo do baton está **intacto** desde o início da sessão — o baton foi narrado, não passado |
| ③ | o baton manda executar uma tarefa já `[x]` (baton podre) |
| ④ | o registro de sessões (§8) não ganhou linha nova |
| ⑤ | alguma linha nova do §8 não tem a **sua** chave `**Sessão:**` no log de apontamento |
| ⑥ | a sessão escreveu contrato de bloco e passou o baton para ⚙️ **sem** uma linha `**Aceite:** <quem>, <data> (bloco <id>)` nova |
| ⑦ | só com o módulo OpenSpec: o contrato do bloco não declara a change nem o motivo de não haver uma (cobrado com o baton no ⚙️ ou com o bloco concluído); ou a change não existe, não valida, tem `skip_specs`, segue aberta com o bloco concluído, ou falta o CLI para validá-la |

Outros nove itens da Conferência de saída seguem na mão (critérios de aceite medidos, documento de
interface atualizado, nenhuma decisão pendente selada por fora etc.) — ver
[`sessao/referencia/conferencia.md`](sessao/referencia/conferencia.md).

O `--estado` devolve no stdout, em JSON, o que o `start` e o `escopos` precisam — PLAN, branch, bloco
ativo, baton (papel, ponto de entrada, coerência com os checkboxes), próxima tarefa aberta, gates 🔁,
blockers, se o log de apontamento existe e a declaração OpenSpec do bloco —, para o modelo não ter de
interpretar o PLAN sozinho. Sai com exit 1 se o baton estiver podre, como o `--inicio`.

O projeto recebe um **lançador**, não uma cópia do portão: ele procura a skill em `$SESSAO_SKILL_DIR`
→ `~/.claude/skills/sessao` → `~/.codex/skills/sessao` → `<repo>/.agents/skills/sessao`. Assim toda
correção do portão chega aos projetos já instalados. Se não achar a skill, sai com **exit 2**, nunca 0:
portão que não rodou não pode parecer portão que passou.

---

## Skill `resumo-trabalho`

> Referência completa: [`resumo-trabalho/SKILL.md`](resumo-trabalho/SKILL.md); modelo do resumo em
> [`resumo-trabalho/templates/template-apontamentos.md`](resumo-trabalho/templates/template-apontamentos.md).

### A ideia

O trabalho é entregue **por card do GitLab**, e um card pode levar vários dias e tocar vários repos. Por
isso o log é **um arquivo por label** (card), global e fora de qualquer repositório —
`<work-log>/<label>.md` — e append-only. O resumo é gerado a partir dele, no modelo "Apontamentos",
pronto para colar no card.

**Com a `sessao`, as entradas são automáticas:** cada sessão grava a sua, depois do seu ok, e você só
pede o `gerar`. O `label` e o `registrar` servem para registrar à mão — o trabalho feito fora de um
escopo, por exemplo.

### Subcomandos

| Comando | Efeito |
|---|---|
| `label <card>` | Define o label ativo **desta conversa**. |
| `registrar [<card>] [texto]` | Acrescenta uma entrada ao log (O que foi feito / Problemas-Correções / Validações / Pendências). Sem card nem label ativo, **pergunta** — nunca inventa. |
| `gerar <card>` | Resumo do card com as entradas de **hoje** — o apontamento diário. |
| `gerar <card> <AAAA-MM-DD>` | O mesmo para uma data específica (retroativo). |
| `gerar <card> completo` | Resumo de todo o histórico do card. |
| `gerar dia [<AAAA-MM-DD>]` | Agregado de todos os cards do dia. ⚠️ **Só com pedido explícito de agregar todos os cards.** |
| `listar` | Lista os labels existentes, com contagem de entradas e datas. |

Linguagem natural equivalente também vale ("vou trabalhar no card X", "anota isso no card X", "resumo
do card X").

**"Resumo do dia" sem card não é `gerar dia`.** O alvo é o label ativo da conversa (ou o slug do
escopo do `sessao` que a sessão operou); sem ele, o agente pergunta o card — não o deduz pelo
repositório nem pelo índice de escopos, como a `sessao` também não deduz. O agregado só sai com pedido
explícito. "Hoje" filtra a data **dentro** do card, nunca amplia a busca. O motivo é concreto: o apontamento é colado num card específico, e misturar labels entrega à
chefia trabalho de outra frente, em outro repo.

### Regras do resumo

- **Leitor não-técnico:** quem lê é a chefia, que conhece o projeto mas não mexe no código. Todo
  detalhe técnico entra **completo** (nomes, números, comandos, causa raiz) **e** precedido de uma
  explicação curta — bloco "🧭 Para entender este apontamento", aposto na 1ª menção e frase de
  propósito abrindo cada subseção. Cortar detalhe para simplificar é tão errado quanto despejar
  jargão cru.
- **Links:** todo documento, página ou relatório publicado no período entra com link clicável, inline
  e numa seção "📎 Documentos e páginas".
- **MR/issue sempre qualificado:** `grupo/projeto!N`, nunca `!N` solto — o card vive em outro
  projeto, e a referência curta apontaria para o repo errado.
- **Sem horário no título de subseção** — a chefia lê por assunto, não por timestamp.
- **Entrega** dentro de um bloco de 4 crases (ou `~~~`), para colar markdown cru no GitLab.

---

## Como as duas se integram

```mermaid
flowchart LR
    sessao["/sessao end · handoff · parada no meio do bloco"] -->|"só depois do seu ok"| log[("#lt;work-log#gt;/#lt;slug#gt;.md<br/>uma entrada por sessão<br/>com a linha Sessão: #lt;chave#gt;")]
    log --> resumo["/resumo-trabalho gerar #lt;slug#gt;"]
```

- **Automático:** você não chama `registrar`. O agente grava a entrada da sessão no log sozinho, logo
  depois do seu ok para o commit; você só pede o `/resumo-trabalho gerar <slug>`.
- **O label é o slug.** Não há campo separado, nem apelido: o escopo `upgrade-postgres-16` escreve em
  `<work-log>/upgrade-postgres-16.md`, e o resumo sai com `/resumo-trabalho gerar upgrade-postgres-16`.
- **Uma sessão = uma entrada — o índice é a sessão, não o relatório.** `end`, `handoff` e toda parada
  no meio de bloco gravam a entrada da sessão. Com relatório, ele é a matéria-prima; sem relatório, a
  fonte é a linha do §8 + as decisões + os commits daquela sessão.
- **A chave da sessão sai do arquivo, nunca da memória.** Ela vem da linha da sessão no §8 do PLAN e
  vai na linha `**Sessão:**` logo abaixo do cabeçalho da entrada:

  | Registro de sessões do PLAN | Chave | Exemplo no log |
  |---|---|---|
  | sem coluna de número (template atual): `\| 2026-09-24 \| B5 \| … \|` | `<data>#<k>`, k = posição entre as linhas de mesma data | `**Sessão:** 2026-09-24#2 · B5 (⚙️ Executor)` |
  | com coluna de número (legado): `\| 11 \| 2026-09-04 \| … \|` | o número | `**Sessão:** 11` |

  A chave torna o registro idempotente (rodar o `end` de novo não duplica) e é o que o item ⑤ do
  portão confere, sessão por sessão. Por isso o §8 é append-only: cada sessão acrescenta a sua linha
  no fim.

---

## Estrutura do repositório

```text
.
├── README.md                         ← este arquivo
├── openspec/                         ← specs vivas das próprias skills (specs/) e changes arquivadas
├── scripts/
│   ├── versao.sh                     ← confere VERSION × CHANGELOG × tag e prepara um lançamento
│   └── autoteste_versao.sh           ← testa o versao.sh num repositório descartável
├── sessao/
│   ├── SKILL.md                      ← o roteador: ativação, subcomando → arquivo, regras invioláveis
│   ├── VERSION                       ← a versão atual (SemVer)
│   ├── CHANGELOG.md                  ← o que mudou em cada versão
│   ├── subcomandos/                  ← um arquivo por subcomando, lido sob demanda
│   ├── referencia/                   ← protocolo, conferência de saída, apontamentos, layout, deploy, openspec
│   ├── HISTORICO.md                  ← o porquê de cada regra (não é carregado para operar)
│   ├── HELP.md                       ← índice de uso (/sessao help)
│   ├── README.md                     ← resumo da skill
│   ├── agents/openai.yaml            ← bloqueia invocação implícita no Codex
│   ├── scripts/
│   │   ├── conferencia_saida.sh      ← o portão (fechamento, --inicio, --estado)
│   │   ├── conferencia_saida.shim.sh ← o lançador instalado nos projetos
│   │   ├── bloco_agents.sh           ← sincroniza o bloco gerenciado do AGENTS.md (`update`)
│   │   ├── openspec_ambiente.sh      ← confere e prepara o OpenSpec: CLI, telemetria, schema, repo
│   │   └── autoteste_portao.sh       ← testa portão, --estado, bloco gerenciado e ambiente do OpenSpec
│   ├── openspec-schema/              ← o schema `sessao` do OpenSpec (proposta + specs, sem tarefas)
│   └── templates/
│       ├── AGENTS.template.md        ← índice + regras do projeto + bloco gerenciado
│       ├── CLAUDE.template.md        ← o `@AGENTS.md`
│       ├── PLAN.template.md          ← o PLAN de um escopo
│       ├── template-relatorio.md     ← gabarito de relatório de bloco
│       └── README.md                 ← o que o `init` copia para o projeto
└── resumo-trabalho/
    ├── SKILL.md
    ├── VERSION
    ├── CHANGELOG.md
    └── templates/template-apontamentos.md
```

## Manutenção

- **A fonte canônica de cada skill é o `SKILL.md` e os arquivos que ele manda ler** (na `sessao`,
  `subcomandos/` e `referencia/`). Cada regra mora em um desses arquivos só; `HELP.md`, templates e
  este README apontam para eles. Se divergirem, a fonte canônica vence — e a divergência é bug a
  corrigir no mesmo commit.
- **Mexeu numa regra? Leia antes o caso que a criou** em `sessao/HISTORICO.md`, e registre lá o novo.
- **Mexeu no portão, no `bloco_agents.sh`, no `openspec_ambiente.sh`, no schema ou nos templates? Rode o
  autoteste** antes de commitar:

  ```bash
  ~/.claude/skills/sessao/scripts/autoteste_portao.sh   # exit 0 = íntegro; exit 1 = regressão
  ```

  Ele monta repositórios descartáveis a partir dos templates, num `HOME` falso, e afirma que cada item
  do portão dispara quando deve e fica verde quando deve, que o `--estado` devolve JSON correto e que o
  bloco gerenciado é sincronizado sem tocar no resto do `AGENTS.md`; cobre também o ⑦ e o ambiente do
  OpenSpec. São 54 casos, e o 51 usa o OpenSpec real, se instalado. Existe porque, em 2026-08-24, o
  portão e o `PLAN.template.md` falavam dialetos diferentes e o portão aprovava sem conferir quase
  nada — com exit 0.
- **Mudou o bloco gerenciado do `AGENTS.template.md`?** Rode `/sessao update` em cada projeto instalado.
- **Mudou um comportamento verificável de uma skill** (portão, lançador, bloco gerenciado, ambiente do
  OpenSpec)? Este repositório usa o próprio módulo: abra uma change em `openspec/`
  (`openspec new change <id> --schema sessao`), valide e arquive junto com o código — ver
  [`sessao/referencia/openspec.md`](sessao/referencia/openspec.md). Os cenários das specs vivas são os
  casos do autoteste.
- **Atualizou o CLI do OpenSpec?** Rode o autoteste antes de usar: o portão depende do formato da
  resposta do CLI, e o caso 51 é o que pega uma mudança nele. Só então suba `OPENSPEC_MINIMO`.
- **Código que parece morto e não é:** o suporte ao layout legado (PLAN na raiz, índice no `CLAUDE.md`,
  registro de sessões numerado) é deliberado — os escopos legados não serão migrados. Está marcado
  como tal nos scripts e coberto pelo autoteste; removê-lo é retirada de suporte, não limpeza.
- **Commits** no padrão `<skill>: <o que mudou e por quê>`, em pt-BR (ex.: `sessao: o ⑤ confere a
  chave de cada sessão nova`). Mudança que atravessa as duas skills ou o repositório: `repo: …`. O
  lançamento de uma versão é um commit à parte, `release: <skill> <versão>`. **Todo commit que muda
  uma skill acrescenta uma linha na seção `## [Não lançado]` do CHANGELOG dela** — ver
  [Versionamento](#versionamento).
- O antigo espelho `~/workspace/playbook-controle-sessoes/` foi **aposentado** em 2026-09-24. Este
  repositório é a única fonte.

## Versionamento

Cada skill tem a sua própria versão, no padrão [SemVer](https://semver.org/lang/pt-BR/)
(`MAJOR.MINOR.PATCH`), porque elas mudam em ritmos diferentes:

| Onde | O quê |
|---|---|
| `<skill>/VERSION` | a versão atual, e nada mais |
| `<skill>/CHANGELOG.md` | o que mudou em cada versão, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) |
| tag `<skill>-v<versão>` | o commit que lançou a versão (ex.: `sessao-v3.0.0`) |

**Quando subir cada número.** O critério é o que muda para quem usa a skill:

- **MAJOR** — quebra algo de que os projetos ou o uso já dependem: subcomando que some ou muda a forma
  de chamar; escopo existente que passa a reprovar no portão sem ter mudado; formato incompatível de
  arquivo (`PLAN.md`, work-log, bloco gerenciado, lançador).
- **MINOR** — capacidade nova que não quebra o que existe: subcomando novo, modo novo do portão, item
  do portão que só vale para escopo novo, texto novo no bloco gerenciado. Exigir uma ferramenta nova
  só para usar a capacidade nova também é MINOR.
- **PATCH** — correção sem mudar o contrato, inclusive de um defeito que fazia o portão aprovar o que
  devia reprovar.

Quando a versão pede ação nos projetos (rodar `/sessao update`, instalar uma ferramenta), o CHANGELOG
diz isso numa linha **Ação nos projetos:**, no começo da seção da versão.

**Lançar é dar número ao que está em `## [Não lançado]`:** o `VERSION` sobe, as entradas ganham o
título da versão com a data, e a tag marca o commit no git. É o que diz a quem usa a skill qual versão
tem instalada e o que mudou desde a anterior. Correção também se lança: é o PATCH.

**No dia a dia,** todo commit que muda uma skill acrescenta a sua linha em `## [Não lançado]`, sob
*Adicionado*, *Modificado*, *Removido* ou *Corrigido*. Para lançar, depois de commitar as mudanças
(`<nível>` é `major`, `minor` ou `patch`):

```bash
scripts/versao.sh lancar <skill> <nível>   # grava o VERSION e abre "## [<versão>] - <hoje>" logo abaixo do "## [Não lançado]"
git add <skill> && git commit -m "release: <skill> <versão>"
git tag -a <skill>-v<versão> -m "<skill> <versão>"
git push origin master <skill>-v<versão>
```

O lançamento é sempre um commit à parte, que só mexe no `VERSION` e no CHANGELOG, e a tag vai nele.
Assim o prefixo de cada commit de mudança continua dizendo o que mudou, `git show <skill>-v<versão>`
mostra só o lançamento e `git log --grep '^release:'` lista todas as versões. O `lancar` não commita,
não cria tag e não faz push: ele imprime estes três comandos com a versão nova preenchida, e cada um
segue a regra de sempre — o agente só o roda com a sua validação explícita.
`scripts/versao.sh verificar` confere que VERSION, CHANGELOG e tag concordam e que nenhuma skill mudou
desde a última tag sem entrada no CHANGELOG. Rode antes de cada push. `scripts/autoteste_versao.sh`
testa o próprio verificador.

**Antes de 2026-10-19 não havia número.** A primeira versão numerada da `sessao` é a 3.0.0: o
repositório já a chamava de "controle de sessões v2" desde o primeiro commit, e a reestruturação de
2026-10-19 quebrou o contrato dessa v2. A `resumo-trabalho` começa na 1.0.0. O que veio antes está
resumido no fim de cada CHANGELOG.

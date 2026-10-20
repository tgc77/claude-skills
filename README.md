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

**A divisão do trabalho, em uma frase:** você digita `/sessao init` uma vez por escopo e
`/sessao start <slug>` a cada sessão, e responde e valida o que o agente mostra; o agente planeja com
você, executa, registra, confere e commita, para em cada ponto que depende de você e termina toda
sessão mostrando o comando da próxima. Para começar: [Instalação](#instalação),
[Primeiros passos](#primeiros-passos) e [Quem faz o quê](#quem-faz-o-quê).

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
- [Testes](#testes)
- [Versionamento](#versionamento)

---

## Instalação

Uma vez por máquina. O primeiro passo é seu; o segundo, o agente faz com o seu ok.

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

**2. O CLI do OpenSpec**, sem o qual não se abre escopo novo. Basta ter Node ≥ 20.19 na máquina: o
`/sessao init` confere o resto e, se o CLI faltar, mostra os comandos e, com o seu ok, instala ele
mesmo — na versão mínima, com a conferência de assinaturas e a telemetria desligada — e liga o schema
da skill ao OpenSpec. O passo a passo está em
[`sessao/referencia/openspec.md`](sessao/referencia/openspec.md#ambiente--uma-vez-por-máquina).

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

Você não precisa decorar nada disto: toda sessão termina com os **próximos passos**, que trazem o
comando da sessão seguinte pronto para copiar. Os comandos abaixo são os do Claude Code; no Codex,
troque `/sessao` por `$sessao`.

1. **Abra o escopo.** No repositório do projeto, numa sessão nova:

   ```text
   /sessao init
   ```

   O agente pergunta o slug, a descrição, o que fica fora, os blocos iniciais, a branch de trabalho, o
   ambiente e os guardrails; na primeira vez naquele repositório, também como tratar você, o idioma, a
   política de commit e os repos irmãos. **Você** responde, confere a estrutura que ele mostra e dá o
   "ok" para criar; depois, outro "ok" para o commit. Num repositório que já usa a skill, o `init` só
   acrescenta o escopo novo. No fim, ele mostra o comando da próxima sessão e oferece seguir direto
   para o planejamento do primeiro bloco, ali mesmo.

2. **Planeje o primeiro bloco**, com um modelo forte — na mesma sessão do `init`, se aceitou a oferta,
   ou numa sessão nova:

   ```text
   /sessao start upgrade-postgres-16
   ```

   O baton diz 🧠 Planejador. O agente deixa o bloco **executor-ready**: tarefas atômicas, cada
   critério de aceite medido, as decisões de design resolvidas com você e, se o bloco muda um
   comportamento de que alguém depende, uma change do OpenSpec com a proposta e o delta das specs.
   Então ele mostra o plano, e **você lê e dá o aceite** — responder às perguntas dele não conta como
   aceite. Com o aceite, que vale também como o ok do commit, ele mesmo faz o **handoff**: passa o baton
   ao ⚙️ Executor, grava o apontamento, roda o portão e commita. Você não digita `/sessao handoff`. Se
   o `init` já deixou o bloco executor-ready, com o baton em ⚙️, pule para o passo 3.

3. **Execute**, numa **sessão nova** e com um modelo mais barato:

   ```text
   /sessao start upgrade-postgres-16
   ```

   O baton diz ⚙️ Executor. O agente executa o bloco inteiro em loop, marcando as tarefas, sem pedir
   licença a cada passo. Ele só para quando o bloco fecha ou quando precisa de você — decisão de design
   fora do plano, critério de aceite que não bateu, autorização que falta. Nos dois casos ele encerra a
   sessão sozinho (é o `end`) e pede o seu "ok" para commitar.

4. **Valide.** Responda "ok", ou peça ajustes. Com o ok, o agente grava o apontamento, roda o portão e
   commita. Depois pergunta se pode fazer o push e termina com os **próximos passos**:

   ```text
   ▶ Próxima sessão — 🧠 Planejador, com um modelo forte, numa sessão nova:
       /sessao start upgrade-postgres-16
   • Push: o commit 3f2a9c1 está só no repositório local. Posso fazer o push?
   • Apontamento do dia: é só pedir "gere os apontamentos de hoje" — o escopo já está ativo nesta conversa.
   ```

5. **Repita com o comando que a sessão anterior mostrou**, sempre numa sessão nova: com o baton em 🧠,
   o Planejador detalha o próximo bloco e, com o seu aceite, faz o handoff; com o baton em ⚙️, o
   Executor executa. Ficou um tempo longe do escopo? Veja [como conferir onde parou](#quem-faz-o-quê).

6. **Apontamento do dia:** peça "gere os apontamentos de hoje". As entradas já foram gravadas sessão a
   sessão, e o escopo ativo na conversa diz de qual escopo é o resumo, que sai pronto para colar no card.
   Numa conversa sem escopo ativo, diga qual: "gere os apontamentos de hoje do upgrade-postgres-16".

Para encerrar uma sessão no meio, peça `/sessao end`: o agente registra onde parou e fecha como no fim
de um bloco. Se a conversa terminar sem isso, o próximo `start` percebe as edições que ficaram sem
commit e pergunta o que fazer antes de seguir.

## Quem faz o quê

Você conduz com comandos e validações; o trabalho de registro é do agente, que segue a skill sem você
pedir. Os scripts de `sessao/scripts/` também são do agente: você não precisa rodá-los.

| Momento | Você | O agente, sozinho |
|---|---|---|
| **Uma vez por máquina** | Clona as skills ([Instalação](#instalação)) e aprova a instalação do CLI do OpenSpec, quando o agente pedir. | No `init`, confere o ambiente do OpenSpec; se faltar o CLI, mostra os comandos e, com o seu ok, instala, confere as assinaturas, desliga a telemetria e liga o schema da skill. |
| **Abrir um escopo** | `/sessao init`; responde slug, blocos, branch, ambiente e guardrails; dá o ok para criar e para commitar. | Confere se o slug é único. Na 1ª vez no repositório, cria `AGENTS.md`, `CLAUDE.md`, o lançador do portão e o template de relatório; em todo escopo novo, o `PLAN.md` com o 1º bloco detalhado, a linha no índice, a pasta `openspec/` (se faltar) e o baton. No fim, mostra o comando da próxima sessão. |
| **Começar uma sessão** | Abre uma sessão nova, com o modelo que os próximos passos sugeriram, e cola o comando deles (`/sessao start <slug>`). | Lê o estado do escopo, confere o baton e assume o papel que ele manda, sem perguntar. Avisa se a sessão anterior não fechou e se o projeto precisa de `/sessao update`. |
| **Planejar (🧠)** | Responde às decisões de design, lê o plano — e a proposta e o delta do OpenSpec, se houver — e dá o aceite. | Detalha o bloco, mede os critérios de aceite, cria e valida a change do OpenSpec e mostra o plano. Com o seu aceite, faz o handoff sozinho: grava o contrato, o aceite e o baton ⚙️. |
| **Executar (⚙️)** | Acompanha. Pode interromper, ou pedir `/sessao end` para encerrar no meio. | Executa o bloco em loop e marca as tarefas; quando a realidade diverge do plano, para e devolve ao Planejador. |
| **Fechar a sessão** | Dá o ok para o commit, ou pede ajustes (na sessão de Planejador, o aceite já vale como esse ok); responde se pode fazer o push. | Fecha a sessão sozinho: o Planejador com o `handoff`, o Executor com o `end`, ao fechar o bloco ou ao parar. Atualiza PLAN, baton e registro de sessões; gera o relatório se o bloco fechou e arquiva a change; com o ok, grava o apontamento, roda o portão e commita. Pergunta do push e termina com os **próximos passos**. |
| **Apontamento do dia** | Pede "gere os apontamentos de hoje" e cola o resultado no card. | Já gravou uma entrada no log para cada sessão; com o pedido, gera o resumo do escopo ativo na conversa. |
| **A skill mudou** | `/sessao update`, quando o agente mostrar o comando. | Percebe no `start` e no `escopos` que o bloco gerenciado do `AGENTS.md` ficou desatualizado e mostra o comando; no `update`, sincroniza o bloco, o lançador e o ambiente do OpenSpec e commita com o seu ok. |

- **Os próximos passos, no fim de toda sessão,** trazem tudo o que depende de você, com o comando
  exato: a próxima sessão (papel, modelo sugerido e `/sessao start <slug>`), o push a aprovar, o merge,
  quando o commit não está na branch base, e o lembrete de que o apontamento do dia sai com um pedido:
  "gere os apontamentos de hoje".
- **O agente nunca faz sem o seu ok:** commit, `push`, a entrada no log de apontamentos e instalação de
  ferramenta. E nunca dá o aceite de um plano por você nem escolhe o escopo quando você não deu o slug:
  mostra o que falta e pergunta.
- **Você não precisa fazer à mão:** editar o PLAN, o baton ou o registro de sessões; rodar o portão;
  escrever no log; criar, validar ou arquivar a change do OpenSpec; digitar `handoff` ou `end` no fim
  de um bloco; lembrar o comando da próxima sessão.
- **Para conferir onde parou** — depois de um tempo longe do escopo, ou para ver se o baton foi mesmo
  para o Executor: `/sessao escopos` mostra o baton de cada escopo, e
  `/sessao start <slug> onde paramos?` dá um briefing sem executar nada. Nenhum dos dois altera o
  repositório. O `handoff` não serve para isso: rodado de novo, ele refaz o ritual e pede outro aceite.
- **O modelo é escolha sua:** a skill não troca de modelo; os próximos passos dizem o papel da próxima
  sessão e sugerem o modelo. Um modelo só também funciona; a divisão compensa quando executar custa
  muito mais que planejar.
- **O merge também:** o PLAN e o `AGENTS.md` precisam viver na branch base compartilhada, senão um
  escopo que está em outra branch parece ter sumido. Os próximos passos avisam quando o commit ficou
  fora dela.
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
| `handoff` | o Planejador, sozinho, ao fim do planejamento; você só o digita para ir direto a ele (ex.: logo depois do `init`) | Planejador → Executor: deixa o bloco executor-ready, mede os critérios, declara a change do OpenSpec e mostra o plano; com o seu **aceite**, grava o baton e o apontamento, roda o portão e commita. | Sim, com o seu aceite |
| `end` | o Executor, sozinho, quando o bloco fecha ou para; você, para encerrar no meio | Fim de sessão (ver abaixo). | Sim, com o seu ok |
| `update` | você, quando o agente mostrar o comando (no `start` ou no `escopos`) | Põe o projeto em dia com a skill: sincroniza o bloco gerenciado do `AGENTS.md` (`scripts/bloco_agents.sh`), troca a cópia antiga do portão pelo lançador, confere o `CLAUDE.md` e o ambiente do OpenSpec. | Sim, com o seu ok |

### Ciclo de vida

```mermaid
flowchart TD
    init["/sessao init<br/>estrutura + PLAN com B1 detalhado"] -->|"baton 🧠"| plan
    plan["/sessao start #lt;slug#gt;<br/>o Planejador detalha o bloco e mede os critérios"] --> handoff
    handoff["handoff, feito pelo Planejador<br/>depois do seu aceite"] -->|"baton ⚙️"| exec
    exec["/sessao start #lt;slug#gt;<br/>o Executor executa o bloco em loop"] --> term{"condição<br/>terminal"}
    term -->|"bloco fechou"| fecha["auto-end: relatório + registro<br/>pede o seu ok para commitar"]
    term -->|"parada no meio"| para["registro sem relatório<br/>pede o seu ok para commitar"]
    fecha -->|"último bloco"| fim["escopo 🟢 no índice<br/>a pasta fica como histórico"]
    fecha -->|"baton 🧠"| plan
    para -->|"baton 🧠"| plan
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
5. **Commita** só o que é daquele escopo e daquela sessão.
6. Pergunta, em separado, se pode fazer o **push** — inclusive para deploy — e termina com os
   **próximos passos**: o comando completo da próxima sessão, o merge, se o commit ficou fora da branch
   base, e o lembrete do apontamento do dia.

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

**Com a `sessao`, as entradas são automáticas:** cada sessão grava a sua, depois do seu ok, e para o
resumo basta pedir "gere os apontamentos de hoje" na conversa do escopo. O `label` e o `registrar`
servem para registrar à mão — o trabalho feito fora de um escopo, por exemplo.

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
explícito. "Hoje" filtra a data **dentro** do card, nunca amplia a busca. O motivo é concreto: o
apontamento é colado num card específico, e misturar labels entrega à chefia trabalho de outra frente,
em outro repo.

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
    sessao["sessão que termina<br/>end · handoff · parada no meio do bloco"] -->|"só depois do seu ok"| log[("#lt;work-log#gt;/#lt;slug#gt;.md<br/>uma entrada por sessão<br/>com a linha Sessão: #lt;chave#gt;")]
    log --> resumo["pedido: gere os apontamentos de hoje<br/>= /resumo-trabalho gerar #lt;slug#gt;"]
```

- **Automático:** você não chama `registrar`. O agente grava a entrada da sessão no log sozinho, logo
  depois do seu ok para o commit; para o resumo, basta pedir "gere os apontamentos de hoje" na conversa
  do escopo.
- **O label é o slug.** Não há campo separado, nem apelido: o escopo `upgrade-postgres-16` escreve em
  `<work-log>/upgrade-postgres-16.md`. O pedido em linguagem natural equivale a
  `/resumo-trabalho gerar upgrade-postgres-16`, que dá o mesmo resultado em qualquer conversa.
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
├── .github/workflows/testes.yml      ← as camadas 1 e 2 dos testes a cada push e pull request
├── openspec/                         ← specs vivas das próprias skills (specs/) e changes arquivadas
├── scripts/
│   ├── testar.sh                     ← os testes numa chamada só (ver Testes)
│   ├── versao.sh                     ← confere VERSION × CHANGELOG × tag e prepara um lançamento
│   └── autoteste_versao.sh           ← testa o versao.sh num repositório descartável
├── testes/
│   ├── documentacao.py               ← a camada 2: diagramas, texto que some, links, subcomandos
│   ├── autoteste_documentacao.sh     ← testa a conferência da documentação
│   └── comportamento/                ← a camada 3: o agente de verdade em cenários roteirizados
│       ├── rodar.sh                  ← roda os cenários, soma o custo e grava o selo
│       ├── lib.sh                    ← a caixa descartável, o turno do agente e as asserções
│       ├── cenarios/                 ← um arquivo por cenário
│       └── fixtures/                 ← o projeto de mentira e o PLAN pronto para o Executor
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
- **Antes de cada commit, rode `scripts/testar.sh`** (camadas 1 e 2, ver [Testes](#testes)). O CI roda o
  mesmo a cada push, mas lá o vermelho chega depois do commit. Entre os testes está o autoteste do
  portão (`sessao/scripts/autoteste_portao.sh`): ele monta repositórios descartáveis a partir dos
  templates, num `HOME` falso, e afirma que cada item do portão dispara quando deve e fica verde quando
  deve, que o `--estado` devolve JSON correto e que o bloco gerenciado é sincronizado sem tocar no resto
  do `AGENTS.md`; cobre também o ⑦ e o ambiente do OpenSpec. São 54 casos, e o 51 usa o OpenSpec real,
  se instalado. Existe porque, em 2026-08-24, o portão e o `PLAN.template.md` falavam dialetos
  diferentes e o portão aprovava sem conferir quase nada — com exit 0.
- **Mexeu em instrução de uma skill** (`SKILL.md`, `subcomandos/`, `referencia/`, templates)? Rode
  também a camada 3, `scripts/testar.sh --comportamento`: só o agente de verdade mostra se ele passou a
  fazer o que o texto novo diz. O `lancar` a exige antes de dar número à versão.
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

## Testes

Três camadas, todas por um comando só, o [`scripts/testar.sh`](scripts/testar.sh):

| Camada | O que confere | Quando roda | Custo |
|---|---|---|---|
| 1. Scripts | O portão, o `versao.sh` e a própria conferência da documentação, cada um no seu autoteste, em repositórios descartáveis; e VERSION × CHANGELOG × tag. | Sozinha: a cada push e pull request (GitHub Actions) e no `versao.sh lancar`. | Grátis, segundos. |
| 2. Documentação | Diagrama Mermaid que não renderiza ou que o VS Code apaga (`&lt;` num rótulo); `<placeholder>` fora de código, que some da página; link relativo e âncora quebrados; subcomando que o roteador, o `HELP.md` e o README não listam igual. | Junto com a 1. | Grátis. |
| 3. Comportamento do agente | O agente de verdade, em cenários roteirizados num projeto descartável — o ciclo inteiro (`init` → `start` 🧠 → aceite → push → `start` ⚙️ → "gere os apontamentos de hoje") e as travas da skill. | Você, antes de lançar uma versão que mexeu em instrução: o `lancar` exige. | Gasta do seu plano. |

```bash
scripts/testar.sh                                # camadas 1 e 2 — o que o CI roda
scripts/testar.sh --comportamento                # e a camada 3
testes/comportamento/rodar.sh --listar           # os cenários da camada 3
testes/comportamento/rodar.sh ciclo-completo     # um cenário só (não grava o selo)
testes/comportamento/rodar.sh --ferramenta codex # o mesmo roteiro no Codex
```

**Os cenários da camada 3**, do mais barato ao mais caro: o `help` mostra o guia; o `start` sem
slug pergunta qual escopo, mesmo com um só; um pedido técnico comum não liga a skill; "gere os
apontamentos de hoje" sem escopo ativo pergunta o card; o `start` avisa do bloco gerenciado
desatualizado e da sessão anterior que não fechou; sem o "ok", nada é commitado nem vai para o
work-log; e o ciclo completo, num repositório virgem.

**Como ela confere.** Cada cenário roda numa caixa em `/tmp`: o projeto (uma calculadora que só
soma), um remoto local que flagra push e um work-log próprio (`SESSAO_WORKLOG_DIR`). O seu work-log e
este repositório não são tocados, e o teste confere isso a cada turno. As mensagens são as que você
mandaria ("Aceito o plano do B1. Pode commitar.", "gere os apontamentos de hoje"), e cada sessão
nova é uma conversa nova, como no uso real. As asserções olham primeiro o estado — o `--estado` do
portão, os commits, o work-log, o remoto, o portão rodado de novo — e só depois a resposta. O
Planejador roda com o modelo forte (opus) e o Executor com o barato (sonnet), a divisão que a skill
recomenda.

**O selo.** A rodada completa e verde da camada 3 grava, dentro do `.git` (fora de qualquer commit), a
impressão digital das instruções das skills e dos cenários. O `versao.sh lancar` roda as camadas 1 e
2 e, se a skill mudou instrução desde a última tag, exige o selo do conteúdo atual; sem ele, recusa e
mostra o comando. Mudança só no CHANGELOG, no HISTORICO, no README ou no VERSION não exige.

**Requisitos da camada 3:** o CLI logado (`claude` ou `codex`), `jq`, `python3` e `openspec`. O
`claude` do PATH precisa estar em dia (`claude update`); para usar outro binário, aponte
`SESSAO_TESTE_CLAUDE` para ele. Os modelos mudam com `SESSAO_TESTE_MODELO_FORTE` e
`SESSAO_TESTE_MODELO_BARATO`. O custo que a rodada informa é o preço de tabela; nos planos Pro e Max,
ele sai do uso do plano. Medido em 2026-10-20: os sete cenários baratos, uns US$ 1,30; o ciclo completo,
com o Planejador no opus, uns US$ 8 a 10 — o bastante para esgotar a janela de 5 horas do Pro numa
tarde de testes. `SESSAO_TESTE_MODELO_FORTE=sonnet` barateia a rodada, ao custo de testar o
Planejador com o modelo que a skill não recomenda para ele.

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
desde a última tag sem entrada no CHANGELOG; o `scripts/testar.sh` e o CI o rodam.
`scripts/autoteste_versao.sh` testa o próprio verificador.

**O `lancar` só lança o que passou nos testes.** Antes de editar qualquer arquivo, ele roda as camadas
1 e 2 e, se a skill mudou instrução desde a última tag, exige o selo da camada 3 para o conteúdo atual
(ver [Testes](#testes)). Vermelho, ou teste que não rodou, e ele recusa, mostrando o que falta.

**Antes de 2026-10-19 não havia número.** A primeira versão numerada da `sessao` é a 3.0.0: o
repositório já a chamava de "controle de sessões v2" desde o primeiro commit, e a reestruturação de
2026-10-19 quebrou o contrato dessa v2. A `resumo-trabalho` começa na 1.0.0. O que veio antes está
resumido no fim de cada CHANGELOG.

---
name: sessao
description: >-
  Monta e opera o sistema de Controle de Sessões para projetos de escopo definido — protocolo
  na skill + índice de escopos no AGENTS.md + um PLAN.md por escopo (docs/sessoes/SLUG/) + protocolo
  planner/executor + rolling-wave. Skill de invocação exclusivamente explícita: use somente quando
  Tiago escrever $sessao, @sessao ou /sessao. Nunca a acione por contexto do repositório ou por um
  pedido técnico comum. Para assumir e operar um escopo existente, exija `sessao start SLUG`
  explicitamente; os demais subcomandos executam somente sua própria função.
---

# Skill: sessao — Controle de Sessões

Sistema para tocar um projeto de escopo definido com agentes de I.A., com cada sessão enxuta de
contexto e sem perda de continuidade, mesmo que cada sessão comece do zero e modelos diferentes assumam
o trabalho. **Princípio único:** cada fato mora em UM arquivo; o resto aponta, nunca copia. O plano se
detalha em rolling-wave: perto em alta resolução, longe em rascunho.

## ⛔ Ativação exclusivamente explícita

- Só aja quando o usuário invocar a skill: `/sessao <sub>` no Claude Code; `$sessao <sub>` ou
  `@sessao <sub>` no Codex. Onde este texto diz `/sessao`, entenda "invoque a skill".
- **Assumir e operar um escopo exige `start <slug>` com o slug escrito.** Os demais subcomandos fazem
  só a própria função e não autorizam um `start` implícito.
- **Nunca deduza o escopo** pela branch, por haver um único escopo ativo, pelo índice ou pelo
  repositório. Sem slug, não escolha: liste os escopos e pergunte.
- `AGENTS.md`, `CLAUDE.md`, `docs/sessoes/` ou um PLAN existentes não ativam nada.
- 🔒 A regra também está em configuração, para o lado que lê política em vez de texto:
  [`agents/openai.yaml`](agents/openai.yaml) (`allow_implicit_invocation: false`). Se mover, clonar ou
  empacotar a skill, leve o arquivo junto — texto sozinho não impede invocação implícita.

**Onde a skill é descoberta:** Claude Code em `~/.claude/skills/`; Codex em `~/.codex/skills/` e em
`.agents/skills/`. Um symlink por caminho resolve: a skill mora num lugar só.

## 📂 Leitura sob demanda

Este arquivo é o roteador. **Antes de executar um subcomando, leia o arquivo dele e os que ele mandar
ler** — não execute de memória nem por este resumo. Sem subcomando, pergunte qual.

| Subcomando | O que faz | Leia |
|---|---|---|
| `escopos [<slug>]` | lista os escopos do repo e onde cada um parou; não altera nada | [`subcomandos/escopos.md`](subcomandos/escopos.md) |
| `init` | abre um escopo, instalando o sistema se o repo for virgem | [`subcomandos/init.md`](subcomandos/init.md) |
| `start <slug> [nota]` | início de sessão: assume o papel que o baton manda | [`subcomandos/start.md`](subcomandos/start.md) |
| `handoff` | Planejador → Executor: bloco executor-ready, critérios medidos, aceite | [`subcomandos/handoff.md`](subcomandos/handoff.md) |
| `end` | fim de sessão; o Executor o dispara sozinho ao fechar o bloco ou ao parar | [`subcomandos/end.md`](subcomandos/end.md) |
| `update` | põe o projeto em dia com a skill: bloco gerenciado do `AGENTS.md`, lançador do portão, ambiente do OpenSpec | [`subcomandos/update.md`](subcomandos/update.md) |
| `help` | mostra o guia de uso; não altera nada | [`HELP.md`](HELP.md) |

Referências, lidas quando o subcomando manda:

| Arquivo | Conteúdo |
|---|---|
| [`referencia/protocolo.md`](referencia/protocolo.md) | artefatos, rolling-wave, papéis 🧠/⚙️, quando o Executor para, baton, gates 🔁 |
| [`referencia/conferencia.md`](referencia/conferencia.md) | ordem do fechamento, portão ①-⑦, itens conferidos na mão |
| [`referencia/apontamentos.md`](referencia/apontamentos.md) | log do `resumo-trabalho`: uma sessão = uma entrada, chave, idempotência |
| [`referencia/layout.md`](referencia/layout.md) | layout do projeto, slug, resolução de escopo, branch base |
| [`referencia/deploy.md`](referencia/deploy.md) | entrega destinada a deploy |
| [`referencia/openspec.md`](referencia/openspec.md) | módulo OpenSpec: a declaração do bloco, change, validação, archive, ambiente |

O **porquê** de cada regra — os incidentes que a criaram — está em [`HISTORICO.md`](HISTORICO.md). Não
é preciso lê-lo para operar; leia antes de afrouxar, mover ou remover uma regra. Scripts em `scripts/`,
templates em `templates/`, ao lado deste arquivo.

## 🔑 Vocabulário

- **slug** — o identificador único do escopo: pasta `docs/sessoes/<slug>/`, argumento dos comandos e
  label do apontamento (`<work-log>/<slug>.md`). Sem apelidos.
- **PLAN** — `docs/sessoes/<slug>/PLAN.md`, fonte única de verdade do escopo (em escopo legado, o
  caminho que a coluna PLAN do índice disser).
- **baton** — a linha `🎬 Próximo:` do "🔎 Agora" do PLAN: o papel e o ponto de entrada da próxima
  sessão.
- **§8** — o registro de sessões do PLAN: append-only, uma linha por sessão.
- **portão** — `scripts/conferencia_saida.sh`: a conferência mecânica antes de todo commit de
  fechamento (`<slug> <ref-base>`), a checagem do baton (`--inicio`) e o estado do escopo em JSON
  (`--estado`).
- **bloco gerenciado** — o trecho do `AGENTS.md` entre `<!-- sessao:inicio` e `<!-- sessao:fim -->`,
  igual ao de `templates/AGENTS.template.md`; o `update` o mantém em dia.
- **change / spec viva** (módulo OpenSpec) — a change é a proposta + o delta de specs de um bloco que
  muda comportamento; arquivada quando o bloco conclui, ela é fundida em `openspec/specs/`, a spec viva.
  O contrato de cada bloco declara a sua change ou `não se aplica — <motivo>`
  ([`referencia/openspec.md`](referencia/openspec.md)).

## Regras invioláveis (valem em qualquer subcomando)

- **QUESTIONAMENTO ABERTO = REGISTRO CONGELADO.** No instante em que o usuário questiona, discorda ou
  pede para validar algo, **pare de escrever**: nada entra em `PLAN.md`, `AGENTS.md`, relatório,
  memória ou commit até ele concordar — **com tudo**, não com a parte que pareceu resolvida. Concordar
  com um ponto não libera os outros; silêncio não é aval; "faz sentido" no meio da conversa não é aval.
  O aval é explícito e vem **depois** de ele ver a evidência.
  - **Por quê:** registrar é o ato que transforma hipótese em verdade oficial do projeto. O PLAN é lido
    por sessões futuras como fato estabelecido, e commit por cima de análise não validada propaga o
    erro e custa caro de desfazer.
  - **No lugar:** apresente a evidência crua (diff, saída de comando, trecho de arquivo), a conclusão
    que tira dela e as opções, e pergunte. As mudanças ficam no working tree, sem commit.
  - **Não vale como desculpa:** "era só documentar", "é reversível", "ia commitar mesmo", "o ritual do
    `end` manda commitar". O ritual não sobrepõe esta regra: com questionamento aberto no fim da
    sessão, o `end` para e pergunta antes de commitar.
  - **Plano também é registro — e é o caso que mais escapa.** Selar um bloco (contrato no PLAN, baton,
    commit) exige as decisões pendentes zeradas e o plano **mostrado e aceito**, registrado como
    `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)` — o id do bloco é obrigatório. **Responder às
    perguntas do agente não é aceitar o plano:** 3 perguntas respondidas fecham as 3 perguntas, não
    abrem o commit. O item ⑥ do portão confere isso.
  - **Se já registrou antes do aval:** diga isso na primeira frase, ofereça o `git reset --soft` (ou
    reverter a edição) e espere. Nunca deixe passar como se tivesse sido combinado.
  - **Exceção única:** trabalho mecânico já contratado num bloco executor-ready — marcar checkbox de
    tarefa concluída, gerar o relatório de bloco fechado no ritual. Conclusão nova, causa raiz
    reenquadrada, mudança de contrato, criação ou cancelamento de bloco e reordenação do Board
    **nunca** são mecânicos.
  - A versão curta desta regra está no bloco gerenciado do `AGENTS.md` de cada projeto, e lá ela vale
    também fora da skill.
- **IDENTIFICADOR SOZINHO NÃO É CONTEXTO — quem pede decisão carrega a substância junto.** Ao levar
  qualquer pergunta ao usuário, **nunca** cite `T3`, `B2`, `D7` (ou nome de arquivo, flag, evento) como
  se o rótulo bastasse: escreva, ao lado do id, **o que aquilo é em uma linha** e **o que muda em cada
  opção**. Vale também no meio da conversa, não só no pedido formal de decisão.
  - **Por quê:** o id é escrituração interna do `PLAN.md`, não memória do usuário. As sessões são
    espaçadas e ele não carrega o Board na cabeça; perguntar por rótulo o obriga a abrir o PLAN para
    entender a própria pergunta, e **decisão tomada sem entender a pergunta é pior que decisão
    adiada**. O agente acabou de reler o PLAN inteiro; ele, não.
  - A versão curta desta regra também está no bloco gerenciado do `AGENTS.md`, e lá ela vale fora da
    skill.
- **Commit e push só com validação explícita**, pedida a cada vez — sem exceção, nem para deploy.
  Commite só o que é do escopo e da sessão; nada de `git add -A` cego.
- **Um escopo por sessão e por working tree.** Nunca leia nem opere o PLAN de outro escopo; paralelo
  real só com `git worktree`.
- **Anti-duplicação:** protocolo → esta skill; índice e regras do projeto → `AGENTS.md`; estado e plano
  → `PLAN.md` do escopo; detalhe denso → relatórios; ganchos → memória, onde a ferramenta tiver uma.
  Atualize in-place e nunca suba detalhe de relatório para o PLAN.
- **Fechamento passa pela Conferência de saída** ([`referencia/conferencia.md`](referencia/conferencia.md)):
  vermelho é PARADA, nunca ressalva no relatório.

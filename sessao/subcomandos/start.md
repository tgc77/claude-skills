# `start <slug> [nota]` — início de sessão

Leia antes de agir: [`../referencia/protocolo.md`](../referencia/protocolo.md) (papéis, baton, quando o
Executor para).

## 1. Escopo — só com o slug escrito

- O 1º termo depois de `start` é o slug; o resto é a **nota de sessão**. Procure o slug na coluna
  `Slug` do índice (`AGENTS.md`; em projeto legado, `CLAUDE.md`), por match exato. Nome que não está
  lá ⇒ pare e liste os slugs que existem.
- **Sem slug, não escolha:** liste os escopos (como em `escopos`) e pergunte qual. Nunca deduza pela
  branch, pelo único escopo ativo nem pelo repositório.
- Diga em 1 linha qual escopo assumiu.

## 2. Estado do escopo — um comando

```bash
scripts/conferencia_saida.sh <slug> --estado
```

O JSON traz o caminho do PLAN, a branch de trabalho, o bloco ativo, o baton (papel, ponto de entrada,
tarefa citada e se ela é coerente com os checkboxes), a próxima tarefa aberta do bloco, os gates 🔁, os
blockers e a declaração OpenSpec do bloco (`openspec`). **Exit 1 = baton podre** (manda executar tarefa já `[x]`, ou a linha 🎬 falta ou está
duplicada): **não execute**, não adivinhe a próxima tarefa e não replaneje por conta própria — mostre
ao usuário o que a linha 🎬 diz × o que o Board diz e pergunte.

Depois leia **só** o cabeçalho "🔎 Agora" e o bloco ativo do PLAN (o contrato: DoR, DoD, critérios,
escalonamento). Se o `openspec` do JSON aponta uma change **aberta**, leia também
`openspec/changes/<id>/` (proposta e delta): é o comportamento que o bloco entrega e faz parte do
contrato ([`../referencia/openspec.md`](../referencia/openspec.md)). Não releia relatórios e nunca leia o PLAN de outro escopo. Os guardrails 🚧 do PLAN
valem para a sessão inteira e sobrepõem hábitos gerais.

Anote `git rev-parse HEAD`: é a ref-base do portão no fechamento.

(Repo sem o lançador do portão: leia o "🔎 Agora" + o bloco ativo e confira o baton contra o Board na
mão — são 5 segundos — e recomende o `update`.)

## 3. Nota de sessão — classifique antes de tocar em qualquer tarefa

Se houver texto depois do slug, ele **precede e condiciona** o baton. Classifique-o antes de executar;
não comece a executar para só depois "encaixar" a nota.

- **(A) Briefing — só carregar contexto.** Sinais: "só carregar o contexto", "onde paramos", "não
  execute ainda", "me explique", "resumo do estado". Apresente: onde parou · ponto de entrada · gates 🔁
  pendentes · decisões em aberto · qual seria a próxima ação se mandasse executar. **E pare**,
  aguardando ordem explícita. Nada de efeito colateral: não marque checkbox, não rode comando, não edite
  arquivo e não rearme setup vivo.
- **(B) Diretivas de execução.** "Só a tarefa T3", "pule o passo X", "use o cluster Y", "sem commit
  hoje", "seja verboso nos números". Ecoe em 1-3 linhas as diretivas entendidas e como cada uma altera
  o ponto de entrada ou os gates; então execute já sob elas. Diretiva do usuário vence o PLAN no que for
  operacional.
- **(C) Misto** (contexto + diretiva) — o caso comum. Briefing de (A), e só execute se a nota contiver
  ordem explícita de executar; na dúvida, briefing + pergunta de 1 linha.
- **Conflito com o contrato do bloco = PARADA, não improviso.** Diretiva que muda DoD, ordem de blocos
  ou escopo do contrato, ou que pede pular um gate 🔁, é (re)planejamento: exponha o conflito (o que o
  PLAN diz × o que a nota pede), ofereça as opções e peça a decisão.
- **Diretivas são efêmeras:** valem para esta sessão e não entram no PLAN, salvo se o usuário disser que
  são permanentes ou se alterarem o contrato (aí é edição de Planejador).

## 4. Papel pelo baton — não pergunte se ele existe

O baton define o **papel**; a nota define **se e como** se executa agora (em briefing, o papel continua
o do baton, mas a sessão para no briefing).

- **`⚙️ Executor`** → sessão de Executor. Diga em 2-3 linhas onde parou e o ponto de entrada e
  **comece a executar** dali, à risca, marcando checkboxes — não pare para perguntar o papel. Daí em
  diante vale o loop de `referencia/protocolo.md` (seção "O Executor não escolhe quando parar"):
  tarefa concluída não encerra sessão nem resposta.
- **`🧠 Planejador`** → entre planejando: detalhar, replanejar, preparar o `handoff`.
- **Baton ausente ou ambíguo** → só aí resuma o estado e pergunte o papel.

## 5. Gates por-sessão não são retrabalho

Só quando se vai executar (em briefing, pule). Antes de executar, reestabeleça os gates 🔁 do ponto de
entrada: reverificar o DoR e rearmar o setup vivo (carga, probe, shells, `export KUBECONFIG`, processos
que não sobrevivem entre sessões). É pré-condição normal, não estado perdido: os resultados já feitos
estão persistidos (`[x]` + relatório). Deixe isso explícito ao usuário, para não parecer que se está
refazendo trabalho.

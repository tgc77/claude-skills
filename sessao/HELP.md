# 📘 Help — skill `sessao`

> Mostrado por `/sessao help` (no Codex, `$sessao help` ou `@sessao help`). É um **índice**: as regras
> completas estão nos arquivos citados abaixo. Se este guia e eles divergirem, eles vencem.

## O que é

Sistema para tocar um projeto de escopo definido (sprint, épico, migração, POC) com agentes de I.A.,
com sessões enxutas de contexto e sem perda de continuidade, mesmo que cada sessão comece do zero e
modelos diferentes assumam o trabalho. Cada fato mora em um arquivo; o plano se detalha em
rolling-wave; um modelo forte planeja (🧠) e um modelo barato executa (⚙️).

## Quando é acionada

Só por invocação explícita. Para operar um escopo: `/sessao start <slug>`. Os outros subcomandos fazem
só o que pedem. Fora disso, o agente trata o pedido como avulso — não lê PLAN, não deduz escopo pela
branch e não roda ritual.

## Subcomandos

| Comando | O que faz | Altera o repo? |
|---|---|---|
| `/sessao escopos [<slug>]` | lista os escopos: slug, descrição, estado, branch, bloco ativo, baton, última atualização | não |
| `/sessao init` | abre um escopo (num repo virgem, instala o sistema); levanta os dados com você e confirma antes de criar | sim, com o seu ok |
| `/sessao start <slug> [nota]` | início de sessão: confere o baton e assume o papel que ele manda | conforme o papel |
| `/sessao handoff` | 🧠 → ⚙️: bloco executor-ready, critérios medidos, o seu aceite | sim, com o seu ok |
| `/sessao end` | fim de sessão: registro sempre; relatório só se o bloco fechou ou você pediu | sim, com o seu ok |
| `/sessao update` | põe o projeto em dia com a skill (bloco gerenciado do `AGENTS.md`, lançador do portão, ambiente do OpenSpec) | sim, com o seu ok |
| `/sessao help` | este guia | não |

## Ciclo de vida

1. `init` cria o PLAN com o B1 detalhado e o resto em rascunho; o baton fica com o 🧠 Planejador.
2. `handoff` deixa o B1 executor-ready e, com o seu aceite, passa o baton ao ⚙️ Executor.
3. `start <slug>` com baton ⚙️: o Executor executa o bloco em loop até uma condição terminal.
4. O bloco fechou → auto-`end` com relatório. Parou no meio → registro sem relatório. Nos dois casos, o
   baton volta ao 🧠 e o agente pede o seu ok para commitar.
5. `start <slug>` com baton 🧠: o Planejador detalha o próximo bloco e volta ao passo 2, até o escopo
   fechar (🟢 no índice; a pasta fica como histórico).

## `start` com nota — exemplos

```text
/sessao start poc-benchmark só carrega o contexto de onde paramos, não execute nada ainda
   → briefing: onde parou, ponto de entrada, gates 🔁, decisões abertas, próxima ação. E para.

/sessao start poc-benchmark onde paramos? o cluster tá fora do ar hoje
   → briefing + o que depende do cluster e o que dá para fazer sem ele.

/sessao start poc-benchmark pode seguir, mas só as tarefas de código, sem commit
   → ecoa as diretivas, ajusta o ponto de entrada e executa sob elas.

/sessao start poc-benchmark pula o bloco B7 e vai pro B8
   → conflito com o contrato (ordem de blocos): para e devolve a decisão para você.

/sessao start
   → sem slug: lista os escopos e pergunta qual.
```

## Conceitos em uma linha

- **Baton** — a linha `🎬 Próximo:` do PLAN; diz o papel da próxima sessão. É a linha que conta, não a
  prosa em volta.
- **Gate 🔁 × marco** — o gate (DoR, carga, probe, `KUBECONFIG`) se refaz em toda sessão; o marco
  (`[x]` + relatório) persiste. Refazer gate não é retrabalho.
- **Aceite** — `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)`, escrito só depois de você ver e aceitar
  o plano. Responder às perguntas do agente não é aceitar.
- **Portão** — `scripts/conferencia_saida.sh`: confere o registro antes do commit (vermelho é parada),
  o baton no início (`--inicio`) e devolve o estado do escopo em JSON (`--estado`).
- **Bloco gerenciado** — o trecho do `AGENTS.md` entre `<!-- sessao:inicio` e `<!-- sessao:fim -->`,
  que declara a ativação explícita; o `update` o mantém igual ao template.
- **Módulo OpenSpec** — todo escopo novo: o contrato de cada bloco declara a sua change (proposta +
  delta das specs, arquivada quando o bloco conclui) ou "não se aplica — <motivo>". O item ⑦ do portão
  confere.
- **Apontamentos** — toda sessão que termina grava uma entrada em `<work-log>/<slug>.md`, só depois do
  seu ok; `/resumo-trabalho gerar <slug>` dá o dia completo.

## Onde está cada coisa

| Quero saber… | Arquivo |
|---|---|
| como cada subcomando funciona | `subcomandos/<nome>.md` |
| papéis, baton, quando o Executor para | `referencia/protocolo.md` |
| como a sessão fecha e o que o portão confere | `referencia/conferencia.md` |
| como o apontamento é gravado | `referencia/apontamentos.md` |
| layout do projeto, slug, troca de escopo | `referencia/layout.md` |
| entrega destinada a deploy | `referencia/deploy.md` |
| specs vivas: change, validação, archive, ambiente do OpenSpec | `referencia/openspec.md` |
| por que uma regra existe | `HISTORICO.md` |
| qual é a versão e o que mudou em cada uma | `VERSION` e `CHANGELOG.md` |

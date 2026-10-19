# Apontamentos — integração com o `resumo-trabalho`

> Lido por `end` e `handoff`. Toda sessão que termina grava a sua entrada no log, e o
> `/resumo-trabalho gerar <slug>` do dia sai completo, sem `registrar` manual.

## 🔑 Invariante: uma sessão que termina = UMA entrada no log

O índice é a **sessão** — não o relatório, e muito menos o subcomando. `end`, `handoff` e toda PARADA
no meio de bloco gravam a entrada da sessão: executor que fechou bloco, executor que parou no meio,
planejador que fez handoff, sessão de validação que não tocou em código. Relatório é matéria-prima
quando existe, não a condição para registrar.

⛔ **Só depois de o usuário validar o commit** (ordem em [`conferencia.md`](conferencia.md)). Validou
⇒ escreva, sem novo pedido. Não validou ⇒ nada é escrito.

## Onde

- O log do escopo é `<work-log>/<slug>.md`, com `<work-log>` = `$SESSAO_WORKLOG_DIR` se definida,
  senão `~/.claude/work-log` (só o endereço do arquivo; qualquer ferramenta lê e escreve nele).
- **O label é o slug.** Não procure campo "label" no PLAN. PLAN antigo que declare label diferente do
  slug é inconsistência de identidade: avise e pergunte qual dos dois nomes vale (o que tem histórico
  no log costuma vencer), em vez de escrever nos dois.
- Log ainda inexistente: crie-o com `# Label: <slug>` na 1ª linha (o formato que o
  `resumo-trabalho listar` lê).
- O log é **append-only, global e fora do repo**: não entra no commit.

## A chave da sessão — sai da linha dela no §8, nunca da memória

| §8 do PLAN | Chave | Exemplo no log |
|---|---|---|
| sem coluna de número (template atual): `\| 2026-09-24 \| B5 \| … \|` | `<AAAA-MM-DD>#<k>`, com k = posição da linha entre as linhas do §8 com a mesma data, contando de cima | `**Sessão:** 2026-09-24#2 · B5 (⚙️ Executor)` |
| com coluna de número (dialeto legado): `\| 11 \| 2026-09-04 \| … \|` | o número | `**Sessão:** 11` |

Data em `DD/MM/AAAA` entra normalizada para `AAAA-MM-DD`. Por isso o §8 é **append-only**: cada sessão
acrescenta a sua linha no fim; inserir linha no meio desloca o k das outras. É a mesma chave que o item
⑤ do portão confere, e ele diz qual falta.

## Como gravar

1. **Levante as sessões de HOJE que ainda não estão no log** — não só a sua. Calcule a chave de cada
   linha do §8 com a data de hoje e procure `**Sessão:** <chave>` no log: chave ausente é buraco a
   preencher, inclusive de sessão anterior que não registrou.
2. **Fonte de cada entrada, nesta ordem:** o relatório da sessão, se existir; senão, a linha do §8 + a
   entrada de Decisões (§7) que aquela sessão gravou + os commits dela. Nada é inventado fora dessas
   fontes. Se uma sessão antiga não deixou rastro suficiente, diga isso ao usuário em 1 linha em vez de
   preencher com suposição.
3. **Idempotência:** chave já presente no log ⇒ pule. Senão, faça **append** de uma entrada densa e
   factual (formato do `resumo-trabalho`: O que foi feito / Problemas-Correções / Validações /
   Pendências). Logo abaixo do cabeçalho `## [data hora] <projeto>`, grave as duas linhas de rastreio:
   - `**Relatório-fonte:** <caminho>` — ou `— sessão sem relatório. Fonte: <§8/§7/commits>`;
   - `**Sessão:** <chave>`, com a chave **logo depois dos dois-pontos**; texto livre só depois dela
     (`**Sessão:** 2026-09-24#2 · B5 (⚙️ Executor)`). É essa linha que torna o passo idempotente e que o
     portão procura.
4. **Horário do cabeçalho = quando a sessão aconteceu**, não a hora em que você escreve. Para sessão
   anterior, tire dos commits dela (`git log --date=format:'%Y-%m-%d %H:%M'`) e marque a entrada como
   *registrada retroativamente*.
5. Confirme em 1 linha quais sessões viraram entrada (ou "nada novo a registrar").

## Pedido de resumo dentro de um escopo é DAQUELE escopo

"Registre e gere os apontamentos de hoje" no contexto de um escopo (durante a sessão ou logo após o
`end`/`handoff`) resolve para `gerar <slug>` — **um** arquivo, `<work-log>/<slug>.md`. Não varra
`<work-log>/*.md` e não use `gerar dia`: "hoje" filtra a data **dentro** do escopo, não amplia a busca.
O apontamento é colado num card específico do GitLab, e misturar labels entrega à chefia trabalho de
outra frente, em outro repo. `gerar dia` só com pedido explícito de agregar todos os cards. Depois de
um `end`/`handoff` que já registrou, não registre de novo: confirme a idempotência e só gere.

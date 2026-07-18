---
name: resumo-trabalho
description: >-
  Registra o que foi feito em cada sessão de trabalho, organizado por label/card do GitLab (uma
  atividade pode envolver mais de um projeto), e gera o resumo no modelo "Apontamentos" padrão do
  usuário (markdown GitLab, pt-BR, copiável) — por card ou agregado do dia. Use quando o usuário
  definir um label/card ("/resumo-trabalho label X", "vou trabalhar no card X"), pedir para
  registrar/anotar o que foi feito, ou pedir um resumo ("/resumo-trabalho gerar X", "resumo do card
  X", "resumo do dia", "apontamentos"). Funciona entre projetos diferentes: o log é global (não fica
  dentro de um repo), então sessões em repos distintos no mesmo dia/card alimentam o mesmo resumo.
---

# Skill: resumo-trabalho — Registro por card e resumo no modelo "Apontamentos"

O modelo de trabalho do usuário é por **card do GitLab**: cada atividade tem um identificador, às
vezes toca mais de um projeto, mas o resumo final é entregue **por card** (colado no GitLab). Por
isso o log é organizado por **label** (= card), não por dia — um card pode levar mais de uma sessão e
mais de um dia.

- **Log global, um arquivo por label:** `~/.claude/work-log/<label-slug>.md`. Fora de qualquer
  projeto — é assim que agrega sessões de repos diferentes para o mesmo card.
- **Modelo do resumo final:** `templates/template-apontamentos.md`, ao lado deste arquivo. Fonte
  única — se o usuário pedir pra mudar o formato, editar esse arquivo, não duplicar em outro lugar.
- **Integração com a skill `sessao`:** se um projeto usa o Controle de Sessões (`sessao`) e tem um
  **label de apontamento** no seu `AGENTS.md`, o `sessao end` **alimenta este log automaticamente** — cada
  `RELATORIO_*_<dia>.md` fechado no dia vira uma entrada `registrar` (marcada com a linha
  `**Relatório-fonte:** <caminho>` p/ idempotência: o `end` não re-registra um relatório já presente).
  Essas entradas são iguais às manuais — `gerar` as trata do mesmo jeito. Se um dia sair incompleto,
  cheque se os relatórios daquele dia foram registrados (o `end` pode não ter rodado numa sessão).

## Sintaxe (args após `/resumo-trabalho`; primeiro token = subcomando)

| Comando | Efeito |
|---|---|
| `label <card-id>` | Define o label ativo **desta conversa**. Todo `registrar` seguinte nesta sessão usa esse label até o usuário trocar. |
| `registrar [<card-id>] <texto opcional>` | Registra o que foi feito. Com `<card-id>` explícito, usa (e também passa a ser) o label ativo da sessão. Sem `<card-id>`, usa o label já ativo. Sem label ativo nem informado: **pergunte o card antes de registrar** — não invente nem use um label genérico por conta própria. |
| `gerar <card-id>` | Resumo daquele card com as entradas de **hoje** (padrão — é o apontamento diário do card). |
| `gerar <card-id> <AAAA-MM-DD>` | Resumo daquele card com as entradas de uma data específica (retroativo: esqueceu de fechar ontem, por exemplo). |
| `gerar <card-id> completo` | Resumo com TODO o histórico daquele card (todas as datas registradas). |
| `gerar dia` | Resumo agregado: todos os cards com entrada **hoje**, uma subseção por card. |
| `gerar dia <AAAA-MM-DD>` | Mesma agregação, mas para uma data específica em vez de hoje. |
| `listar` | Lista os labels existentes (arquivo, contagem de entradas, datas com registro). |

Também aceite linguagem natural equivalente ("vou trabalhar no card X" = `label X`; "anota isso no
card X" = `registrar X ...`; "resumo do card X" = `gerar X`; "resumo de ontem do card X" = `gerar X
<data de ontem>`; "resumo do dia"/"apontamentos" sem card = `gerar dia`). Sem argumento e sem
conseguir deduzir → pergunte.

**Trabalho diário num card que dura vários dias:** o fluxo normal é `registrar` ao longo de cada dia
que você mexe no card (quantas vezes quiser) e, no fim daquele dia, `gerar <card-id>` — que por
padrão já filtra só as entradas de hoje, então funciona como o apontamento diário daquele card sem
misturar com os dias anteriores. O arquivo do label acumula o histórico completo (todos os dias),
mas cada `gerar <card-id>` sem data extra te dá só o "hoje" pra colar no card.

## Slug do label

Derive o nome de arquivo do label informado: minúsculas, espaços/caracteres não alfanuméricos viram
`-`, colapse hífens repetidos, sem hífen nas pontas. Ex.: `CARD-123` → `card-123.md`; `Prefect #45` →
`prefect-45.md`. Guarde o texto original do label na primeira linha do arquivo (`# Label: <original>`)
pra exibir bonito depois, mesmo que o slug normalize a grafia.

## `registrar` — passo a passo

1. Resolva o label: explícito no comando > label ativo da sessão > pergunte (nunca invente).
2. Descubra data e hora atuais (`date '+%Y-%m-%d %H:%M'`) e o "projeto" (nome do diretório/repo git
   atual; pergunte se não for óbvio).
3. `mkdir -p ~/.claude/work-log/`. Se `<label-slug>.md` não existir, crie com `# Label: <original>` na
   primeira linha antes da primeira entrada.
4. Acrescente (append, nunca reescreva entradas existentes) neste formato:

   ```
   ---
   ## [AAAA-MM-DD HH:MM] <projeto>

   **O que foi feito:**
   - ...

   **Problemas/Correções:**
   - **`arquivo ou componente`**: problema → ação tomada (status)

   **Validações:**
   - ...

   **Pendências:**
   - ...
   ```

   Omita subseções vazias. Escreva denso e factual (nomes de arquivo, causa raiz, comandos
   relevantes) — é matéria-prima do resumo final, não resuma demais aqui.
5. Confirme em 1 linha (label usado + projeto), sem reescrever o conteúdo todo no chat.

## `gerar` — passo a passo

1. Resolva o(s) label(s) e a data alvo:
   - `gerar <card-id>` → leia `~/.claude/work-log/<label-slug>.md`. Sem argumento extra, filtre só as
     entradas com data de **hoje**. Com `completo`, use todas as datas. Com uma data explícita
     (`AAAA-MM-DD`), filtre só as entradas daquele dia.
   - `gerar dia [<AAAA-MM-DD>]` → varra `~/.claude/work-log/*.md`, colete entradas datadas do dia alvo
     (hoje, se omitido) em qualquer arquivo, agrupe por label.
2. Se o arquivo do label não existir ou não houver entradas no escopo pedido: avise e ofereça gerar a
   partir só da conversa atual (perguntando o card, se ainda não souber) em vez de inventar dados.
3. Leia `templates/template-apontamentos.md` e sintetize as entradas no modelo exato — você decide
   como mapear o conteúdo livre nas seções fixas (Objetivo, O que foi feito com subseções por
   tema/projeto, Problemas em tabela, Validações, Diagnóstico final, Resultado prático, Pendências).
   Em `gerar dia`, uma subseção de "O que foi feito" por card. Não invente itens fora dos registros.
4. Substitua `DD/MM/AAAA` pela data real.
5. **Referências de MR/issue SEMPRE cross-project totalmente qualificadas.** O apontamento é colado
   num card que quase sempre vive em **outro** projeto do GitLab. Uma referência curta (`!1`, `#4`)
   resolve para o MR/issue de **mesmo número no projeto do card** — repo ERRADO. Portanto: nunca
   escreva `!1`/`#4` soltos; use sempre `grupo/projeto!1` (ou `grupo/projeto#4`), ou a URL completa
   do MR. O `grupo/projeto` é o do repo onde o MR/issue realmente está (o "projeto" da entrada do
   log), não o do card. Ex.: MR !1 do `sfz-cobranca-cnpg-clusters-chart` → escrever
   `<grupo>/sfz-cobranca-cnpg-clusters-chart!1`. Se não souber o caminho de grupo do projeto,
   pergunte ou use a URL completa — não deixe a referência curta.
6. **Entrega:** sempre dentro de fence de 4 crases (` ```` `) — ou `~~~` se o conteúdo tiver blocos de
   código internos — pra colar markdown cru no GitLab sem render no terminal. GitLab Flavored
   Markdown (tabelas padrão, emojis unicode).

## Regras invioláveis

- Log **append-only**, **global** (fora de projetos), **um arquivo por label**, nunca por dia.
- Label é **obrigatório** em todo `registrar`. Sem label ativo nem informado, pergunte — nunca crie um
  label genérico ou adivinhe o card por conta própria.
- O modelo do resumo vive só em `templates/template-apontamentos.md` desta skill.
- **Nunca** referencie MR/issue por número curto (`!1`, `#4`) no resumo — sempre `grupo/projeto!N` ou
  URL completa, apontando pro repo onde o MR/issue de fato está (o card costuma viver em outro projeto).
- Não gere resumo por suposição: baseie-se nas entradas registradas e/ou na conversa atual; pergunte
  se faltar dado para alguma seção do template.

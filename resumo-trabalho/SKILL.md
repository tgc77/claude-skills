---
name: resumo-trabalho
description: >-
  Registra o que foi feito em cada sessão de trabalho, organizado por label/card do GitLab (uma
  atividade pode envolver mais de um projeto), e gera o resumo no modelo "Apontamentos" padrão do
  usuário (markdown GitLab, pt-BR, copiável) — por card e, só sob pedido explícito, agregado do dia.
  Use quando o usuário definir um label/card ("/resumo-trabalho label X", "vou trabalhar no card X"),
  pedir para registrar/anotar o que foi feito, ou pedir um resumo ("/resumo-trabalho gerar X", "resumo
  do card X", "resumo do dia", "apontamentos"). Pedido sem card NÃO é agregado do dia: resolve para o
  label/escopo ativo da conversa (o slug do escopo da skill `sessao` é o label) — "hoje" filtra data
  dentro daquele alvo, nunca o universo de busca. Funciona entre projetos diferentes: o log é global
  (não fica dentro de um repo), então sessões em repos distintos no mesmo dia/card alimentam o mesmo
  resumo.
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
- **Integração com a skill `sessao`: o label É o slug do escopo.** Num projeto que usa o Controle de
  Sessões, cada escopo tem um slug (`docs/sessoes/<slug>/`) que **é** o label deste log — não existe
  campo separado, e o arquivo é `~/.claude/work-log/<slug>.md`. O `end` **e** o `handoff` alimentam esse
  arquivo automaticamente: **uma sessão encerrada = uma entrada**, indexada pela **sessão** e não pelo
  relatório (sessão de handoff ou de validação não gera relatório e ainda assim registra). A
  idempotência vem das linhas de rastreio logo abaixo do cabeçalho — `**Relatório-fonte:** <caminho>`
  quando há relatório, e/ou `**Sessão:** <N>`. Essas entradas são iguais às manuais — `gerar` as trata do
  mesmo jeito.
  **Consequência para o `gerar`:** num repo com escopo ativo, o alvo do resumo **já está determinado** —
  é o slug. Não pergunte o card e não varra o diretório: leia o arquivo daquele slug. Se um dia sair
  incompleto, a causa provável é sessão que não chegou a `end`/`handoff` (nada foi registrado) — cheque
  isso em vez de compensar agregando outros labels.

## Sintaxe (args após `/resumo-trabalho`; primeiro token = subcomando)

| Comando | Efeito |
|---|---|
| `label <card-id>` | Define o label ativo **desta conversa**. Todo `registrar` seguinte nesta sessão usa esse label até o usuário trocar. |
| `registrar [<card-id>] <texto opcional>` | Registra o que foi feito. Com `<card-id>` explícito, usa (e também passa a ser) o label ativo da sessão. Sem `<card-id>`, usa o label já ativo. Sem label ativo nem informado: **pergunte o card antes de registrar** — não invente nem use um label genérico por conta própria. |
| `gerar <card-id>` | Resumo daquele card com as entradas de **hoje** (padrão — é o apontamento diário do card). |
| `gerar <card-id> <AAAA-MM-DD>` | Resumo daquele card com as entradas de uma data específica (retroativo: esqueceu de fechar ontem, por exemplo). |
| `gerar <card-id> completo` | Resumo com TODO o histórico daquele card (todas as datas registradas). |
| `gerar dia` | Resumo agregado: todos os cards com entrada **hoje**, uma subseção por card. ⚠️ **Só sob pedido explícito de agregação** — nunca o default de "resumo do dia" (ver o aviso abaixo da tabela). |
| `gerar dia <AAAA-MM-DD>` | Mesma agregação, mas para uma data específica em vez de hoje. Mesma ressalva. |
| `listar` | Lista os labels existentes (arquivo, contagem de entradas, datas com registro). |

Também aceite linguagem natural equivalente ("vou trabalhar no card X" = `label X`; "anota isso no
card X" = `registrar X ...`; "resumo do card X" = `gerar X`; "resumo de ontem do card X" = `gerar X
<data de ontem>`). Sem argumento e sem conseguir deduzir → pergunte.

> ⛔ **"resumo do dia"/"apontamentos" SEM card NÃO é `gerar dia` por padrão — resolva o alvo antes.**
> Pedido sem card resolve **nesta ordem**, e só o último caso é agregado:
> 1. **Label/escopo ativo nesta conversa** (definido por `label X`, por um `registrar` anterior, ou pelo
>    escopo da skill `sessao` que esta sessão operou — o slug do escopo **é** o label) → `gerar <esse label>`.
> 2. **Sem label ativo, mas o repo atual tem escopo do Controle de Sessões** → é o slug daquele escopo
>    (leia o índice do `CLAUDE.md`; se houver mais de um 🟡 ativo, **pergunte** qual).
> 3. **Só então**, e apenas se o usuário pedir **explicitamente** o agregado de **todos** os cards
>    ("resumo de tudo que fiz hoje, todos os cards", "agregado do dia") → `gerar dia`.
>
> **Por que esta ordem:** "hoje" é filtro de **data dentro do alvo**, nunca o universo de busca.
> Ler "tudo que foi feito hoje" como `gerar dia` faz o resumo de um card trazer trabalho de **outro
> card, em outro repo** — e o apontamento é colado num card específico do GitLab, então isso entrega à
> chefia trabalho que não pertence àquele card. **Caso real (17/08/2026):** logo após o `/sessao end` do
> escopo `airflow-es-remote-logging`, o pedido "apontamentos de tudo que foi feito hoje" foi lido como
> `gerar dia`; a varredura de `~/.claude/work-log/*.md` trouxe `aca-amortizacao`, frente sem relação
> nenhuma com a sessão. **Havendo escopo ativo, ele vence — sempre.**

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

## 🗣️ Regra do leitor não-técnico (OBRIGATÓRIA em `registrar` **e** `gerar`)

**Quem lê estes apontamentos é a chefia do usuário, não a equipe técnica.** São pessoas que conhecem o
projeto e o negócio, mas **não mexem no código nem no cluster**. Um apontamento cheio de jargão sem
apoio não é lido como "trabalho denso": é lido como "não entendi o que foi feito", e o trabalho perde
o crédito que merece.

> **Regra de ouro — as duas metades valem juntas:**
> **(1) NUNCA remova, suavize ou generalize o detalhe técnico.** Nomes de arquivo, métricas, flags,
> comandos, números e causa raiz entram **exatamente como ocorreram**. Transparência é o valor
> principal deste apontamento.
> **(2) NUNCA solte o detalhe técnico cru, sem preparação.** Todo termo que exige conhecimento
> especializado vem **precedido** de uma explicação curta que permita entendê-lo.
>
> Não é resumir mais. É **acrescentar uma camada de contexto antes do detalhe**. O apontamento fica um
> pouco mais longo — e isso é aceito e desejado.

### Teste do gatilho (aplique a cada termo; é mecânico, não subjetivo)

Um termo **precisa** de explicação se cai em alguma destas 4 categorias:

| Categoria | Exemplos | Precisa? |
|---|---|---|
| **Componente/ferramenta específica** do stack | `kube-state-metrics`, `cAdvisor`, PgBouncer, Authelia, CNPG, SeaweedFS | ✅ Sim, na 1ª menção |
| **Mecanismo não-óbvio** de infraestrutura | ConfigMap que não recarrega, PVC RWO single-attach, scrape interval, SD de pod | ✅ Sim, explique o *porquê* em 1 frase |
| **Código interno do projeto** | `D-B6-23`, `B6f/P2a`, `Q1-Q8`, nomes de bloco/contrato | ✅ Sim — diga o que o código designa |
| **Métrica ou unidade criada pela análise** | pod-segundos, CPU·min, cold-start decomposto, `datname` | ✅ Sim — diga o que mede e por que importa |

**NÃO explique** o que o público já domina — commit, branch, deploy, banco de dados, ambiente de
desenvolvimento, teste, versão. Explicar o óbvio é condescendente e desperdiça espaço.

### As 3 formas de explicar (use as três; cada uma tem limite de tamanho)

1. **Bloco de contexto no topo do resumo** — seção `## 🧭 Para entender este apontamento`, logo após o
   Objetivo. **3 a 6 itens**, **1 linha cada**, só os termos que o dia inteiro usa repetidamente.
   Formato: `- **<termo>** — <o que é, em linguagem de negócio>.`
   Se o dia teve menos de 3 termos que se repetem, **omita a seção** e use só as formas 2 e 3.
2. **Aposto inline na 1ª menção** — o termo aparece, seguido de travessão e explicação de **até ~15
   palavras**. A partir da 2ª menção, use o termo puro (não repita a explicação).
   Ex.: "o `kube-state-metrics` — o componente que traduz objetos do Kubernetes em métricas — passou a…"
3. **Frase de propósito abrindo cada subseção** — **1 frase**, antes dos bullets técnicos, dizendo
   *para que serviu* aquele conjunto de trabalho. Responde "por que isso importa?" antes do "o quê".

### Exemplo — antes e depois (siga este padrão)

❌ **Errado (cru — o detalhe está certo, mas ninguém de fora entende):**
```
- **D-B6-23:** sem `checksum/config` no pod template, o ConfigMap muda e o pod não é recriado;
  `up{job="cnpg-postgres"}` volta vazio e o Prometheus segue com a config antiga.
```

❌ **Também errado (explicado, mas o detalhe foi apagado — proibido):**
```
- Encontrado um problema de configuração no monitoramento, que foi diagnosticado e será corrigido.
```

✅ **Certo (explica antes, mantém tudo):**
```
- **D-B6-23 — o Prometheus continuou rodando com a configuração antiga.** O Prometheus é o serviço
  que coleta as métricas da POC, e ele lê sua configuração de um arquivo entregue pelo Kubernetes
  (um "ConfigMap"). O problema: o Kubernetes só reinicia o serviço quando o *nome* desse arquivo
  muda — não quando o *conteúdo* muda. Resultado: a configuração nova foi entregue e ignorada, sem
  erro nenhum. Tecnicamente: falta a anotação `checksum/config` no template do pod, e o sintoma é
  `up{job="cnpg-postgres"}` retornar **vazio** (job inexistente na configuração carregada) em vez de
  `0` (job existente com alvo caindo) — pod de pé há 3d21h.
```

**A estrutura do ✅ é sempre a mesma, nesta ordem:** título em negrito com o efeito em linguagem
comum → 1-2 frases de contexto → o detalhe técnico completo, introduzido por "Tecnicamente:" ou
equivalente.

### Anti-padrões (rejeite se aparecerem)

- **Glossário no fim** do documento — a explicação tem de vir **antes** do termo, não depois.
- **Trocar o termo técnico por paráfrase** ("um componente de métricas" em vez de
  `kube-state-metrics`) — o nome exato precisa aparecer, é o que torna o apontamento rastreável.
- **Repetir a explicação** a cada menção do mesmo termo — só na primeira.
- **Explicar o óbvio** (commit, deploy, branch) ou virar tutorial de Kubernetes.
- **Diluir número em adjetivo** — "melhorou bastante" no lugar de "11 s → 1 s". Número é o produto.

### Checklist antes de entregar (rode mentalmente, item a item)

- [ ] Todo termo das 4 categorias do gatilho tem explicação **na 1ª menção**?
- [ ] Nenhum detalhe técnico foi removido em relação ao que está no log?
- [ ] Cada subseção de "O que foi feito" abre com 1 frase de propósito?
- [ ] O bloco `🧭 Para entender este apontamento` tem 3-6 itens de 1 linha (ou foi omitido por não
      haver termos recorrentes)?
- [ ] Os números aparecem como números, não como adjetivos?
- [ ] Um gerente que conhece o projeto mas não mexe no código conseguiria explicar, com suas palavras,
      **o que foi feito e por que importa**, depois de ler uma vez?

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
5. **Aplique a Regra do leitor não-técnico já aqui**, nos itens que caem no teste do gatilho: cada
   achado técnico entra com o **efeito em linguagem comum** antes do detalhe cru. **Por que no log e
   não só no resumo:** quem `registrar` está com o contexto vivo na cabeça; quem `gerar` (muitas vezes
   outro modelo, dias depois) só tem o log. Se a explicação não for registrada agora, ela terá de ser
   **reconstruída** depois — e é aí que ela sai errada ou genérica. Explicação registrada uma vez é
   transportada de graça para todos os resumos futuros daquele card.
6. Confirme em 1 linha (label usado + projeto), sem reescrever o conteúdo todo no chat.

## `gerar` — passo a passo

1. Resolva o(s) label(s) e a data alvo. **Resolver o alvo é o passo 1 de verdade — não comece lendo
   arquivo.** Se o pedido veio sem card, aplique a ordem de resolução do aviso da seção "Sintaxe"
   (label ativo → escopo do repo → só então agregado) e **diga em 1 linha qual alvo assumiu**:
   - `gerar <card-id>` → leia `~/.claude/work-log/<label-slug>.md`. Sem argumento extra, filtre só as
     entradas com data de **hoje**. Com `completo`, use todas as datas. Com uma data explícita
     (`AAAA-MM-DD`), filtre só as entradas daquele dia.
   - `gerar dia [<AAAA-MM-DD>]` → varra `~/.claude/work-log/*.md`, colete entradas datadas do dia alvo
     (hoje, se omitido) em qualquer arquivo, agrupe por label. ⛔ **Só entre aqui com pedido explícito de
     agregação de todos os cards.** Um `ls`/glob em `~/.claude/work-log/` para descobrir "o que teve
     hoje" **não** é passo de reconhecimento inocente: é o que faz o card errado entrar no resumo.
     Havendo label ou escopo ativo, leia **um** arquivo — o dele.
2. Se o arquivo do label não existir ou não houver entradas no escopo pedido: avise e ofereça gerar a
   partir só da conversa atual (perguntando o card, se ainda não souber) em vez de inventar dados.
3. Leia `templates/template-apontamentos.md` e sintetize as entradas no modelo exato — você decide
   como mapear o conteúdo livre nas seções fixas (Objetivo, Para entender este apontamento, O que foi
   feito com subseções por tema/projeto, Problemas em tabela, Validações, Diagnóstico final, Resultado
   prático, Pendências). Em `gerar dia`, uma subseção de "O que foi feito" por card. Não invente itens
   fora dos registros.
4. **Aplique a Regra do leitor não-técnico e rode o checklist dela antes de entregar.** Não é opcional
   nem "quando sobrar espaço": é critério de aceitação do resumo. Se o log já traz a explicação
   (porque quem registrou aplicou a regra), **transporte-a** — não reescreva do zero nem invente uma
   nova. Se o log veio cru, é aqui que a camada de contexto é construída.
5. Substitua `DD/MM/AAAA` pela data real.
6. **Referências de MR/issue SEMPRE cross-project totalmente qualificadas.** O apontamento é colado
   num card que quase sempre vive em **outro** projeto do GitLab. Uma referência curta (`!1`, `#4`)
   resolve para o MR/issue de **mesmo número no projeto do card** — repo ERRADO. Portanto: nunca
   escreva `!1`/`#4` soltos; use sempre `grupo/projeto!1` (ou `grupo/projeto#4`), ou a URL completa
   do MR. O `grupo/projeto` é o do repo onde o MR/issue realmente está (o "projeto" da entrada do
   log), não o do card. Ex.: MR !1 do `sfz-cobranca-cnpg-clusters-chart` → escrever
   `<grupo>/sfz-cobranca-cnpg-clusters-chart!1`. Se não souber o caminho de grupo do projeto,
   pergunte ou use a URL completa — não deixe a referência curta.
7. **Entrega:** sempre dentro de fence de 4 crases (` ```` `) — ou `~~~` se o conteúdo tiver blocos de
   código internos — pra colar markdown cru no GitLab sem render no terminal. GitLab Flavored
   Markdown (tabelas padrão, emojis unicode).

## Regras invioláveis

- Log **append-only**, **global** (fora de projetos), **um arquivo por label**, nunca por dia.
- Label é **obrigatório** em todo `registrar`. Sem label ativo nem informado, pergunte — nunca crie um
  label genérico ou adivinhe o card por conta própria.
- **`gerar` também exige alvo resolvido, e "hoje" nunca é o alvo.** Pedido de resumo sem card resolve
  por **label ativo → escopo do repo → pergunta**; `gerar dia` (varredura de `~/.claude/work-log/*.md`)
  **só** com pedido explícito de agregar **todos** os cards. Havendo escopo ativo, ele **vence sempre** —
  misturar labels entrega ao card do GitLab trabalho que não é dele. Ver o aviso da seção "Sintaxe".
- O modelo do resumo vive só em `templates/template-apontamentos.md` desta skill.
- **Nunca** referencie MR/issue por número curto (`!1`, `#4`) no resumo — sempre `grupo/projeto!N` ou
  URL completa, apontando pro repo onde o MR/issue de fato está (o card costuma viver em outro projeto).
- Não gere resumo por suposição: baseie-se nas entradas registradas e/ou na conversa atual; pergunte
  se faltar dado para alguma seção do template.
- **A Regra do leitor não-técnico é critério de aceitação, não estilo.** Vale em `registrar` **e** em
  `gerar`, em qualquer modelo. Detalhe técnico **completo e transparente**, sempre precedido de
  preparação para ser entendido por quem não mexe no código. **Remover detalhe para "simplificar" é
  tão errado quanto despejar jargão cru** — os dois modos falham do mesmo jeito: a chefia não consegue
  avaliar o trabalho. Rode o checklist da regra antes de entregar.
- **Padrão de qualidade é o mesmo para todo modelo.** Este documento é a especificação do resultado
  esperado, e não muda conforme quem executa: as seções do template, a densidade factual (números,
  nomes de arquivo, causa raiz) e a camada de contexto são obrigatórias em toda entrega. Na dúvida
  sobre profundidade, **siga o exemplo ✅ da Regra do leitor não-técnico** — ele é a régua.

# Protocolo de sessão — artefatos, papéis, baton e execução

> Lido por `start`, `handoff` e `end`. O porquê de cada regra está em [`../HISTORICO.md`](../HISTORICO.md).

## Os artefatos (cada fato mora em um lugar só)

| Artefato | Papel (o único) | Entra no contexto |
|---|---|---|
| **Skill `sessao`** | o protocolo: papéis, ritual de fechamento, portão | quando invocada |
| **`AGENTS.md`** (raiz do repo) | índice de escopos, regras do projeto e o **bloco gerenciado** (ativação explícita). O `CLAUDE.md` só o importa (`@AGENTS.md`) | sempre (automático) |
| **`docs/sessoes/<slug>/PLAN.md`** | fonte única de verdade do escopo: parâmetros, guardrails, "🔎 Agora" com o baton, Board, bloco ativo, blocos futuros em rascunho, decisões, registro de sessões (§8) | no `start`: só o cabeçalho + o bloco ativo |
| **`RELATORIO_<bloco>_<data>.md`** | detalhe denso (problema → causa → solução → evidência), um por bloco fechado ou quando pedido | quase nunca: só para resgatar um detalhe |
| **Memória** (onde a ferramenta tiver) | ponteiros de alto nível entre sessões | índice sempre; detalhe sob demanda |

Atualize **in-place**: nunca crie uma segunda cópia de um campo que já existe, e nunca suba detalhe de
relatório para o PLAN.

## Rolling-wave

- Detalhe só o **bloco ativo** (e, no máximo, o próximo), com checklist e DoD. Os demais ficam em uma
  linha, marcados `(rascunho)`.
- Replanejar na fronteira do bloco é ritual, não desvio: revise ordem e conteúdo dos blocos futuros à
  luz do que aprendeu. A ordem pode mudar.
- Bloco ≈ 2–4 h de trabalho (uma sessão). Estimativa é guia de fatiamento, não SLA.

## Papéis

### 🧠 Planejador (modelo forte) — atua na fronteira do bloco

- Detalha o próximo bloco até ficar **executor-ready**, resolve as decisões de design, escreve o
  **Contrato de execução** (DoR, DoD verificável, critérios de aceite, decisões resolvidas,
  escalonamento, evidência a capturar) e replaneja os blocos futuros.
- Especifica **decisões e restrições, não keystrokes** — micro-roteirizar desperdiça os tokens caros.
  **Não implementa.**
- **Todo critério de aceite é MEDIDO no estado atual antes de virar alvo — nenhum é deduzido.** Rode o
  comando do critério no commit do handoff e escreva o valor observado ao lado do alvo. Se o baseline
  já reprova o critério, há duas saídas honestas: mudar o alvo, ou tornar a correção tarefa explícita
  do bloco. Critério escrito por raciocínio ("o código novo será vetorizado, logo o grep dará 0") nasce
  falso: é inatingível dentro do contrato, e quem paga é o Executor. Vale para grep, contagem de teste,
  diff, tempo — toda medida. **Grep de código mede a chamada** (`\.foo(`), não a palavra solta, senão
  um comentário correto reprova um código correto.
- **Bloco que muda comportamento descrito em documento de interface carrega a atualização dele como
  tarefa do bloco, com o arquivo nomeado** — não como lembrete no fim. Documento de interface é o que
  sai da equipe: o que vai ao chefe ou ao negócio, ao DBA, o README do escopo, um contrato publicado.
  Ele não emite erro ao envelhecer.

> ✅ **DoD do planejamento (executor-ready):** tarefas atômicas e ordenadas, cada uma com checagem de
> pronto verificável; comandos, paths e valores preenchidos **e medidos**; decisões resolvidas (ou
> marcadas como ponto de escalonamento); DoR satisfeito; risco e segurança anotados; documento de
> interface afetado listado como tarefa.

### ⚙️ Executor (modelo barato) — atua dentro do bloco

- Executa o bloco ativo **à risca**, marcando os checkboxes na hora. Desvios pequenos (retry, fix
  óbvio) ele resolve.
- **Não toma decisão de design.** Se a realidade divergir do plano (DoD inalcançável, estado
  inesperado, ambiguidade), **PARA**, registra em Blockers/Decisões do PLAN e devolve ao Planejador.
- Auto-verifica contra a DoD antes de declarar o bloco concluído.

### Tipo de bloco

- 🔧 **Mecânico** — passos conhecíveis → o Executor sozinho; é onde o split mais rende.
- 🔬 **Descoberta** — a execução produz o conhecimento → o Planejador conduz a 1ª passada; o Executor
  repete ou escala depois. Não escreva contrato fechado para o que ainda não foi descoberto.
- O split compensa quando a execução é muito maior que o planejamento. Bloco curto ou pura descoberta:
  um modelo só, porque o overhead do handoff come o ganho.

## ⚙️ O Executor não escolhe quando parar

Um `start` com baton `⚙️ Executor` inicia um **loop contínuo sobre o bloco ativo**, não a execução
avulsa da tarefa citada no ponto de entrada. Concluiu uma tarefa → valida o resultado, marca o checkbox
e começa imediatamente a próxima tarefa aberta do mesmo bloco. Concluir uma tarefa, atingir um "bom
checkpoint", produzir bastante trabalho, consumir muito tempo ou contexto, ou poder oferecer um resumo
**não são condições de parada**: o Executor não encerra a resposta, não devolve o controle, não reduz,
reordena ou reinterpreta o contrato e não troca o baton por causa delas.

**Condições terminais — lista fechada:**

1. o bloco inteiro satisfez a DoD → auto-`end` com relatório; pede a validação do commit e para na
   fronteira de papel;
2. a realidade divergiu do contrato e exige decisão de design, o estado ficou ambíguo ou inesperado,
   ou uma tarefa exigiria escolha não resolvida no PLAN → grava o motivo, devolve ao Planejador e para;
3. um critério de aceite mediu diferente do alvo → registra a saída crua, devolve ao Planejador e para;
4. falta autorização externa indispensável → pede a autorização e aguarda;
5. o usuário interrompe ou manda pausar ou encerrar;
6. um limite técnico real da ferramenta impede continuar nesta resposta → informa o impedimento
   concreto e preserva como ponto de entrada a primeira tarefa aberta.

**Toda condição terminal encerra a sessão pelo ritual** ([`../subcomandos/end.md`](../subcomandos/end.md)):
a 1 pela porta do fechamento de bloco (relatório + registro); a 2, a 3, a 4 e a 6 pela **3ª porta**
(registro sem relatório: PLAN in-place com o motivo, linha nova no §8, baton `🧠 Planejador`, e então
validação → apontamento → portão → commit); na 5, manda a ordem do usuário. **Parar não dispensa
registrar:** sessão que não deixa linha no §8 não existe para a próxima. Fora dessas seis condições,
emitir resposta final é violação do protocolo. Decisão ausente do contrato é a condição 2, nunca
licença para improvisar. Esta regra sobrepõe qualquer hábito geral de entregar progresso em
checkpoints convenientes.

## Critério de aceite não batido = PARADA, mesmo que a intenção pareça cumprida

Vale nos dois lados. O 🧠 **mede** todo critério antes de fixá-lo como alvo. O ⚙️ **não fecha** bloco
cujo critério mediu diferente do alvo — nada de 🟢 "com ressalva" — e nunca relê o critério pela
intenção que enxerga nele ("o alvo era 0 para garantir X, e o meu código faz X, então vale"). Quem
julga se um critério errado ainda serve é o 🧠. Registrar o achado com transparência **não** substitui
a parada.

## Fronteira de papel = PARADA de sessão

O Executor **nunca vira Planejador na mesma sessão**. Quando o baton viraria `🧠 Planejador` — o bloco
fecha e o próximo está em rascunho ou é 🔬, ou surge no meio da execução qualquer coisa que dê vontade
de (re)planejar (decisão de design, ambiguidade, estado inesperado, DoD inalcançável) — ele **para**,
grava `🎬 Próximo: 🧠 Planejador` + o motivo, registra a sessão e reporta. **Não** detalha o próximo
bloco, não escreve contrato novo e não faz uma 1ª passada de descoberta. Detalhar e executar um bloco
na mesma sessão de Executor é violação de protocolo, mesmo que "pareça pronto para seguir".

## O Executor fecha o próprio bloco

Ao satisfazer toda a DoD, o Executor **dispara o `end` por si** — relatório + PLAN in-place — sem
esperar pedido, e só então grava o baton. O que é auto-disparado é o **ritual, não o commit**: commit,
push e apontamento esperam a validação do usuário. Se a interrupção foi uma PARADA (condições 2, 3, 4
ou 6), ele dispara a 3ª porta, sem relatório. Isto não contradiz a fronteira de papel: ele fecha o
bloco terminado e para; não promove o próximo bloco de rascunho a detalhado.

**Relatório é ato explícito, com uma exceção só:** gere quando o usuário pedir ou no auto-`end` de
fechamento de bloco. Terminar no meio de um bloco não gera relatório — e não gerar relatório nunca
significa não registrar a sessão.

## 🎬 O baton

- O cabeçalho "🔎 Agora" carrega **sempre uma** linha
  `- **🎬 Próximo:** <⚙️ Executor | 🧠 Planejador> · **Ponto de entrada:** <tarefa>`, com os gates 🔁 a
  reestabelecer nas linhas de continuação. É a fonte de verdade do papel da próxima sessão: `init`,
  `handoff` e `end` a gravam; `start` a lê e age sem perguntar. Sem ela, o `start` fica adivinhando o
  papel.
- **O baton é a linha, não a prosa.** Escrever "baton → 🧠" no resumo da sessão, no relatório ou na
  mensagem de commit e deixar a linha com o papel e o ponto de entrada antigos entrega à sessão
  seguinte um bloco já fechado como se fosse tarefa aberta: ela entra no papel errado e refaz o que
  está pronto. Quem escreve atualiza **aquela linha**, in-place, antes do commit. Quem lê confere a
  linha contra o Board e para se as duas discordarem. O item ② do portão reprova o commit quando o
  parágrafo do baton não foi reescrito na sessão.
- **Um estado, um lugar:** cabeçalho, Board, §8 e mensagem de commit são resumos da linha 🎬.
  Divergiu, a linha vence e os resumos se ajustam a ela.

## 🔁 Gate por-sessão × marco

Um **marco** é resultado que persiste (medição, entrega → checkbox `[x]` + relatório). Um **gate
por-sessão** é pré-condição ou processo vivo que não sobrevive entre sessões (DoR "está saudável
agora?", armar carga, probe ou shells, `export KUBECONFIG`) e é reestabelecido em toda sessão de
execução — não é retrabalho nem estado perdido. No PLAN, marque gates com 🔁 (ex.: `🔁 T0 — DoR`,
`🔁 T1 — armar carga+probe`) em vez de checkbox de marco, para o Executor saber que os refaz sempre.

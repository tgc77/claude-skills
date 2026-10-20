# Histórico — por que cada regra existe

> **Não é preciso ler este arquivo para operar a skill.** Ele guarda os incidentes que criaram as
> regras. Antes de afrouxar, mover ou remover uma regra, leia o caso que a criou: quase todas nasceram
> de uma falha silenciosa — nada deu erro, só faltou alguma coisa, e alguém só percebeu depois. As
> regras em si moram em `SKILL.md`, `subcomandos/` e `referencia/`.

## 2026-07-22 — Deploy que "não mudou nada"

Commits destinados a deploy ficavam só locais, ou sem o job de build: o CI builda do remoto e o deploy
reusava o artefato anterior, sem erro nenhum. Pedir "deploya a versão X" sem nomear os jobs também já
tinha custado ciclos. → A cadeia de 4 elos (bump → commit + push → build → deploy da versão nova) e o
diagnóstico de 5 s. Onde está: `referencia/deploy.md`.

## 2026-08-05/06 — Um repo, vários escopos; escopo como argumento; slug sem apelidos

O `PLAN.md` na raiz quebrou quando um repositório ganhou a segunda frente de trabalho. → Um escopo =
uma pasta, o protocolo é um só. Um ponteiro de "escopo ativo" foi descartado: fica velho, é global
enquanto a sessão é local, e não acompanha a troca de branch. → O escopo é argumento. Duas grafias para
o mesmo escopo eram conflito de nome esperando acontecer. → Um escopo, um nome; rename é ato explícito.
Onde está: `referencia/layout.md`.

## 2026-08-17 — Baton trocado só na prosa (1ª vez)

A sessão 34 anunciou a troca de papel para 🧠 no resumo, no relatório e na mensagem de commit, e deixou
a linha 🎬 em `⚙️ 11.1`. A sessão seguinte entraria no papel errado e refaria um bloco pronto. → "O
baton é a linha, não a prosa." Onde está: `referencia/protocolo.md`.

## 2026-08-17 — Apontamento indexado por relatório

Só o `end` alimentava o log, e só quando havia relatório: todo `handoff` e toda sessão de validação
sumiam do apontamento, sem erro — o passo "rodava com sucesso" porque não havia o que coletar. Num dia
de 4 sessões, 2 ficaram fora. → Invariante "uma sessão = uma entrada"; o `handoff` passou a registrar.
Onde está: `referencia/apontamentos.md`.

## 2026-08-17 — Resumo do dia com trabalho de outro card

Logo após o `end` do escopo `airflow-es-remote-logging`, a varredura global do work-log trouxe
`aca-amortizacao` para dentro do resumo. → Pedido de resumo dentro de um escopo é daquele escopo;
`gerar dia` só com pedido explícito. Onde está: `referencia/apontamentos.md`.

## 2026-08-18 — Documento de interface envelhecido

Dois blocos mudaram a cascata de regras e a persistência; o documento entregue à chefia continuou
anunciando duas estratégias trocáveis por flag que já tinham sido removidas. Só apareceu numa
auditoria pedida por desconfiança, dois meses depois. → Item 8 da Conferência e "documento de
interface é tarefa nomeada do bloco". Onde está: `referencia/conferencia.md`,
`referencia/protocolo.md`.

## 2026-08-19 — Baton trocado só na prosa (2ª vez) → o portão

A sessão 44 repetiu o defeito (baton preso em `⚙️ 16.1`) com a regra já escrita, em sessão que relatou
tudo com honestidade. Conclusão: conferência auto-atestada mede a intenção de quem executa, não o
arquivo. → A Conferência de saída virou o portão executável `scripts/conferencia_saida.sh` (item ②).

## 2026-08-24 — Contrato commitado sem aceite

Uma sessão de Planejador escreveu um contrato de 17 tarefas e 15 critérios, passou o baton para ⚙️ e
commitou duas vezes sem o usuário ter visto o plano: responder às perguntas do agente foi tomado como
aceite. A regra "questionamento aberto = registro congelado" estava escrita em três lugares (AGENTS.md,
memória e skill), e o portão deu verde porque não tinha item de aceite. → Item ⑥ e a linha
`**Aceite:**`.

## 2026-08-24 — O portão aprovava sem conferir

Uma auditoria achou o portão escrito contra o dialeto de um repositório (`### 📋 Tarefas`, critérios
em tabela, sessões numeradas) enquanto o `PLAN.template.md` gerava outro. Em projeto novo, ③④⑤ saíam
⚠️ e o ⑥ nem rodava — exit 0 com 2 dos 6 itens valendo. → `scripts/autoteste_portao.sh`, que monta
repositórios a partir dos templates e afirma que cada item dispara.

## 2026-08-24 — Push automático revertido

A regra de deploy autorizava o push "sem esperar o usuário pedir". Revertida: push publica para fora e
não se desfaz sem estrago, e o risco de um push indevido é maior que o de um deploy que não pegou. →
Push sempre com validação própria. Onde está: `referencia/deploy.md`.

## 2026-08-28 — O autoteste commitou no repositório da skill

`montar` era chamada em subshell (`$(montar)`), o `cd` não persistia, e um cenário rodou `git add -A`
e `git commit` no repositório real. → Trava de sandbox no autoteste.

## 2026-08-29 — Falso positivo do ③

Num PLAN real, `T2` aparecia 24 vezes como `[x]` e 5 como `[ ]` (ids reusados entre blocos), e o grep
global acusava baton podre sem fundamento — e vermelho é parada. → Id ambíguo vira ⚠️, nunca 🔴; o ③
passou a reconhecer `T1`, `T4.1b` e `11.1`. Os scripts saíram de `templates/` para `scripts/`.

## 2026-09-01 — Executor parando em checkpoint

O Executor encerrava a resposta ao concluir uma tarefa ou num "bom checkpoint", devolvendo o controle
sem condição de parada real. → Lista fechada de condições terminais. Onde está:
`referencia/protocolo.md`.

## 2026-09-04 — PARADA sem registro; invocação implícita

Uma sessão de Executor parou por critério não batido e registrou tudo com honestidade dentro do bloco,
mas não deixou linha no §8 nem entrada no apontamento: o passo que as grava só era alcançado por `end`
e `handoff`. Sem commit, o portão também não rodou; a sessão seguinte preencheu retroativamente. →
A 3ª porta do `end`. Onde está: `subcomandos/end.md`. No mesmo dia, a regra de invocação explícita
ganhou `agents/openai.yaml`: texto sozinho não impede invocação implícita.

## 2026-09-07 — Portão copiado congelado

O `init` copiava o portão inteiro para cada repositório; toda correção parava na skill, e um escopo
instalado em agosto seguia rodando o portão de agosto. → O lançador
(`scripts/conferencia_saida.shim.sh`), que acha a skill em runtime e falha fechado (exit 2). No mesmo
dia: o ③ passou a reconhecer checkbox de gate 🔁; registro retroativo; e a decisão de **não migrar**
os escopos legados (§8 numerado, PLAN na raiz, índice no `CLAUDE.md`) — por isso o suporte a eles nos
scripts é deliberado.

## 2026-09-08 — O ② cego às continuações do baton

O ② olhava só a 1ª linha física do baton. Uma sessão de conferência de handoff que corrigiu um aviso
nas linhas de continuação, mantendo — corretamente — papel e ponto de entrada, foi reprovada como se
não tivesse passado baton. → O ② compara o parágrafo inteiro.

## 2026-09-11 — Aceite invisível ao diff

Dois blocos aceitos pela mesma pessoa no mesmo dia geravam linhas `**Aceite:**` idênticas byte a byte;
o diff tratava a segunda como contexto e o ⑥ reprovava um aceite que existia. → `(bloco <id>)`
obrigatório na linha de aceite.

## 2026-09-16 — Decisão pedida por rótulo

No fim da T1 do escopo `dag-amortizacao-refactor`, o agente pediu a reordenação "T3 antes de T2" sem
dizer que a T3 era levantar o plano de execução da query base (`DBMS_XPLAN`) e a T2 era escolher a
janela de comparação. O usuário não tinha como decidir sem abrir o PLAN. → Regra "identificador
sozinho não é contexto". Nasceu no `AGENTS.md` de três repositórios da SEFAZ; desde a 3.1.0 mora na
skill, no `SKILL.md` (regras invioláveis) e no bloco gerenciado do `AGENTS.template.md`.

## 2026-09-24 — 2ª sessão do dia aprovada sem registro

O ⑤ aprovava se houvesse qualquer entrada de hoje no log, então a 2ª sessão do dia que não registrou
passava. E o PLAN de um escopo novo, ainda fora do git, deixava o diff vazio. → Chave por sessão
(`<data>#<k>` ou nº) conferida linha a linha; PLAN não rastreado comparado contra o vazio.

## 2026-10-19 — Protocolo copiado envelhecendo; ativação implícita pelo AGENTS.md

Uma análise comparando a skill com o OpenSpec achou:

- o `init` copiava ~25 KB de protocolo para o `AGENTS.md` de cada repositório, e as cópias tinham
  congelado: quatro repositórios não descreviam a chave de sessão que o portão já cobrava, três não
  tinham a 3ª porta e dois ainda rodavam a cópia integral do portão;
- o mesmo `AGENTS.md`, carregado em toda sessão, mandava identificar o escopo e ler o PLAN no início de
  qualquer sessão, contradizendo a regra de invocação explícita;
- o `SKILL.md` (~28 mil tokens, carregado inteiro até para um `escopos`) pesava justamente no modelo
  barato do Executor, e as mesmas regras se repetiam em `SKILL.md`, `HELP.md` e no template.

→ Conceitos trazidos do OpenSpec, sem depender dele: o protocolo mora só na skill; o `AGENTS.md`
carrega um bloco gerenciado curto, sincronizado pelo `update` (`scripts/bloco_agents.sh`, como o
`openspec update`); o `start` exige o slug escrito; o `SKILL.md` virou roteador com um arquivo por
subcomando; os incidentes vieram para este arquivo; e o portão ganhou o `--estado`, com o estado do
escopo em JSON (como o `openspec status --json`). No mesmo dia, o ⑥ deixou de exigir o seletor de
variação U+FE0F no `⚙️`: um baton "⚙ Executor" o deixava cego.

## 2026-10-19 — Comportamento entregue sem registro vivo

A mesma análise achou que o `PLAN.md` guarda bem a execução (tarefas, baton, registro), mas o que o
sistema passava a **fazer** depois de cada bloco não tinha registro vivo: ficava espalhado em relatórios,
documentos de interface e no código, e o item 8 da Conferência era a única defesa, conferida na mão.
Aqui o valor está na ferramenta (validar o delta e fundi-lo nas specs ao arquivar), então a escolha foi
**integrar** o OpenSpec, e não replicá-lo. → Módulo OpenSpec: todo escopo novo nasce com ele; o
contrato de cada bloco declara a sua change ou `não se aplica — <motivo>` — inclusive em repositório
de infra, porque o critério é o bloco, não o tipo de repositório —; e o item ⑦ do portão cobra a
declaração, a validação e o archive. Sem `tasks.md` nem fase `apply`: as tarefas ficam no PLAN, numa
lista só. A telemetria do OpenSpec fica **sempre desligada**, em qualquer trabalho: não traz função a
quem usa, faz uma chamada de rede por comando e, na mesma chave, desliga o aviso de versão nova — e o
CLI só deve mudar de versão depois do autoteste. Onde está: `referencia/openspec.md`, o ⑦ do portão e
`scripts/openspec_ambiente.sh`.

## 2026-10-20 — Resumo que deduzia o escopo pelo índice

Uma auditoria do README achou duas regras em contradição. Desde a 3.0.0, o bloco gerenciado do
`AGENTS.md` proíbe deduzir escopo pela tabela de escopos; a `resumo-trabalho`, num pedido de resumo sem
card e sem label ativo, ainda escolhia o escopo do repositório por essa mesma tabela — e escolhia
sozinha quando havia um escopo só. Com as duas carregadas na mesma sessão, o agente teria de escolher a
qual obedecer. → Sem label nem escopo ativo na conversa, a `resumo-trabalho` pergunta o card: pode
listar os slugs do índice como opções, mas não escolhe por eles. Onde está: `resumo-trabalho/SKILL.md`,
aviso da seção "Sintaxe".

## 2026-10-20 — Handoff lido como comando do usuário

O README novo mandava o dev digitar `/sessao handoff` para fechar o planejamento, e o `HELP.md` dava a
mesma leitura. O usuário apontou que o Planejador faz o handoff sozinho quando o plano é aceito — e era
o que a skill pedia: na v2, o `start` com baton 🧠 dizia "detalhar/replanejar/handoff do próximo
bloco", e o incidente de 2026-08-24 foi justamente um Planejador que selou o handoff sozinho, só que
sem aceite. Na 3.0.0 o texto encolheu para "preparar o `handoff`", que não diz quem dispara. → O
`start`, o `handoff`, o protocolo e o `HELP.md` dizem que o Planejador faz o handoff ao fim do
planejamento, sem esperar o comando, com o aceite como trava; o usuário só o digita para ir direto a
ele. Onde está: `subcomandos/start.md`, `subcomandos/handoff.md` e `referencia/protocolo.md`.

## 2026-10-20 — O dev tinha de lembrar o próximo passo

A mesma revisão mostrou quanto do fluxo dependia da memória do dev: o comando e o papel da próxima
sessão, o push, o `update` quando a skill mudava, os comandos de instalação do OpenSpec. E nada
avisava quando uma sessão terminava sem `end`: a seguinte começava por cima de um PLAN com edições não
commitadas e sem a linha da sessão no registro. → Toda sessão termina com os "Próximos passos" (o
comando completo da próxima sessão, o push a aprovar, o merge, o apontamento); o `start` avisa quando a
sessão anterior não fechou e quando o projeto precisa de `update`; e o `init` e o `update` oferecem
rodar a instalação do CLI. Onde está: `referencia/conferencia.md` (Próximos passos),
`subcomandos/start.md` e `subcomandos/init.md`.

## 2026-10-20 — Handoff sem aceite retomado pelo Executor

No primeiro ciclo completo dos testes de comportamento, o Planejador deixou uma decisão em aberto e não
selou o handoff — certo. Mas o baton do working tree já dizia ⚙️ (o handoff grava o baton antes de
mostrar o plano), e o `start` seguinte entrou como Executor. A trava de sessão aberta funcionou; as
saídas oferecidas, não: "seguir com as edições no working tree" (executar por cima) e mostrar o plano
para colher o aceite ali mesmo, numa sessão de Executor e com o modelo barato. → O papel de uma sessão
que acha a anterior aberta sai do baton do último commit, e só há dois caminhos: fechar aquela sessão
no papel dela ou descartar as edições. Handoff sem aceite se fecha como handoff, pelo 🧠 Planejador.
Onde está: `subcomandos/start.md`. O cenário `handoff-sem-aceite` da camada 3 o cobre.

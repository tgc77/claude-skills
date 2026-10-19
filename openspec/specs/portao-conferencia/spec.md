# portao-conferencia Specification

## Purpose
Confere mecanicamente o registro de uma sessão antes do commit, medindo o PLAN e o log de apontamento em
vez de confiar no que o agente declara ter feito.

## Requirements

### Requirement: Linha do baton única
O portão DEVE reprovar quando o PLAN não tem a linha `🎬 Próximo` ou tem mais de uma.

#### Scenario: PLAN sem a linha do baton
- **WHEN** o PLAN não tem nenhuma linha `- **🎬 Próximo:**`
- **THEN** o item ① sai vermelho e o portão sai com exit 1

#### Scenario: Duas linhas do baton
- **WHEN** o PLAN tem duas linhas `- **🎬 Próximo:**`
- **THEN** o item ① sai vermelho

### Requirement: Baton passado, não narrado
No fechamento, o portão DEVE reprovar quando o parágrafo do baton, isto é, a linha e as continuações
indentadas, está igual ao da ref-base da sessão.

#### Scenario: Baton intacto
- **WHEN** a sessão não mudou a linha do baton nem as continuações
- **THEN** o item ② sai vermelho

#### Scenario: Só a continuação mudou
- **WHEN** a sessão mudou apenas uma linha de continuação do baton
- **THEN** o item ② sai verde

### Requirement: Ponto de entrada não concluído
O portão DEVE reprovar quando a tarefa citada no baton está `[x]` e em nenhum lugar aberta; um id que
aparece aberto num bloco e concluído em outro NÃO DEVE reprovar.

#### Scenario: Baton podre
- **WHEN** o baton cita a T1 e a T1 está `[x]`
- **THEN** o item ③ sai vermelho

#### Scenario: Id reusado entre blocos
- **WHEN** o id citado aparece como `[x]` num bloco e como `[ ]` em outro
- **THEN** o item ③ sai amarelo, nunca vermelho

### Requirement: Linha nova no registro de sessões
No fechamento, o portão DEVE reprovar quando o registro de sessões do PLAN não ganhou linha nova.

#### Scenario: Sessão sem registro
- **WHEN** a sessão não acrescentou linha ao registro de sessões
- **THEN** o item ④ sai vermelho

### Requirement: Apontamento de cada sessão
Cada linha nova do registro DEVE ter a sua chave `**Sessão:**` no log de apontamento do escopo:
`<data>#<k>`, em que k é a posição da linha entre as de mesma data, ou o número da sessão no dialeto
legado.

#### Scenario: Segunda sessão do dia sem apontamento
- **WHEN** o log tem a entrada `<hoje>#1` e a sessão acrescentou a 2ª linha de hoje ao registro
- **THEN** o item ⑤ sai vermelho e diz a chave que falta, `<hoje>#2`

#### Scenario: Limite numérico da chave
- **WHEN** a chave exigida é `<data>#1` e o log só tem `<data>#12`
- **THEN** o item ⑤ sai vermelho

### Requirement: Aceite do contrato
Quando a sessão escreve contrato de bloco e passa o baton ao Executor, o portão DEVE exigir uma linha
`**Aceite:** <quem>, <data> (bloco <id>)` acrescentada nesta mesma sessão.

#### Scenario: Contrato sem aceite
- **WHEN** a sessão escreveu tarefas e passou o baton ao ⚙️ sem acrescentar o aceite
- **THEN** o item ⑥ sai vermelho

#### Scenario: Aceite antigo
- **WHEN** o único aceite do PLAN foi commitado antes da sessão
- **THEN** o item ⑥ sai vermelho

#### Scenario: Engrenagem sem o seletor de variação
- **WHEN** o baton diz "⚙ Executor", sem o U+FE0F
- **THEN** o item ⑥ continua exigindo o aceite

### Requirement: PLAN de escopo novo
No fechamento, um PLAN que ainda não está no git DEVE ser conferido contra um arquivo vazio, com aviso
para incluí-lo no commit.

#### Scenario: Escopo nascido na sessão
- **WHEN** o PLAN do escopo ainda não passou por `git add`
- **THEN** o portão avisa que ele está fora do git e confere o arquivo inteiro como mudança da sessão

### Requirement: Modo início
Com `--inicio`, o portão DEVE conferir só a coerência do baton e sair com exit 1 quando ele está podre,
sem avaliar os itens de fechamento.

#### Scenario: Início com baton podre
- **WHEN** o baton manda executar tarefa já concluída
- **THEN** o portão sai com exit 1

#### Scenario: Início com baton saudável
- **WHEN** o baton cita tarefa aberta
- **THEN** o portão sai com exit 0 e não avalia os itens ④, ⑤ e ⑥

### Requirement: Modo estado
Com `--estado`, o portão DEVE imprimir no stdout só um JSON com o estado do escopo (PLAN, branch, bloco
ativo, baton e coerência, tarefas, gates, registro e apontamento) e mandar as linhas de conferência
para o stderr.

#### Scenario: Estado de um escopo saudável
- **WHEN** o baton cita a T1, que está aberta
- **THEN** o JSON traz papel executor, coerência "coerente" e próxima tarefa T1, e o exit é 0

#### Scenario: Estado com baton podre
- **WHEN** o baton cita tarefa concluída
- **THEN** o JSON sai assim mesmo, com coerência "podre", e o exit é 1

### Requirement: Resolução do PLAN
O portão DEVE achar o PLAN do slug pelo índice do `AGENTS.md`, pelo índice legado do `CLAUDE.md`, por
`docs/sessoes/<slug>/PLAN.md` ou pelo `PLAN.md` da raiz, nessa ordem, e sair com exit 2 quando não achar
nenhum.

#### Scenario: Índice legado
- **WHEN** o índice de escopos está no `CLAUDE.md` e aponta para o `PLAN.md` da raiz
- **THEN** o portão confere esse PLAN

#### Scenario: Slug desconhecido
- **WHEN** o slug não resolve para nenhum PLAN
- **THEN** o portão sai com exit 2

### Requirement: Escopo sem o módulo OpenSpec
Em PLAN sem o parâmetro `**OpenSpec**` no cabeçalho, o portão NÃO DEVE emitir o item ⑦ nem reprovar
por ele.

#### Scenario: Escopo anterior à 3.1.0
- **WHEN** o PLAN não tem o parâmetro **OpenSpec**
- **THEN** a saída do portão não tem o item ⑦

### Requirement: Declaração OpenSpec do bloco
Com o módulo, o portão DEVE reprovar o fechamento quando o contrato do bloco ativo não declara a change
nem "não se aplica — <motivo>" e o baton está com o Executor ou o bloco concluiu; com o baton no
Planejador, DEVE só avisar.

#### Scenario: Declaração ainda de modelo, baton no Executor
- **WHEN** a declaração é o texto de modelo do template e o baton está com o ⚙️
- **THEN** o item ⑦ sai vermelho

#### Scenario: Sem declaração, baton no Planejador
- **WHEN** o contrato não tem a declaração e o baton está com o 🧠
- **THEN** o item ⑦ sai amarelo e o portão não reprova por ele

### Requirement: Motivo obrigatório
A declaração "não se aplica" DEVE trazer o motivo; sem ele, ou fora dos dois formatos aceitos, o item ⑦
DEVE sair vermelho.

#### Scenario: Não se aplica sem motivo
- **WHEN** a declaração é só "não se aplica"
- **THEN** o item ⑦ sai vermelho

#### Scenario: Não se aplica com motivo
- **WHEN** a declaração é "não se aplica — bloco só de medição, não muda comportamento"
- **THEN** o item ⑦ sai verde e mostra o motivo

### Requirement: Change declarada válida
A change declarada DEVE existir e passar no `openspec validate --strict`, ignorado só o aviso de
SHALL/MUST; change inexistente, inválida, com `skip_specs` ou com resposta ilegível DEVE reprovar.

#### Scenario: Change inexistente
- **WHEN** o contrato declara uma change que não está em `openspec/changes/` nem no arquivo
- **THEN** o item ⑦ sai vermelho e mostra o comando que a cria

#### Scenario: Change inválida
- **WHEN** o OpenSpec aponta um requisito sem cenário
- **THEN** o item ⑦ sai vermelho e repassa a pendência

#### Scenario: Spec em português
- **WHEN** a única pendência é o aviso de que o requisito não tem SHALL nem MUST
- **THEN** o item ⑦ sai verde

### Requirement: Change arquivada ao concluir o bloco
Com todas as tarefas do bloco ativo concluídas, a change declarada DEVE estar arquivada; se continuar
aberta, o item ⑦ DEVE sair vermelho e mandar arquivá-la.

#### Scenario: Bloco concluído com a change aberta
- **WHEN** todas as tarefas estão `[x]` e a change continua em `openspec/changes/`
- **THEN** o item ⑦ sai vermelho e mostra `openspec archive <id> -y`

#### Scenario: Change arquivada
- **WHEN** a change está em `openspec/changes/archive/<data>-<id>/`
- **THEN** o item ⑦ sai verde

### Requirement: Falha fechada sem o CLI
Sem o CLI do OpenSpec ou sem o node, uma change aberta declarada DEVE reprovar o item ⑦, em vez de
passar sem validação.

#### Scenario: CLI ausente
- **WHEN** o contrato declara uma change aberta e o `openspec` não está instalado
- **THEN** o item ⑦ sai vermelho

### Requirement: Declaração OpenSpec no estado
O `--estado` DEVE trazer o campo `openspec`, com o módulo, a declaração, a change, a situação e o
motivo do bloco ativo.

#### Scenario: Change aberta no estado
- **WHEN** o bloco ativo declara a change `bloqueio-login`, que está aberta
- **THEN** o campo `openspec` traz módulo ligado, declaração "change", a change `bloqueio-login` e a situação "aberta"

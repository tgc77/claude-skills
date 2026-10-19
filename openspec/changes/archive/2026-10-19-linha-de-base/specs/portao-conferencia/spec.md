## Purpose
Confere mecanicamente o registro de uma sessão antes do commit, medindo o PLAN e o log de apontamento em
vez de confiar no que o agente declara ter feito.

## ADDED Requirements

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

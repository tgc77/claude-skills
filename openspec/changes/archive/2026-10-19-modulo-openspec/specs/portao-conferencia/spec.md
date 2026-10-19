## ADDED Requirements

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

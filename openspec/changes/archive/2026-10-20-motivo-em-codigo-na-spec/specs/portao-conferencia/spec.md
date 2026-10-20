## MODIFIED Requirements

### Requirement: Declaração OpenSpec do bloco
Com o módulo, o portão DEVE reprovar o fechamento quando o contrato do bloco ativo não declara a change
nem `não se aplica — <motivo>` e o baton está com o Executor ou o bloco concluiu; com o baton no
Planejador, DEVE só avisar.

#### Scenario: Declaração ainda de modelo, baton no Executor
- **WHEN** a declaração é o texto de modelo do template e o baton está com o ⚙️
- **THEN** o item ⑦ sai vermelho

#### Scenario: Sem declaração, baton no Planejador
- **WHEN** o contrato não tem a declaração e o baton está com o 🧠
- **THEN** o item ⑦ sai amarelo e o portão não reprova por ele

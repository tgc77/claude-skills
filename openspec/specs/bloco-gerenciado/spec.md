# bloco-gerenciado Specification

## Purpose
Mantém o trecho do `AGENTS.md` que a skill controla igual ao template, sem tocar no conteúdo próprio do
projeto.

## Requirements

### Requirement: Verificar o bloco
O `--verificar` DEVE sair com 0 quando o bloco entre os marcadores é igual ao do template e com 1,
mostrando o diff, quando difere.

#### Scenario: Bloco desatualizado
- **WHEN** o bloco do `AGENTS.md` difere do template
- **THEN** o script sai com 1 e mostra o diff

#### Scenario: Bloco em dia
- **WHEN** o `AGENTS.md` foi criado a partir do template
- **THEN** o script sai com 0

### Requirement: Aplicar só no bloco
O `--aplicar` DEVE reescrever só o trecho entre `<!-- sessao:inicio` e `<!-- sessao:fim -->`, mantendo o
resto do arquivo.

#### Scenario: Atualização do bloco
- **WHEN** o bloco está desatualizado e o arquivo tem conteúdo do projeto fora dele
- **THEN** o bloco passa a ser igual ao do template e o conteúdo de fora fica idêntico

### Requirement: Recusa sem marcadores válidos
O script NÃO DEVE escrever nada quando o `AGENTS.md` não tem os marcadores, ou os tem duplicados ou fora
de ordem; nesses casos DEVE sair com 1.

#### Scenario: AGENTS.md de antes do bloco
- **WHEN** o `AGENTS.md` não tem os marcadores
- **THEN** o script sai com 1 e manda migrar com o usuário

#### Scenario: Marcadores duplicados
- **WHEN** o `AGENTS.md` tem dois marcadores de início
- **THEN** o script sai com 1 e não altera o arquivo

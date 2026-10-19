# ambiente-openspec Specification

## Purpose
Confere e prepara o que a máquina e o repositório precisam para o módulo OpenSpec da skill: o CLI, a
telemetria desligada, o schema e a pasta `openspec/`.

## Requirements

### Requirement: Verificar o ambiente
O `--verificar` DEVE sair com 1 e listar cada pendência: CLI ausente ou abaixo da versão mínima, node
ausente, telemetria ligada e schema `sessao` sem o symlink para a skill.

#### Scenario: Máquina sem o schema e com a telemetria ligada
- **WHEN** o symlink do schema não existe e a telemetria está ligada
- **THEN** o script sai com 1 e aponta as duas pendências

#### Scenario: CLI abaixo do mínimo
- **WHEN** o CLI instalado é a versão 1.13.0
- **THEN** o script acusa a versão abaixo do mínimo

### Requirement: Aplicar o ambiente
O `--aplicar` DEVE criar o symlink do schema para a pasta da skill e desligar a telemetria; ele NÃO DEVE
apagar uma cópia do schema que encontre no lugar do symlink.

#### Scenario: Máquina nova
- **WHEN** o `--aplicar` roda sem o symlink e com a telemetria ligada
- **THEN** o symlink aponta para o schema da skill, a telemetria fica desligada e o exit é 0

#### Scenario: Cópia no lugar do symlink
- **WHEN** existe uma cópia do schema onde deveria estar o symlink
- **THEN** o `--verificar` acusa a cópia e o `--aplicar` não a apaga

### Requirement: Preparar o repositório
O `--preparar-repo` DEVE criar `openspec/` com `openspec init --tools none`, quando faltar, e apontar
`schema: sessao` no `config.yaml`, mantendo o resto do arquivo.

#### Scenario: Repositório sem a pasta openspec
- **WHEN** o repositório não tem `openspec/`
- **THEN** a pasta é criada e o `config.yaml` começa com `schema: sessao`

### Requirement: Cópia local do schema
Num repositório com `openspec/`, o `--verificar` DEVE acusar uma cópia do schema em
`openspec/schemas/sessao`, porque ela sobreporia a da skill.

#### Scenario: Projeto com cópia do schema
- **WHEN** o repositório tem `openspec/schemas/sessao`
- **THEN** o `--verificar` sai com 1 e manda apagar a cópia

## Why

O PLAN guarda a execução de um escopo, mas o comportamento que cada bloco entrega não tinha registro
vivo. O módulo liga cada bloco a uma change do OpenSpec, e o portão passa a cobrar essa declaração.
Origem: Fase 2 da reestruturação da skill `sessao` (2026-10-19), que sai na versão 3.1.0.

## What Changes

- Todo escopo novo nasce com o parâmetro **OpenSpec**, e o contrato de cada bloco declara a sua change
  ou "não se aplica — <motivo>".
- O portão ganha o item ⑦ e o campo `openspec` no `--estado`.
- O novo `openspec_ambiente.sh` confere e prepara o CLI, a telemetria, o schema e o repositório.

## Capabilities

### New Capabilities
- `ambiente-openspec`: o que a máquina e o repositório precisam para o módulo funcionar

### Modified Capabilities
- `portao-conferencia`: o item ⑦ e a declaração OpenSpec no `--estado`

## Impact

`conferencia_saida.sh`, `openspec_ambiente.sh`, `openspec-schema/` e `PLAN.template.md`. Os casos 41 a
54 do autoteste são os cenários.

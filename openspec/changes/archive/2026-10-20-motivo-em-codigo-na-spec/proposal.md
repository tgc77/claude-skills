## Why

O requisito "Declaração OpenSpec do bloco" escreve a forma `não se aplica — <motivo>` fora de código, e
na página renderizada o `<motivo>` é lido como tag HTML e some: a regra aparece como "não se aplica — ".
A conferência da documentação (`testes/documentacao.py`, 2026-10-20) acusou. É a mesma correção que a
3.1.1 da `sessao` fez no `SKILL.md`, no `HELP.md` e no `HISTORICO.md`.

## What Changes

- A forma `não se aplica — <motivo>` do requisito passa a aparecer como código. Só a redação muda: o
  comportamento do portão e os cenários do requisito continuam os mesmos.

## Capabilities

### New Capabilities
Nenhuma.

### Modified Capabilities
- `portao-conferencia`: a redação do requisito "Declaração OpenSpec do bloco"

## Impact

Só `openspec/specs/portao-conferencia/spec.md`. Nenhum script, template ou caso do autoteste muda.

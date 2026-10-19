## Why

O comportamento verificável da skill `sessao` (o portão, o lançador e o bloco gerenciado) só estava
descrito nos scripts, nos comentários e nos casos do autoteste. Esta change registra o que a versão
3.0.0 já faz, para que as próximas mudanças entrem como delta. Origem: piloto do módulo OpenSpec da
skill `sessao`, em 2026-10-19.

## What Changes

- Nenhum comportamento muda: as specs descrevem a 3.0.0, com os cenários tirados do autoteste do portão.

## Capabilities

### New Capabilities
- `portao-conferencia`: a conferência mecânica do registro de uma sessão (fechamento, início e estado)
- `lancador-do-portao`: o lançador que cada projeto instala no lugar de uma cópia do portão
- `bloco-gerenciado`: a sincronização do trecho do `AGENTS.md` que a skill controla

## Impact

`sessao/scripts/conferencia_saida.sh`, `conferencia_saida.shim.sh` e `bloco_agents.sh`. Os casos 1 a 40
do `autoteste_portao.sh` são os cenários.

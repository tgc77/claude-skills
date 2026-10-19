# lancador-do-portao Specification

## Purpose
Mantém nos projetos só o endereço do portão, para que toda correção da skill chegue aos escopos já
instalados sem recopiar nada.

## Requirements

### Requirement: Executa o portão da skill instalada
O lançador DEVE executar o portão da primeira skill que achar, nesta ordem: `$SESSAO_SKILL_DIR`, a pasta
de skills do Claude Code, a do Codex e `.agents/skills/sessao` na raiz do repositório.

#### Scenario: Skill apontada por variável
- **WHEN** `SESSAO_SKILL_DIR` aponta para a skill
- **THEN** o lançador roda o portão dela com os mesmos argumentos e devolve o exit do portão

### Requirement: Falha fechada sem a skill
Sem achar a skill, o lançador DEVE sair com exit 2 e dizer onde procurou; ele NÃO DEVE sair com 0.

#### Scenario: Nenhuma skill instalada
- **WHEN** nenhum dos lugares tem a skill
- **THEN** o lançador sai com exit 2 e lista os caminhos procurados

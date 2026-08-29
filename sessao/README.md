# sessao — skill de Controle de Sessões (v2)

Skill que monta e opera o sistema de controle de sessões: **protocolo permanente + índice de escopos
no `AGENTS.md`** + **um `PLAN.md` por escopo** (`docs/sessoes/<escopo>/`) + protocolo
planner/executor + rolling-wave.

**Compatível com Claude Code e Codex**, a partir de uma cópia só:

| Ferramenta | Descoberta | Invocação |
|---|---|---|
| Claude Code | `~/.claude/skills/` (cópia real) | `/sessao init\|start\|handoff\|end\|help` |
| Codex | `~/.codex/skills/` e `~/.agents/skills/` (symlinks) | `$sessao …` ou `@sessao …` |

O projeto instalado ganha `AGENTS.md` (fonte única: protocolo + índice) e um `CLAUDE.md` de uma linha
(`@AGENTS.md`), porque o Claude Code lê `CLAUDE.md` e o Codex lê `AGENTS.md`. ⛔ **Nunca**
`AGENTS.override.md`: no Codex ele substitui o `AGENTS.md` em vez de somar.

Layout da skill: `templates/` (o que é copiado para o projeto) · `scripts/` (portão + autoteste).

**Esta skill é a FONTE CANÔNICA dos templates** (`templates/`). O repositório
`~/workspace/playbook-controle-sessoes/` é apenas um espelho versionável que sincroniza daqui via
`make sync`. Edite os templates aqui, não no clone.

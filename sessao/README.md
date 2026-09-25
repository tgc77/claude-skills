# sessao — skill de Controle de Sessões (v2)

Skill que monta e opera o sistema de controle de sessões: **protocolo permanente + índice de escopos
no `AGENTS.md`** + **um `PLAN.md` por escopo** (`docs/sessoes/<escopo>/`) + protocolo
planner/executor + rolling-wave.

**Compatível com Claude Code e Codex**, a partir de uma cópia só:

| Ferramenta | Descoberta | Invocação |
|---|---|---|
| Claude Code | `~/.claude/skills/` (cópia real) | `/sessao escopos\|init\|start\|handoff\|end\|help` |
| Codex | `~/.codex/skills/` e `.agents/skills/` (symlinks para a cópia real) | `$sessao …` ou `@sessao …` |

O projeto instalado ganha `AGENTS.md` (fonte única: protocolo + índice), um `CLAUDE.md` de uma linha
(`@AGENTS.md`) — porque o Claude Code lê `CLAUDE.md` e o Codex lê `AGENTS.md` — e o lançador
`scripts/conferencia_saida.sh`. ⛔ **Nunca** `AGENTS.override.md`: no Codex ele substitui o
`AGENTS.md` em vez de somar.

Layout da skill: `SKILL.md` (o protocolo, fonte canônica) · `HELP.md` (o que `/sessao help` mostra) ·
`templates/` (o que é copiado para o projeto) · `scripts/` (portão, lançador e autoteste) ·
`agents/openai.yaml` (bloqueia a invocação implícita no Codex — leve-o junto se mover a skill).

**Esta pasta é a fonte canônica** de tudo acima, versionada no repositório `tgc77/claude-skills`. O
antigo espelho `~/workspace/playbook-controle-sessoes/` foi aposentado em 2026-09-24. Visão geral do
repositório, instalação e manutenção: [`../README.md`](../README.md).

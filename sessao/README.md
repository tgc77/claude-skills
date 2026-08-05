# sessao — skill de Controle de Sessões (v2)

Skill do Claude Code que monta e opera o sistema de controle de sessões: **protocolo permanente no
`AGENTS.md`** + **um `PLAN.md` por escopo** (`docs/sessoes/<escopo>/`) + protocolo planner/executor +
rolling-wave. Invoque com `/sessao init|start|handoff|end|help`.

**Esta skill é a FONTE CANÔNICA dos templates** (`templates/`). O repositório
`~/workspace/playbook-controle-sessoes/` é apenas um espelho versionável que sincroniza daqui via
`make sync`. Edite os templates aqui, não no clone.

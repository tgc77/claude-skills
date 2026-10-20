# sessao — skill de Controle de Sessões

Skill que monta e opera o sistema de controle de sessões: **protocolo na skill** + **índice de escopos
e um bloco gerenciado no `AGENTS.md`** + **um `PLAN.md` por escopo** (`docs/sessoes/<slug>/`) +
protocolo planner/executor + rolling-wave.

**Compatível com Claude Code e Codex**, a partir de uma cópia só:

| Ferramenta | Descoberta | Invocação |
|---|---|---|
| Claude Code | `~/.claude/skills/` (cópia real) | `/sessao escopos\|init\|start\|handoff\|end\|update\|help` |
| Codex | `~/.codex/skills/` e `.agents/skills/` (symlinks para a cópia real) | `$sessao …` ou `@sessao …` |

O projeto instalado ganha um `AGENTS.md` (índice de escopos, regras do projeto e o bloco gerenciado),
um `CLAUDE.md` que só importa o `AGENTS.md` — o Claude Code lê `CLAUDE.md` e o Codex lê `AGENTS.md` —
e o lançador `scripts/conferencia_saida.sh`. O protocolo não é copiado para o projeto: cópia congela.
⛔ **Nunca** `AGENTS.override.md`: no Codex ele substitui o `AGENTS.md` em vez de somar.

Layout da skill:

- `SKILL.md` — o roteador: ativação, subcomando → arquivo, regras invioláveis;
- `subcomandos/` — um arquivo por subcomando, lido sob demanda;
- `referencia/` — protocolo, conferência de saída, apontamentos, layout, deploy, openspec;
- `HISTORICO.md` — o porquê de cada regra (não é carregado para operar);
- `VERSION` e `CHANGELOG.md` — a versão atual e o que mudou em cada uma (não são carregados para operar);
- `HELP.md` — o índice que `/sessao help` mostra;
- `templates/` — o que o `init` copia para o projeto;
- `scripts/` — portão, lançador, sincronizador do bloco gerenciado, ambiente do OpenSpec e autoteste;
- `openspec-schema/` — o schema `sessao` do OpenSpec (proposta + specs, sem tarefas), ligado ao
  OpenSpec por symlink;
- `agents/openai.yaml` — bloqueia a invocação implícita no Codex (leve-o junto se mover a skill).

**Esta pasta é a fonte canônica** de tudo acima, versionada no repositório `tgc77/claude-skills`.
Visão geral do repositório, instalação e manutenção: [`../README.md`](../README.md).

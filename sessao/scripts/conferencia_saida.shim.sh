#!/usr/bin/env bash
#
# LANÇADOR do portão de conferência de saída. É ESTE arquivo que o `init` instala em
# `scripts/conferencia_saida.sh` de cada projeto — o portão de verdade mora na skill `sessao`.
#
# POR QUE UM LANÇADOR, E NÃO UMA CÓPIA
# ------------------------------------
# Até 2026-09-07 o `init` copiava o portão inteiro para dentro de cada repo. Consequência: toda
# correção na skill parava na skill. Um escopo instalado em agosto seguia rodando o portão de
# agosto, sem nenhum aviso — e o portão é justamente o mecanismo que existe porque regra
# auto-atestada não segura. Regra escrita na skill, mecanismo velho no projeto: é a mesma classe de
# falha silenciosa que o portão foi criado para pegar.
# Com o lançador, o projeto guarda o ENDEREÇO do portão; a versão é sempre a da skill instalada.
#
# RESOLUÇÃO (primeiro que existir vence)
#   1. $SESSAO_SKILL_DIR                  — override explícito (CI, instalação fora do padrão)
#   2. ${CLAUDE_CONFIG_DIR:-~/.claude}/skills/sessao   — Claude Code
#   3. ${CODEX_HOME:-~/.codex}/skills/sessao           — Codex
#   4. <raiz do repo>/.agents/skills/sessao            — skill vendorizada no próprio projeto
#
# Não achou: sai com 2 (≠ 1, que é REPROVAÇÃO) e diz como resolver. Falha FECHADA de propósito —
# portão que não roda nunca deve parecer portão que passou.
#
set -o pipefail

_raiz_repo=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

_candidatos=(
    "${SESSAO_SKILL_DIR:-}"
    "${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/skills/sessao"
    "${CODEX_HOME:-${HOME}/.codex}/skills/sessao"
    "${_raiz_repo:+${_raiz_repo}/.agents/skills/sessao}"
)

for _base in "${_candidatos[@]}"; do
    [[ -n "${_base}" ]] || continue
    _portao="${_base%/}/scripts/conferencia_saida.sh"
    if [[ -x "${_portao}" ]]; then
        exec "${_portao}" "$@"
    fi
done

{
    echo "🔴 portão NÃO executado — a skill 'sessao' não foi encontrada."
    echo
    echo "   Procurei em:"
    for _base in "${_candidatos[@]}"; do
        [[ -n "${_base}" ]] && echo "     - ${_base%/}/scripts/conferencia_saida.sh"
    done
    echo
    echo "   Instale a skill, ou aponte para ela:"
    echo "     SESSAO_SKILL_DIR=/caminho/para/skills/sessao $0 $*"
    echo
    echo "   ⚠️ Isto NÃO é aprovação. Portão que não roda não substitui portão verde:"
    echo "      a conferência de saída continua pendente e o commit não deve ser feito."
} >&2
exit 2

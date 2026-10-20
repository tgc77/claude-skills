#!/usr/bin/env bash
#
# Os testes do repositório numa chamada só: é o que o CI roda a cada push e o que o
# `versao.sh lancar` roda antes de dar número a uma versão.
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# Até 2026-10-20 os autotestes existiam, mas dependiam de alguém lembrar de rodá-los ("mexeu no
# portão? rode o autoteste"), e nada conferia a documentação nem o comportamento do agente: a 3.1.1
# e a 3.2.0 da `sessao` mudaram só instruções, sem teste nenhum, e dois defeitos de página
# renderizada foram achados a olho. Três camadas:
#   1. scripts       — os autotestes (portão, versao.sh, conferência da documentação) e o verificar
#   2. documentação  — testes/documentacao.py: diagramas, texto que some, links e âncoras, subcomandos
#   3. comportamento — testes/comportamento/rodar.sh: o agente de verdade, em cenários roteirizados
# As camadas 1 e 2 são determinísticas e grátis. A 3 chama o modelo e gasta do plano de quem roda,
# por isso só entra com --comportamento.
#
# USO
#   scripts/testar.sh                      # camadas 1 e 2
#   scripts/testar.sh --comportamento […]  # e a 3; o que vier depois vai para o rodar.sh
#   exit 0 = tudo verde · 1 = algum vermelho · 2 = alguma camada não rodou (nunca é aprovação)
#
set -o pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_DIR
cd "${REPO_DIR}" || exit 2

comportamento=0
if [[ "${1:-}" == "--comportamento" ]]; then
    comportamento=1
    shift
elif [[ $# -gt 0 ]]; then
    echo "uso: $0 [--comportamento [<opções do testes/comportamento/rodar.sh>…]]" >&2
    exit 2
fi

TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "${TMP}"' EXIT

vermelhos=0
nao_rodou=0

# Roda um teste com a saída guardada: verde mostra só o veredito; vermelho mostra a saída inteira.
teste() {
    local nome="$1" inicio="${SECONDS}" codigo
    shift
    "$@" > "${TMP}/saida" 2>&1
    codigo=$?
    if [[ "${codigo}" -eq 0 ]]; then
        printf '  ✅ %s (%ss)\n' "${nome}" "$((SECONDS - inicio))"
        grep '^✅' "${TMP}/saida" | cut -c1-110 | sed 's/^/       /'
        return
    fi
    if [[ "${codigo}" -eq 1 ]]; then
        vermelhos=$((vermelhos + 1))
        printf '  🔴 %s — exit 1 (%ss):\n' "${nome}" "$((SECONDS - inicio))"
    else
        nao_rodou=$((nao_rodou + 1))
        printf '  ⚠️  %s — exit %s, não rodou (%ss):\n' "${nome}" "${codigo}" "$((SECONDS - inicio))"
    fi
    sed 's/^/      /' "${TMP}/saida"
}

printf '\033[1m1. Scripts\033[0m\n'
teste "autoteste do portão"                    sessao/scripts/autoteste_portao.sh
teste "autoteste do versao.sh"                 scripts/autoteste_versao.sh
teste "autoteste da conferência da documentação" testes/autoteste_documentacao.sh
teste "versão × CHANGELOG × tag"               scripts/versao.sh verificar

printf '\n\033[1m2. Documentação\033[0m\n'
teste "conferência da documentação"            testes/documentacao.py

if [[ "${comportamento}" -eq 1 ]]; then
    printf '\n\033[1m3. Comportamento do agente\033[0m\n'
    # Sem guardar a saída: é longa, e quem roda quer ver cada turno andando.
    testes/comportamento/rodar.sh "$@"
    case $? in
        0) ;;
        1) vermelhos=$((vermelhos + 1)) ;;
        *) nao_rodou=$((nao_rodou + 1)) ;;
    esac
fi

echo "------------------------------------------------------------------------"
if [[ "${vermelhos}" -gt 0 ]]; then
    echo "🔴 TESTES REPROVADOS — ${vermelhos} vermelho(s)$([[ ${nao_rodou} -gt 0 ]] && echo ", ${nao_rodou} que não rodou(aram)")."
    exit 1
fi
if [[ "${nao_rodou}" -gt 0 ]]; then
    echo "⚠️  TESTES INCOMPLETOS — ${nao_rodou} teste(s) não rodou(aram); isso não é aprovação."
    exit 2
fi
if [[ "${comportamento}" -eq 1 ]]; then
    echo "✅ TESTES APROVADOS — scripts, documentação e comportamento do agente."
else
    echo "✅ TESTES APROVADOS — scripts e documentação. O comportamento do agente (camada 3) roda com"
    echo "   scripts/testar.sh --comportamento, e gasta do seu plano."
fi

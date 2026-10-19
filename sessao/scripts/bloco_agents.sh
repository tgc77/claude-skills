#!/usr/bin/env bash
#
# Sincroniza o BLOCO GERENCIADO do AGENTS.md de um projeto com o template da skill `sessao`.
# É o que o subcomando `update` roda. Ver subcomandos/update.md.
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# Até 2026-10-19 o `init` copiava o protocolo inteiro (~25 KB) para o AGENTS.md de cada projeto, e
# cada cópia congelava na versão do dia em que foi feita: em outubro, quatro repositórios ainda
# descreviam uma chave de apontamento que o portão já não aceitava, e três não tinham a regra da
# PARADA no meio do bloco. É a mesma classe de falha que o lançador resolveu para o portão
# (2026-09-07). Agora o protocolo mora só na skill, e o AGENTS.md carrega um bloco curto, entre
# marcadores, que este script compara com o template e reescreve — sem tocar no resto do arquivo.
#
# USO
#   bloco_agents.sh --verificar [AGENTS.md]   # 0 = em dia · 1 = desatualizado, ausente ou malformado
#   bloco_agents.sh --aplicar   [AGENTS.md]   # 0 = gravado ou já em dia · 1 = ausente ou malformado
#   (2 = erro de uso, arquivo inexistente ou template sem bloco válido)
#
# Sem marcadores no AGENTS.md, nada é escrito: AGENTS.md com o protocolo copiado (de antes do bloco
# gerenciado) é migrado com o usuário, não por script — ver subcomandos/update.md.
#
set -o pipefail

readonly MARCA_INICIO='<!-- sessao:inicio'
readonly MARCA_FIM='<!-- sessao:fim -->'
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SKILL_DIR
readonly TEMPLATE="${SKILL_DIR}/templates/AGENTS.template.md"

uso() { echo "uso: $0 --verificar|--aplicar [AGENTS.md]" >&2; exit 2; }
[[ $# -ge 1 && $# -le 2 ]] || uso
case "$1" in
    --verificar) readonly MODO="verificar" ;;
    --aplicar)   readonly MODO="aplicar" ;;
    *)           uso ;;
esac
readonly ALVO="${2:-AGENTS.md}"
[[ -f "${ALVO}" ]]     || { echo "🔴 ${ALVO} não existe" >&2; exit 2; }
[[ -f "${TEMPLATE}" ]] || { echo "🔴 template não encontrado: ${TEMPLATE}" >&2; exit 2; }

# Um par de marcadores, na ordem certa, ou nada. Ecoa "ok", "ausente" ou "malformado".
estado_dos_marcadores() {
    local n_ini n_fim l_ini l_fim
    n_ini=$(grep -c -- "^${MARCA_INICIO}" "$1")
    n_fim=$(grep -c -x -F -- "${MARCA_FIM}" "$1")
    if [[ "${n_ini}" -eq 0 && "${n_fim}" -eq 0 ]]; then echo "ausente"; return; fi
    if [[ "${n_ini}" -ne 1 || "${n_fim}" -ne 1 ]]; then echo "malformado"; return; fi
    l_ini=$(grep -n -- "^${MARCA_INICIO}" "$1" | cut -d: -f1)
    l_fim=$(grep -n -x -F -- "${MARCA_FIM}" "$1" | cut -d: -f1)
    if [[ "${l_ini}" -lt "${l_fim}" ]]; then echo "ok"; else echo "malformado"; fi
}

# O bloco inteiro, marcadores incluídos.
extrai_bloco() {
    awk -v ini="${MARCA_INICIO}" -v fim="${MARCA_FIM}" '
        index($0, ini) == 1 { dentro = 1 }
        dentro              { print }
        dentro && $0 == fim { exit }
    ' "$1"
}

if [[ "$(estado_dos_marcadores "${TEMPLATE}")" != "ok" ]]; then
    echo "🔴 o template ${TEMPLATE} não tem um bloco gerenciado válido" >&2
    exit 2
fi
case "$(estado_dos_marcadores "${ALVO}")" in
    ausente)
        echo "🔴 ${ALVO} não tem o bloco gerenciado (${MARCA_INICIO} … ${MARCA_FIM})."
        echo "   É um AGENTS.md de antes do bloco: a migração é feita com o usuário (subcomandos/update.md)."
        exit 1 ;;
    malformado)
        echo "🔴 ${ALVO}: marcadores do bloco gerenciado duplicados ou fora de ordem — corrija à mão."
        exit 1 ;;
esac

bloco_template="$(extrai_bloco "${TEMPLATE}")"
bloco_alvo="$(extrai_bloco "${ALVO}")"
if [[ "${bloco_alvo}" == "${bloco_template}" ]]; then
    echo "✅ bloco gerenciado em dia: ${ALVO}"
    exit 0
fi

if [[ "${MODO}" == "verificar" ]]; then
    echo "🔴 bloco gerenciado DESATUALIZADO em ${ALVO} — diferença para o template da skill:"
    diff -u --label "${ALVO} (atual)" --label "template da skill" \
        <(printf '%s\n' "${bloco_alvo}") <(printf '%s\n' "${bloco_template}")
    exit 1
fi

tmp_bloco="$(mktemp)"
tmp_saida="$(mktemp)"
trap 'rm -f "${tmp_bloco}" "${tmp_saida}"' EXIT
printf '%s\n' "${bloco_template}" > "${tmp_bloco}"
awk -v ini="${MARCA_INICIO}" -v fim="${MARCA_FIM}" -v bloco="${tmp_bloco}" '
    index($0, ini) == 1  { while ((getline linha < bloco) > 0) print linha; pulando = 1; next }
    pulando && $0 == fim { pulando = 0; next }
    pulando              { next }
                         { print }
' "${ALVO}" > "${tmp_saida}"
diff -u --label "${ALVO} (antes)" --label "${ALVO} (depois)" "${ALVO}" "${tmp_saida}"
# `cat >` em vez de `mv`: preserva dono, permissões e hardlinks do arquivo original.
cat "${tmp_saida}" > "${ALVO}"
echo "✅ bloco gerenciado reescrito em ${ALVO} (o resto do arquivo não mudou)"

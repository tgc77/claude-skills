#!/usr/bin/env bash
#
# Confere e prepara o ambiente do módulo OpenSpec da skill `sessao` (ver referencia/openspec.md).
#
# POR QUE ESTE ARQUIVO EXISTE
# ---------------------------
# O módulo depende de três coisas fora do projeto: o CLI `openspec` (com o node), a telemetria dele
# desligada e o schema `sessao`, que mora nesta skill e chega ao OpenSpec por um symlink em
# ~/.local/share/openspec/schemas/. Uma cópia do schema em cada projeto envelheceria como o protocolo
# copiado envelheceu (HISTORICO.md, 2026-10-19); o symlink mantém uma cópia só — a mesma lição do
# lançador do portão. Este script confere as três coisas e conserta as duas que não pedem decisão do
# usuário: o symlink e a telemetria. Instalar o CLI é decisão do usuário; o script só diz como.
#
# USO
#   openspec_ambiente.sh --verificar       # 0 = pronto · 1 = falta algo (listado)
#   openspec_ambiente.sh --aplicar         # cria o symlink do schema, desliga a telemetria, confere
#   openspec_ambiente.sh --preparar-repo   # no repositório atual: `openspec init --tools none`, se
#                                          # faltar openspec/, e `schema: sessao` no config.yaml
#   (2 = erro de uso)
#
set -o pipefail

readonly OPENSPEC_MINIMO="1.14.3"   # a versão contra a qual o portão e o autoteste foram escritos
readonly OPENSPEC_BIN="${SESSAO_OPENSPEC_BIN:-openspec}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly SKILL_DIR
readonly SCHEMA_DA_SKILL="${SKILL_DIR}/openspec-schema"
readonly LINK_DO_SCHEMA="${XDG_DATA_HOME:-${HOME}/.local/share}/openspec/schemas/sessao"

falhas=0
verde()    { printf '✅ %s\n' "$1"; }
amarelo()  { printf '⚠️  %s\n' "$1"; }
vermelho() { printf '🔴 %s\n' "$1"; falhas=$((falhas + 1)); }
os()       { OPENSPEC_TELEMETRY=0 NO_COLOR=1 "${OPENSPEC_BIN}" "$@"; }

uso() { echo "uso: $0 --verificar | --aplicar | --preparar-repo" >&2; exit 2; }
[[ $# -eq 1 ]] || uso

# 0 se $1 >= $2 em SemVer (só X.Y.Z).
versao_ao_menos() {
    local -a a b
    local i
    IFS=. read -r -a a <<< "$1"
    IFS=. read -r -a b <<< "$2"
    for i in 0 1 2; do
        (( 10#${a[i]:-0} > 10#${b[i]:-0} )) && return 0
        (( 10#${a[i]:-0} < 10#${b[i]:-0} )) && return 1
    done
    return 0
}

tem_cli() { command -v "${OPENSPEC_BIN}" >/dev/null 2>&1; }

verificar() {
    local versao alvo telemetria fonte raiz
    if ! tem_cli; then
        vermelho "CLI do OpenSpec ausente. Instalação, com a verificação de assinatura: referencia/openspec.md"
    else
        versao="$(os --version 2>/dev/null | head -1)"
        if [[ "${versao}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && versao_ao_menos "${versao}" "${OPENSPEC_MINIMO}"; then
            verde "CLI do OpenSpec ${versao} (mínimo ${OPENSPEC_MINIMO})"
        else
            vermelho "CLI do OpenSpec '${versao}' abaixo do mínimo ${OPENSPEC_MINIMO} — atualize (referencia/openspec.md)"
        fi
        telemetria="$(os config get telemetry.enabled 2>/dev/null | tail -1)"
        if [[ "${telemetria}" == "false" ]]; then
            verde "telemetria do OpenSpec desligada na configuração global"
        else
            vermelho "telemetria do OpenSpec não está desligada na configuração global — rode --aplicar"
        fi
    fi
    if command -v node >/dev/null 2>&1; then
        verde "node $(node --version) (o portão o usa para ler a validação)"
    else
        vermelho "node ausente — o OpenSpec e o item ⑦ do portão dependem dele"
    fi
    if [[ -L "${LINK_DO_SCHEMA}" ]]; then
        alvo="$(readlink -f "${LINK_DO_SCHEMA}")"
        if [[ "${alvo}" == "${SCHEMA_DA_SKILL}" ]]; then
            verde "schema 'sessao' ligado à skill: ${LINK_DO_SCHEMA} → ${alvo}"
        else
            vermelho "${LINK_DO_SCHEMA} aponta para ${alvo}, não para ${SCHEMA_DA_SKILL}"
        fi
    elif [[ -e "${LINK_DO_SCHEMA}" ]]; then
        vermelho "${LINK_DO_SCHEMA} é uma cópia, não um symlink para a skill — remova-a à mão e rode --aplicar"
    else
        vermelho "schema 'sessao' não instalado no OpenSpec (${LINK_DO_SCHEMA}) — rode --aplicar"
    fi
    # No repositório atual, se ele usa o OpenSpec: o config aponta o schema da skill, e nenhuma cópia
    # local o sobrepõe (o OpenSpec procura primeiro em openspec/schemas/ do projeto).
    raiz="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ -n "${raiz}" && -d "${raiz}/openspec" ]]; then
        if grep -qE '^schema: *sessao *$' "${raiz}/openspec/config.yaml" 2>/dev/null; then
            verde "${raiz}/openspec/config.yaml usa o schema 'sessao'"
        else
            vermelho "${raiz}/openspec/config.yaml não usa o schema 'sessao' — rode --preparar-repo"
        fi
        if [[ -e "${raiz}/openspec/schemas/sessao" ]]; then
            vermelho "${raiz}/openspec/schemas/sessao sobrepõe o schema da skill — apague a cópia local"
        fi
        if tem_cli; then
            fonte="$(cd "${raiz}" && os schemas --json 2>/dev/null | node -e '
                let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
                    try { const x = JSON.parse(s).find(e => e.name === "sessao"); console.log(x ? x.source : ""); }
                    catch (e) { console.log(""); }
                });' 2>/dev/null)"
            if [[ "${fonte}" == "user" ]]; then
                verde "o OpenSpec resolve o schema 'sessao' pelo symlink da skill"
            else
                vermelho "o OpenSpec não resolve o schema 'sessao' pelo symlink da skill (fonte: '${fonte:-nenhuma}')"
            fi
        fi
    fi
    if [[ "${falhas}" -ne 0 ]]; then
        echo "🔴 ambiente do OpenSpec incompleto (${falhas} pendência(s))"
        return 1
    fi
    echo "✅ ambiente do OpenSpec pronto"
}

aplicar() {
    mkdir -p "$(dirname "${LINK_DO_SCHEMA}")"
    if [[ ! -e "${LINK_DO_SCHEMA}" && ! -L "${LINK_DO_SCHEMA}" ]]; then
        ln -s "${SCHEMA_DA_SKILL}" "${LINK_DO_SCHEMA}"
        echo "➕ symlink criado: ${LINK_DO_SCHEMA} → ${SCHEMA_DA_SKILL}"
    fi
    if tem_cli && [[ "$(os config get telemetry.enabled 2>/dev/null | tail -1)" != "false" ]]; then
        os config set telemetry.enabled false >/dev/null && echo "➕ telemetria do OpenSpec desligada"
    fi
    verificar
}

preparar_repo() {
    local raiz
    raiz="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "🔴 fora de um repositório git" >&2; exit 2; }
    cd "${raiz}" || exit 2
    tem_cli || { echo "🔴 CLI do OpenSpec ausente — instale antes (referencia/openspec.md)"; exit 1; }
    if [[ ! -d openspec ]]; then
        os init --tools none --no-animation >/dev/null || { echo "🔴 'openspec init --tools none' falhou"; exit 1; }
        echo "➕ openspec/ criado com 'openspec init --tools none' (sem arquivos de ferramenta)"
    fi
    if grep -qE '^schema:' openspec/config.yaml 2>/dev/null; then
        sed -i -E 's/^schema:.*/schema: sessao/' openspec/config.yaml
    else
        printf 'schema: sessao\n' | cat - openspec/config.yaml 2>/dev/null > openspec/config.yaml.novo
        mv openspec/config.yaml.novo openspec/config.yaml
    fi
    echo "✅ ${raiz}/openspec pronto, com 'schema: sessao' — commite a pasta junto com o escopo"
}

case "$1" in
    --verificar)     verificar ;;
    --aplicar)       aplicar ;;
    --preparar-repo) preparar_repo ;;
    *)               uso ;;
esac

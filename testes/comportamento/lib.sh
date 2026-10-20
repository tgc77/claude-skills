# shellcheck shell=bash
#
# O que os cenários da camada 3 usam: a caixa descartável, o turno do agente e as asserções.
# Carregado pelo rodar.sh, que define FERRAMENTA, MODELO_FORTE, MODELO_BARATO, SKILLS_DIR, SAIDA,
# ARQ_CUSTO e os limites; não roda sozinho.
#
# Cada asserção confere uma coisa que a skill promete, de preferência pelo estado (o --estado do
# portão, os commits, o work-log, o remoto) e só por último pelo texto da resposta, que varia de um
# modelo para outro e de uma rodada para outra.

falhas=0
ok()     { printf '    ✅ %s\n' "$1"; }
nok()    { printf '    🔴 %s\n' "$1"; falhas=$((falhas + 1)); }
mostra() { printf '%s\n' "$1" | sed 's/^/         │ /'; }
passo()  { printf '  \033[1m▸ %s\033[0m\n' "$1"; }

readonly SESSAO_DIR="${SKILLS_DIR}/sessao"
readonly FIXTURES="${SKILLS_DIR}/testes/comportamento/fixtures"
HOJE="$(date +%F)"
ONTEM="$(date -d yesterday +%F)"
readonly HOJE ONTEM
SLUG=calc-subtracao
N_TURNO=0
SESSAO_ID=""
RESPOSTA=""
ACOES=""

# Forma de invocar na ferramenta em uso, e a mesma forma como regex (o "$" do Codex escapado).
if [[ "${FERRAMENTA}" == codex ]]; then CMD='$sessao'; CMD_RE='\$sessao'; else CMD='/sessao'; CMD_RE='/sessao'; fi

# --- Caixa ------------------------------------------------------------------------------------------
# Cada cenário roda numa caixa própria: repo/ (o projeto, com o remoto apontado para remoto.git, que
# flagra push) e worklog/ (o SESSAO_WORKLOG_DIR: o work-log real não é tocado). O repo nasce com a
# calculadora que só soma, na main, já empurrada para o remoto.
nova_caixa() {
    CAIXA="$(mktemp -d "${TMPDIR:-/tmp}/sessao-comportamento.XXXXXX")"
    REPO="${CAIXA}/repo"
    REMOTO="${CAIXA}/remoto.git"
    WORKLOG="${CAIXA}/worklog"
    printf '%s\n' "${CAIXA}" >> "${ARQ_CAIXAS}"
    mkdir -p "${REPO}" "${WORKLOG}" "${CAIXA}/sem-hooks"
    git init -q --bare "${REMOTO}"
    git -C "${REPO}" init -q -b main
    # A configuração global de quem roda não entra: nada de assinatura, hooks ou outro autor.
    git -C "${REPO}" config user.name "Fulano de Teste"
    git -C "${REPO}" config user.email fulano@teste.invalid
    git -C "${REPO}" config commit.gpgsign false
    git -C "${REPO}" config tag.gpgsign false
    git -C "${REPO}" config core.hooksPath "${CAIXA}/sem-hooks"
    git -C "${REPO}" remote add origin "${REMOTO}"
    cp -R "${FIXTURES}/projeto/." "${REPO}/"
    git -C "${REPO}" add -A
    git -C "${REPO}" commit -qm "calculadora: só a soma"
    git -C "${REPO}" push -q origin main 2>/dev/null
}

# O projeto como o `init` e um handoff o deixariam, sem gastar modelo: AGENTS.md com o bloco
# gerenciado do template, CLAUDE.md, lançador do portão, OpenSpec, e o PLAN com o B1 pronto para o
# Executor — aceite e handoff de ontem, com o apontamento daquela sessão no log. Confere o próprio
# fixture antes de entregar: fixture podre não pode virar vermelho da skill.
instalar_escopo_pronto() {
    local plan="docs/sessoes/${SLUG}"
    git -C "${REPO}" checkout -q -b "feat/${SLUG}"
    python3 - "${SESSAO_DIR}/templates/AGENTS.template.md" "${FIXTURES}/AGENTS.md" "${REPO}/AGENTS.md" <<'PY'
import io, re, sys
template, fixture, destino = sys.argv[1:]
bloco = re.search(r'<!-- sessao:inicio.*?<!-- sessao:fim -->', io.open(template, encoding='utf-8').read(), re.S)
assert bloco, 'template sem o bloco gerenciado'
texto = io.open(fixture, encoding='utf-8').read().replace('{{BLOCO_GERENCIADO}}', bloco.group(0))
io.open(destino, 'w', encoding='utf-8').write(texto)
PY
    printf '@AGENTS.md\n' > "${REPO}/CLAUDE.md"
    mkdir -p "${REPO}/scripts" "${REPO}/${plan}"
    cp "${SESSAO_DIR}/scripts/conferencia_saida.shim.sh" "${REPO}/scripts/conferencia_saida.sh"
    chmod +x "${REPO}/scripts/conferencia_saida.sh"
    cp "${SESSAO_DIR}/templates/template-relatorio.md" "${REPO}/docs/sessoes/template-relatorio.md"
    ( cd "${REPO}" && OPENSPEC_TELEMETRY=0 "${SESSAO_DIR}/scripts/openspec_ambiente.sh" --preparar-repo >/dev/null ) \
        || { echo "🔴 fixture: o --preparar-repo do OpenSpec falhou" >&2; exit 2; }
    sed "s/{{ONTEM}}/${ONTEM}/g" "${FIXTURES}/PLAN-executor.md" > "${REPO}/${plan}/PLAN.md"
    cat > "${WORKLOG}/${SLUG}.md" <<MD
# Label: ${SLUG}

---
## [${ONTEM} 17:30] repo

**Relatório-fonte:** — sessão sem relatório. Fonte: §8, §7 e commits.
**Sessão:** ${ONTEM}#1 · B1 (🧠 Planejador)

**O que foi feito:**
- B1 (função \`subtrair\`) detalhado em duas tarefas; critérios medidos: \`calc.subtrair\` ainda não
  existe (\`AttributeError\`) e a suíte roda 1 teste, OK. Aceite do Fulano e baton para o ⚙️ Executor.
MD
    git -C "${REPO}" add -A
    git -C "${REPO}" commit -qm "docs(sessao): escopo ${SLUG} com o B1 pronto para o Executor"
    local j
    j="$(estado)" || { echo "🔴 fixture: o --estado do portão reprovou o PLAN do fixture" >&2; mostra "${j}"; exit 2; }
    jq -e '.baton.papel == "executor" and .baton.coerencia == "coerente"' >/dev/null <<<"${j}" \
        || { echo "🔴 fixture: baton inesperado" >&2; mostra "$(jq -c .baton <<<"${j}")"; exit 2; }
    ( cd "${REPO}" && "${SESSAO_DIR}/scripts/bloco_agents.sh" --verificar AGENTS.md >/dev/null ) \
        || { echo "🔴 fixture: bloco gerenciado do AGENTS.md fora do template" >&2; exit 2; }
}

# --- O que fica de fora da caixa ----------------------------------------------------------------------
# Impressão do que o agente não pode tocar: o repositório das skills e o work-log real.
foto_de_fora() {
    {
        find "${SKILLS_DIR}" \( -path "${SKILLS_DIR}/.git" -o -path "${SKILLS_DIR}/synced" \) -prune \
             -o -type f -printf '%P %s %T@\n'
        find "${HOME}/.claude/work-log" -type f -printf '%P %s %T@\n' 2>/dev/null
    } | sort | sha256sum | cut -c1-16
}

# --- Turno do agente ----------------------------------------------------------------------------------
# turno <rótulo> <forte|barato> <nova|segue> <mensagem>
# Manda uma mensagem do usuário: numa conversa nova ("nova", como uma sessão nova) ou na mesma do turno
# anterior ("segue"). Deixa a última mensagem do agente em RESPOSTA e as chamadas de ferramenta em
# ACOES (uma por linha, em JSON), guarda a conversa em ${SAIDA} e soma o custo em ${ARQ_CUSTO}.
turno() {
    local rotulo="$1" peso="$2" modo="$3" mensagem="$4" modelo base inicio="${SECONDS}" antes codigo
    [[ "${peso}" == forte ]] && modelo="${MODELO_FORTE}" || modelo="${MODELO_BARATO}"
    [[ "${modo}" == nova ]] && SESSAO_ID=""
    if teto_estourado; then
        nok "teto de custo (US\$ ${TETO_USD}) atingido antes do turno ${rotulo}: rodada interrompida"
        exit 2
    fi
    N_TURNO=$((N_TURNO + 1))
    base="${SAIDA}/$(printf '%02d' "${N_TURNO}")-${rotulo}"
    printf '%s\n' "${mensagem}" > "${base}.mensagem.txt"
    antes="$(foto_de_fora)"
    "turno_${FERRAMENTA}" "${modelo}" "${mensagem}" "${base}"
    codigo=$?
    printf '%s\n' "${RESPOSTA}" > "${base}.resposta.md"
    printf '%s\n' "${ACOES}" > "${base}.acoes.jsonl"
    printf '%s\n' "${CUSTO_TURNO:-0}" >> "${ARQ_CUSTO}"
    printf '    \033[2m↳ %s · %s · %s: %ss, %s ações, US$ %s\033[0m\n' "${rotulo}" "${FERRAMENTA}" \
        "${modelo:-padrão}" "$((SECONDS - inicio))" "$(grep -c . <<<"${ACOES}")" "$(awk -v c="${CUSTO_TURNO:-0}" 'BEGIN { printf "%.2f", c }')"
    # Erro do CLI (limite do plano, login, rede) não é comportamento da skill: o cenário não rodou.
    if [[ "${codigo}" -ne 0 || -z "${RESPOSTA}" || "${ERRO_CLI:-0}" -eq 1 ]]; then
        printf '    ⚠️  o %s falhou (exit %s): %s\n' "${FERRAMENTA}" "${codigo}" \
            "$(head -c 300 <<<"${RESPOSTA:-$(tail -3 "${base}.err" 2>/dev/null)}")"
        echo "    ⚠️  cenário interrompido: não rodou (exit 2), não é vermelho da skill"
        exit 2
    fi
    if [[ "$(foto_de_fora)" != "${antes}" ]]; then
        nok "algo mudou fora da caixa durante o turno (repositório das skills ou ~/.claude/work-log)"
        echo "         ⚠️  confira à mão: git -C ${SKILLS_DIR} status · ls -lt ~/.claude/work-log" >&2
        printf 'fora-da-caixa\n' >> "${ARQ_CUSTO}.alarmes"
    fi
}

# Ambiente mínimo do CLI: o do usuário (HOME, PATH, idioma, fuso), sem as variáveis desta sessão,
# com o work-log da caixa.
ambiente() {
    printf '%s\n' "HOME=${HOME}" "PATH=${PATH}" "USER=${USER:-$(id -un)}" "LANG=${LANG:-C.UTF-8}" \
        "TERM=dumb" "SESSAO_WORKLOG_DIR=${WORKLOG}" "OPENSPEC_TELEMETRY=0"
    [[ -n "${TZ:-}" ]] && printf 'TZ=%s\n' "${TZ}"
    [[ -n "${LC_ALL:-}" ]] && printf 'LC_ALL=%s\n' "${LC_ALL}"
    return 0
}

turno_claude() {
    local modelo="$1" mensagem="$2" base="$3" codigo
    local -a args=(-p "${mensagem}" --output-format stream-json --verbose --model "${modelo}"
                   --max-turns "${MAX_PASSOS}" --permission-mode acceptEdits
                   --allowedTools Bash Read Edit Write Glob Grep Skill TodoWrite
                   --disallowedTools AskUserQuestion WebFetch WebSearch Task
                   --add-dir "${WORKLOG}" --max-budget-usd "${TETO_TURNO_USD}")
    [[ -n "${SESSAO_ID}" ]] && args+=(--resume "${SESSAO_ID}")
    local -a amb
    mapfile -t amb < <(ambiente)
    ( cd "${REPO}" && timeout "${TEMPO_TURNO}" env -i "${amb[@]}" "${CLAUDE_BIN}" "${args[@]}" ) \
        > "${base}.jsonl" 2> "${base}.err" < /dev/null
    codigo=$?
    local resultado
    resultado="$(jq -cs '[.[] | select(.type == "result")] | last // {}' "${base}.jsonl" 2>/dev/null)"
    [[ -n "${resultado}" ]] || resultado='{}'
    RESPOSTA="$(jq -r '.result // ""' <<<"${resultado}")"
    SESSAO_ID="$(jq -r '.session_id // ""' <<<"${resultado}")"
    CUSTO_TURNO="$(jq -r '.total_cost_usd // 0' <<<"${resultado}")"
    ERRO_CLI="$(jq -r 'if .is_error == true then 1 else 0 end' <<<"${resultado}")"
    ACOES="$(jq -c 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")
                    | {ferramenta: .name, entrada: .input}' "${base}.jsonl" 2>/dev/null)"
    return "${codigo}"
}

turno_codex() {
    local modelo="$1" mensagem="$2" base="$3" codigo
    # O `exec resume` não aceita -s nem --add-dir: o sandbox vai por -c, igual nos dois.
    local -a args=(--json --skip-git-repo-check -o "${base}.ultima.md" -c 'sandbox_mode="workspace-write"'
                   -c "sandbox_workspace_write.writable_roots=[\"${WORKLOG}\", \"${REMOTO}\"]")
    ERRO_CLI=0
    [[ -n "${modelo}" ]] && args+=(-m "${modelo}")
    local -a amb
    mapfile -t amb < <(ambiente)
    if [[ -n "${SESSAO_ID}" ]]; then
        ( cd "${REPO}" && timeout "${TEMPO_TURNO}" env -i "${amb[@]}" "${CODEX_BIN}" exec resume "${args[@]}" "${SESSAO_ID}" "${mensagem}" ) \
            > "${base}.jsonl" 2> "${base}.err" < /dev/null
    else
        ( cd "${REPO}" && timeout "${TEMPO_TURNO}" env -i "${amb[@]}" "${CODEX_BIN}" exec -C "${REPO}" "${args[@]}" "${mensagem}" ) \
            > "${base}.jsonl" 2> "${base}.err" < /dev/null
    fi
    codigo=$?
    [[ -z "${SESSAO_ID}" ]] && SESSAO_ID="$(jq -r 'select(.type == "thread.started") | .thread_id // empty' "${base}.jsonl" 2>/dev/null | head -1)"
    RESPOSTA="$(cat "${base}.ultima.md" 2>/dev/null)"
    CUSTO_TURNO=0   # o codex exec não informa custo
    ACOES="$(jq -c 'select(.type == "item.completed") | .item | select(.type != "agent_message" and .type != "reasoning")
                    | {ferramenta: .type, entrada: .}' "${base}.jsonl" 2>/dev/null)"
    return "${codigo}"
}

teto_estourado() {
    awk -v teto="${TETO_USD}" '{ s += $1 } END { exit !(s > teto) }' "${ARQ_CUSTO}" 2>/dev/null
}

# --- Marca: o estado antes de um turno, para as asserções de "nada mudou" ---------------------------
marca() {
    MARCA_COMMITS="$(git -C "${REPO}" rev-list --all --count)"
    MARCA_REMOTO="$(refs_do_remoto)"
    MARCA_LOG="$(foto_do_log)"
    MARCA_SESSOES="$(entradas_do_log)"
}
refs_do_remoto() { git -C "${REMOTO}" for-each-ref --format='%(refname) %(objectname)' | sort; }
foto_do_log()    { find "${WORKLOG}" -type f -exec sha256sum {} + 2>/dev/null | sort | sha256sum | cut -c1-16; }
entradas_do_log() {
    if [[ -f "${WORKLOG}/${SLUG}.md" ]]; then grep -c '^\*\*Sessão:\*\*' "${WORKLOG}/${SLUG}.md"; else echo 0; fi
}
estado() { ( cd "${REPO}" && SESSAO_WORKLOG_DIR="${WORKLOG}" scripts/conferencia_saida.sh "${SLUG}" --estado 2>/dev/null ); }

# --- Asserções ----------------------------------------------------------------------------------------
trecho_da_resposta() { mostra "$(printf '%s\n' "${RESPOSTA}" | head -40)"; }

espera_resposta() {        # <regex> <o que promete>
    if grep -qiE -- "$1" <<<"${RESPOSTA}"; then ok "$2"; else nok "$2"; trecho_da_resposta; fi
}
nao_espera_resposta() {    # <regex> <o que promete>
    local achado
    achado="$(grep -iE -- "$1" <<<"${RESPOSTA}" | head -3)"
    if [[ -z "${achado}" ]]; then ok "$2"; else nok "$2"; mostra "${achado}"; fi
}
espera_acao() {            # <regex sobre as chamadas de ferramenta> <o que promete>
    if grep -qiE -- "$1" <<<"${ACOES}"; then ok "$2"; else nok "$2"; mostra "$(cut -c1-160 <<<"${ACOES}" | head -15)"; fi
}
nao_espera_acao() {        # <regex sobre as chamadas de ferramenta> <o que promete>
    local achado
    achado="$(grep -iE -- "$1" <<<"${ACOES}" | cut -c1-200 | head -3)"
    if [[ -z "${achado}" ]]; then ok "$2"; else nok "$2"; mostra "${achado}"; fi
}
espera_estado() {          # <expressão jq que dá true> <o que promete>
    local j
    j="$(estado)"
    if jq -e "$1" >/dev/null 2>&1 <<<"${j}"; then
        ok "$2"
    else
        nok "$2"
        mostra "$(jq -c '{baton: .baton.texto, papel: .baton.papel, coerencia: .baton.coerencia,
                          tarefas: .tarefas_do_bloco_ativo, openspec}' <<<"${j}" 2>/dev/null || head -c 600 <<<"${j}")"
    fi
}
espera_commits_novos() {   # <n> <o que promete>
    local n=$(( $(git -C "${REPO}" rev-list --all --count) - MARCA_COMMITS ))
    if [[ "${n}" -eq "$1" ]]; then ok "$2"; else nok "$2 — ${n} commit(s) novo(s), esperado $1"; mostra "$(git -C "${REPO}" log --all --oneline -5)"; fi
}
espera_log_intocado() {    # <o que promete>
    if [[ "$(foto_do_log)" == "${MARCA_LOG}" ]]; then ok "$1"; else nok "$1"; mostra "$(tail -15 "${WORKLOG}/${SLUG}.md" 2>/dev/null)"; fi
}
espera_uma_entrada_nova_no_log() {   # <o que promete> — e com a chave de hoje
    local n=$(( $(entradas_do_log) - MARCA_SESSOES ))
    local ultima
    ultima="$(grep '^\*\*Sessão:\*\*' "${WORKLOG}/${SLUG}.md" 2>/dev/null | tail -1)"
    if [[ "${n}" -eq 1 && "${ultima}" == "**Sessão:** ${HOJE}#"* ]]; then
        ok "$1 (${ultima#\*\*Sessão:\*\* })"
    else
        nok "$1 — ${n} entrada(s) nova(s); a última: ${ultima:-nenhuma}"
    fi
}
espera_sem_push() {        # <o que promete>
    if [[ "$(refs_do_remoto)" == "${MARCA_REMOTO}" ]]; then ok "$1"; else nok "$1"; mostra "$(refs_do_remoto)"; fi
}
espera_push_da_branch() {  # <branch> <o que promete>
    local local_ remoto
    local_="$(git -C "${REPO}" rev-parse -q --verify "refs/heads/$1")"
    remoto="$(git -C "${REMOTO}" rev-parse -q --verify "refs/heads/$1")"
    if [[ -n "${remoto}" && "${remoto}" == "${local_}" ]]; then ok "$2"; else nok "$2 — remoto: ${remoto:-sem a branch}, local: ${local_:-?}"; fi
}
espera_portao_verde() {    # <ref-base> <o que promete>
    local saida
    saida="$(cd "${REPO}" && SESSAO_WORKLOG_DIR="${WORKLOG}" scripts/conferencia_saida.sh "${SLUG}" "$1" 2>&1)"
    if [[ $? -eq 0 ]]; then ok "$2"; else nok "$2"; mostra "$(grep -E '🔴|⚠️' <<<"${saida}" | head -8)"; fi
}
espera_comando() {         # <o que promete> <comando…> — roda no repo da caixa
    local descricao="$1" saida
    shift
    # Sem bytecode: a asserção não pode deixar arquivo novo no repo que o agente vai commitar.
    saida="$(cd "${REPO}" && PYTHONDONTWRITEBYTECODE=1 "$@" 2>&1)"
    if [[ $? -eq 0 ]]; then ok "${descricao}"; else nok "${descricao}"; mostra "$(tail -6 <<<"${saida}")"; fi
}
nao_espera_comando() {     # <o que promete> <comando…> — o comando tem de falhar
    local descricao="$1"
    shift
    if (cd "${REPO}" && PYTHONDONTWRITEBYTECODE=1 "$@" >/dev/null 2>&1); then nok "${descricao}"; else ok "${descricao}"; fi
}
espera_arquivo() {         # <caminho no repo, aceita glob> <o que promete>
    local -a achados
    mapfile -t achados < <(cd "${REPO}" && compgen -G "$1")
    if [[ ${#achados[@]} -gt 0 ]]; then ok "$2"; else nok "$2 — não há $1"; fi
}
nao_espera_arquivo() {     # <caminho no repo> <o que promete>
    if [[ -e "${REPO}/$1" ]]; then nok "$2 — $1 existe"; else ok "$2"; fi
}
espera_arquivo_contem() {  # <caminho no repo> <regex> <o que promete>
    if grep -qE -- "$2" "${REPO}/$1" 2>/dev/null; then ok "$3"; else nok "$3"; mostra "$(grep -nE 'Aceite|🎬' "${REPO}/$1" 2>/dev/null | head -5)"; fi
}
espera_intocado() {        # <caminho no repo> <o que promete> — igual ao HEAD
    if git -C "${REPO}" diff --quiet HEAD -- "$1" && [[ -z "$(git -C "${REPO}" ls-files -o --exclude-standard -- "$1")" ]]; then
        ok "$2"
    else
        nok "$2"; mostra "$(git -C "${REPO}" status --short -- "$1" | head -8)"
    fi
}

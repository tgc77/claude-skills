# shellcheck shell=bash
DESCRICAO="start com o bloco gerenciado do AGENTS.md desatualizado: avisa e mostra o update, sem parar a sessão"

cenario() {
    nova_caixa
    instalar_escopo_pronto
    # O AGENTS.md de um projeto instalado antes da 3.1.0: sem a regra "identificador sozinho".
    python3 - "${REPO}/AGENTS.md" <<'PY'
import io, re, sys
f = sys.argv[1]
s = io.open(f, encoding='utf-8').read()
s2 = re.sub(r'^- \*\*🗣️ Identificador sozinho.*?(?=^<!-- sessao:fim -->)', '', s, count=1, flags=re.S | re.M)
assert s2 != s, 'a regra não foi achada no bloco'
io.open(f, 'w', encoding='utf-8').write(s2)
PY
    git -C "${REPO}" commit -qam "docs: AGENTS.md de antes da 3.1.0"
    if (cd "${REPO}" && "${SESSAO_DIR}/scripts/bloco_agents.sh" --verificar AGENTS.md >/dev/null); then
        echo "🔴 fixture: o bloco devia estar desatualizado" >&2
        exit 2
    fi
    marca
    turno briefing barato nova "${CMD} start ${SLUG} só carrega o contexto de onde paramos, não execute nada ainda"
    espera_resposta "${CMD_RE} update" "mostra o comando: ${CMD} update"
    espera_resposta 'T1' "o briefing traz o ponto de entrada (T1)"
    espera_intocado calc.py "briefing não executa"
    espera_intocado AGENTS.md "não atualiza o AGENTS.md por conta própria"
    espera_intocado docs "não mexe no PLAN"
    espera_commits_novos 0 "não commita"
}

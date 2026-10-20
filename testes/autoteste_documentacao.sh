#!/usr/bin/env bash
#
# Autoteste da conferência da documentação (`testes/documentacao.py`) — o controle do controle.
#
# Monta um repositório sintético com a mesma forma do real (roteador, HELP, README, subcomandos,
# a "Sintaxe" do resumo-trabalho), planta um defeito por vez e afirma que a conferência o acusa e que
# o que é legítimo continua verde. Não depende do estado da documentação real: um defeito nela
# reprova a conferência, não este teste. Não toca no repositório real (trava de sandbox, como nos
# outros autotestes — ver sessao/HISTORICO.md, 2026-08-28).
#
# USO
#   testes/autoteste_documentacao.sh       # exit 0 = íntegro; exit 1 = regressão
#
set -o pipefail

falhas=0
titulo() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()     { printf '  ✅ %s\n' "$1"; }
nok()    { printf '  🔴 %s\n' "$1"; falhas=$((falhas + 1)); }
mostra() { printf '%s\n' "$1" | sed 's/^/      /'; }

TESTES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TESTES
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "${TMP}"' EXIT

garantir_sandbox() {
    if [[ "${PWD}" != "${TMP}/repo" ]]; then
        echo "🔴 ABORTADO: o autoteste tentou operar fora do sandbox (${PWD})." >&2
        exit 2
    fi
}

# Repo sintético e íntegro. ⚠️ NÃO chamar com $(montar): em subshell o `cd` não persiste.
montar() {
    rm -rf "${TMP}/repo"
    mkdir -p "${TMP}/repo/testes" "${TMP}/repo/sessao/subcomandos" "${TMP}/repo/sessao/templates" \
             "${TMP}/repo/resumo-trabalho"
    cd "${TMP}/repo" || exit 2
    garantir_sandbox
    git init -q
    cp "${TESTES}/documentacao.py" testes/
    cat > README.md <<'MD'
# repo

Veja a [seção acentuada](#seção-com-acento--e-emoji-), a [segunda](#subcomandos-1) e o
[roteador](sessao/SKILL.md#-leitura-sob-demanda).

## Skill `sessao`

### Subcomandos

| Subcomando | O que faz |
|---|---|
| `alfa [<slug>]` | faz alfa |
| `help` | mostra o guia |

```mermaid
flowchart TD
    a["/sessao start #lt;slug#gt;<br/>o agente"] --> b["fim"]
```

### Seção com acento — e emoji 🧭

Texto com <descrição curta>, que aparece na página, e `<slug>` em código.

## Skill `resumo-trabalho`

### Subcomandos

| Comando | Efeito |
|---|---|
| `gerar <card>` | gera |
| `listar` | lista |
MD
    cat > sessao/SKILL.md <<'MD'
# sessao

## 📂 Leitura sob demanda

| Subcomando | O que faz | Leia |
|---|---|---|
| `alfa [<slug>]` | faz alfa | [`subcomandos/alfa.md`](subcomandos/alfa.md) |
| `help` | mostra o guia | [`HELP.md`](HELP.md) |
MD
    cat > sessao/HELP.md <<'MD'
# Help

## Subcomandos

| Comando | O que faz |
|---|---|
| `/sessao alfa [<slug>]` | faz alfa |
| `/sessao help` | este guia |
MD
    printf '# alfa\n\nVolta ao [roteador](../SKILL.md).\n' > sessao/subcomandos/alfa.md
    printf '# Template\n\n**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)\n' > sessao/templates/PLAN.template.md
    cat > resumo-trabalho/SKILL.md <<'MD'
# resumo

## Sintaxe (args)

| Comando | Efeito |
|---|---|
| `gerar <card>` | gera |
| `listar` | lista |
MD
}

conf() { python3 testes/documentacao.py "$@" 2>&1; }

titulo "1. Repositório íntegro ⇒ exit 0 (âncora acentuada, com emoji e duplicada; template com placeholder)"
montar
saida="$(conf --sem-render)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && grep -q 'DOCUMENTAÇÃO ÍNTEGRA' <<<"${saida}" \
    && ok "exit 0" || { nok "exit ${codigo} no repo íntegro"; mostra "${saida}"; }

titulo "2. Diagrama com &lt;slug&gt; no rótulo ⇒ exit 1 (é o '/.md' do VS Code, 2026-10-20)"
montar
sed -i 's/#lt;slug#gt;/\&lt;slug\&gt;/' README.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'README.md:.*entidade HTML' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou a entidade" || { nok "deixou passar &lt; no rótulo"; mostra "${saida}"; }
montar
sed -i 's/#lt;slug#gt;/<slug>/' README.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'README.md:.*<slug> num rótulo' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou a tag crua no rótulo" || { nok "deixou passar <slug> no rótulo"; mostra "${saida}"; }

titulo "3. Placeholder fora de código ⇒ exit 1, com arquivo e linha (é o <motivo> da 3.1.1)"
montar
printf '\nA forma é não se aplica — <motivo>.\n' >> sessao/subcomandos/alfa.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'sessao/subcomandos/alfa.md:5: <motivo>' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou com arquivo:linha" || { nok "deixou passar <motivo> na prosa"; mostra "${saida}"; }
montar
cat >> sessao/subcomandos/alfa.md <<'MD'

A forma é `não se aplica — <motivo>`, e o code span pode quebrar a linha: `não se aplica —
<motivo>`. Escapado também aparece: \<motivo>. <!-- comentário com <motivo> -->

```text
- **OpenSpec:** não se aplica — <motivo>
```
MD
mkdir -p openspec/changes/archive/2026-01-01-x testes/fixtures
printf 'História: não se aplica — <motivo>\n' > openspec/changes/archive/2026-01-01-x/proposal.md
printf 'Fixture: <slug> e o [índice](../../../AGENTS.md), que só existe no destino.\n' > testes/fixtures/PLAN.md
saida="$(conf --sem-render)"; codigo=$?
[[ "${codigo}" -eq 0 ]] \
    && ok "código, code span quebrado, escape, comentário, cerca, change arquivada e fixture ficam verdes" \
    || { nok "falso positivo"; mostra "${saida}"; }

titulo "4. Link para arquivo que não existe e âncora que não existe ⇒ exit 1"
montar
printf '\nVeja o [guia](../GUIA.md).\n' >> sessao/subcomandos/alfa.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'alfa.md:.*\.\./GUIA.md, que não existe' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou o arquivo" || { nok "deixou passar link quebrado"; mostra "${saida}"; }
montar
printf '\nVeja a [seção](../SKILL.md#nao-existe).\n' >> sessao/subcomandos/alfa.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'âncora #nao-existe não existe em sessao/SKILL.md' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou a âncora" || { nok "deixou passar âncora quebrada"; mostra "${saida}"; }

titulo "5. Subcomando fora do roteador e tabela que diverge ⇒ exit 1"
montar
printf '# beta\n' > sessao/subcomandos/beta.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'subcomandos/\*.md diverge do roteador: sobra beta' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "arquivo sem linha no roteador" || { nok "deixou passar subcomando órfão"; mostra "${saida}"; }
montar
sed -i '/`\/sessao alfa/d' sessao/HELP.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'sessao/HELP.md diverge do roteador: falta alfa' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "HELP sem um subcomando" || { nok "deixou passar o HELP incompleto"; mostra "${saida}"; }
montar
sed -i 's/`subcomandos\/alfa.md`](subcomandos\/alfa.md)/`HELP.md`](HELP.md)/' sessao/SKILL.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'manda o `alfa` ler' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "roteador apontando o arquivo errado" || { nok "deixou passar o roteador errado"; mostra "${saida}"; }
montar
sed -i '/^| `listar` | lista |$/d' README.md
saida="$(conf --sem-render)"; codigo=$?
grep -q 'resumo-trabalho no README' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "README do resumo-trabalho diverge da Sintaxe" || { nok "deixou passar a divergência"; mostra "${saida}"; }

titulo "6. Sem o mermaid-cli ⇒ exit 2 (não rodou não é aprovação); uso inválido ⇒ exit 2"
montar
saida="$(MMDC=/nao/existe/mmdc conf)"; codigo=$?
[[ "${codigo}" -eq 2 ]] && grep -q 'NÃO RODOU' <<<"${saida}" \
    && ok "exit 2 sem o mermaid-cli" || { nok "exit ${codigo} sem o mermaid-cli"; mostra "${saida}"; }
conf --nada >/dev/null; [[ $? -eq 2 ]] && ok "opção inválida" || nok "aceitou opção inválida"

titulo "7. Diagrama com sintaxe inválida ⇒ exit 1 no render (precisa do mermaid-cli)"
montar
if [[ -n "${MMDC:-}" ]] || command -v mmdc >/dev/null || command -v npx >/dev/null; then
    sed -i 's/--> b\["fim"\]/--> b["fim"/' README.md
    saida="$(conf)"; codigo=$?
    grep -q 'README.md:.*não renderiza' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
        && ok "acusou o diagrama quebrado" || { nok "diagrama quebrado passou"; mostra "${saida}"; }
else
    nok "sem mmdc nem npx: o caso do render não rodou"
fi

echo
if [[ "${falhas}" -ne 0 ]]; then
    echo "🔴 AUTOTESTE REPROVADO — ${falhas} verificação(ões) falharam."
    exit 1
fi
echo "✅ AUTOTESTE APROVADO — 7 casos. Cobre: o repo íntegro (âncora acentuada, com emoji e"
echo "   duplicada; placeholder de template); entidade e tag crua num rótulo Mermaid; placeholder na"
echo "   prosa e o que não é defeito (código, code span quebrado, escape, comentário, cerca, change"
echo "   arquivada, fixture); link e âncora quebrados; subcomando órfão, HELP incompleto, roteador errado e a"
echo "   tabela do resumo-trabalho; o mermaid-cli ausente e o uso inválido; e o render que falha."

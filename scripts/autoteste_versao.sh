#!/usr/bin/env bash
#
# Autoteste do `versao.sh` — confere que o verificador acusa o que deve e que o `lancar` move o
# CHANGELOG do jeito certo. Monta um repositório descartável com uma skill de mentira; não toca no
# repositório real (trava de sandbox, como no autoteste do portão — ver sessao/HISTORICO.md,
# 2026-08-28).
#
# USO
#   scripts/autoteste_versao.sh            # exit 0 = íntegro; exit 1 = regressão
#
set -o pipefail

falhas=0
titulo() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()     { printf '  ✅ %s\n' "$1"; }
nok()    { printf '  🔴 %s\n' "$1"; falhas=$((falhas + 1)); }
mostra() { printf '%s\n' "$1" | sed 's/^/      /'; }

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "${TMP}"' EXIT
HOJE="$(date +%F)"
readonly HOJE
readonly CL=alfa/CHANGELOG.md

garantir_sandbox() {
    if [[ "${PWD}" != "${TMP}/repo" ]]; then
        echo "🔴 ABORTADO: o autoteste tentou operar git fora do sandbox (${PWD})." >&2
        exit 2
    fi
}

# Repo com a skill `alfa` lançada em 1.0.0 (tag alfa-v1.0.0) e uma pasta `fantasma/` com SKILL.md
# fora do git — o papel do cache synced/ no repositório real. Os testes que o `lancar` roda são
# dublês: TESTAR_SAIDA e SELO_SAIDA dizem o que eles respondem (0 por padrão).
# ⚠️ NÃO chamar com $(montar): em subshell o `cd` não persiste.
montar() {
    rm -rf "${TMP}/repo"
    mkdir -p "${TMP}/repo/scripts" "${TMP}/repo/alfa" "${TMP}/repo/fantasma"
    cd "${TMP}/repo" || exit 2
    git init -q
    git config user.email autoteste@local
    git config user.name autoteste
    cp "${SCRIPTS}/versao.sh" scripts/
    mkdir -p testes/comportamento
    printf '#!/usr/bin/env bash\necho "✅ TESTES APROVADOS (dublê)"; exit "${TESTAR_SAIDA:-0}"\n' > scripts/testar.sh
    printf '#!/usr/bin/env bash\necho "selo (dublê): $*"; exit "${SELO_SAIDA:-0}"\n' > testes/comportamento/rodar.sh
    chmod +x scripts/testar.sh testes/comportamento/rodar.sh
    printf -- '---\nname: alfa\n---\n# alfa\n' > alfa/SKILL.md
    printf -- '---\nname: fantasma\n---\n' > fantasma/SKILL.md
    printf '1.0.0\n' > alfa/VERSION
    cat > "${CL}" <<'MD'
# Changelog — skill `alfa`

## [Não lançado]

## [1.0.0] - 2026-01-01

### Adicionado
- primeira versão.

[Não lançado]: https://exemplo.invalid/r/compare/alfa-v1.0.0...HEAD
[1.0.0]: https://exemplo.invalid/r/releases/tag/alfa-v1.0.0
MD
    garantir_sandbox
    git add scripts testes alfa
    git commit -qm base
    git tag -a alfa-v1.0.0 -m "alfa 1.0.0"
}

v() { ./scripts/versao.sh "$@" 2>&1; }

# Põe uma entrada na seção "Não lançado".
entrada() { sed -i "s/^## \[Não lançado\]$/## [Não lançado]\n\n### Corrigido\n- $1/" "${CL}"; }

titulo "1. Versão, CHANGELOG e tag coerentes ⇒ exit 0; pasta com SKILL.md fora do git é ignorada"
montar
saida="$(v verificar)"; codigo=$?
grep -q '✅ alfa 1.0.0' <<<"${saida}" && ok "alfa verde" || { nok "alfa não ficou verde"; mostra "${saida}"; }
grep -q 'fantasma' <<<"${saida}" && nok "olhou a pasta fora do git" || ok "fantasma/ ignorada"
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo}"; mostra "${saida}"; }

titulo "2. Skill mudou depois da tag sem entrada no CHANGELOG ⇒ exit 1, com a lista do que mudou"
montar
printf 'regra nova\n' >> alfa/SKILL.md
saida="$(v verificar)"; codigo=$?
grep -q 'mudou desde alfa-v1.0.0' <<<"${saida}" && ok "acusou a mudança sem registro" || { nok "deixou passar mudança sem CHANGELOG"; mostra "${saida}"; }
grep -q 'alfa/SKILL.md' <<<"${saida}" && ok "listou o arquivo" || nok "não disse o que mudou"
[[ "${codigo}" -eq 1 ]] && ok "exit 1" || nok "exit ${codigo}"
git checkout -q -- alfa/SKILL.md
printf 'novo\n' > alfa/novo.md
saida="$(v verificar)"; codigo=$?
grep -q 'alfa/novo.md' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "arquivo novo, ainda fora do git, também conta" || { nok "arquivo novo passou batido"; mostra "${saida}"; }

titulo "3. A mesma mudança com entrada em 'Não lançado' ⇒ exit 0"
montar
printf 'regra nova\n' >> alfa/SKILL.md
entrada "regra nova no SKILL.md"
saida="$(v verificar)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo}"; mostra "${saida}"; }

titulo "4. VERSION diverge do CHANGELOG ⇒ exit 1"
montar
printf '1.0.1\n' > alfa/VERSION
saida="$(v verificar)"; codigo=$?
grep -q 'VERSION diz 1.0.1' <<<"${saida}" && ok "acusou a divergência" || { nok "não acusou VERSION ≠ CHANGELOG"; mostra "${saida}"; }
[[ "${codigo}" -eq 1 ]] && ok "exit 1" || nok "exit ${codigo}"

titulo "5. lancar minor: título novo sobre as entradas, links e VERSION; sem tag, verificar reprova"
montar
printf 'regra nova\n' >> alfa/SKILL.md
entrada "regra nova no SKILL.md"
saida="$(v lancar alfa minor)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "exit 0" || { nok "exit ${codigo}"; mostra "${saida}"; }
[[ "$(cat alfa/VERSION)" == "1.1.0" ]] && ok "VERSION = 1.1.0" || nok "VERSION = $(cat alfa/VERSION)"
python3 -I - "${CL}" "${HOJE}" <<'PY' && ok "título [1.1.0] logo abaixo de 'Não lançado', com a entrada embaixo dele" || nok "CHANGELOG mal movido"
import io, sys
linhas = io.open(sys.argv[1], encoding="utf-8").read().splitlines()
i = linhas.index("## [Não lançado]")
assert linhas[i + 1] == "" and linhas[i + 2] == f"## [1.1.0] - {sys.argv[2]}", linhas[i:i + 3]
j = linhas.index("## [1.0.0] - 2026-01-01")
assert "- regra nova no SKILL.md" in linhas[i + 2:j]
PY
grep -q -x -F '[Não lançado]: https://exemplo.invalid/r/compare/alfa-v1.1.0...HEAD' "${CL}" \
    && ok "link 'Não lançado' compara a partir da 1.1.0" || nok "link 'Não lançado' não atualizado"
grep -q -x -F '[1.1.0]: https://exemplo.invalid/r/compare/alfa-v1.0.0...alfa-v1.1.0' "${CL}" \
    && ok "link [1.1.0] compara 1.0.0…1.1.0" || nok "link [1.1.0] ausente ou errado"
grep -q 'git tag -a alfa-v1.1.0' <<<"${saida}" && ok "imprimiu o comando da tag" || nok "não disse como criar a tag"
git tag -l | grep -q 'alfa-v1.1.0' && nok "criou tag sozinho — tag é com validação" || ok "não criou tag"
[[ "$(git log --oneline | wc -l)" -eq 1 ]] && ok "não commitou" || nok "commitou sozinho — commit é com validação"
saida="$(v verificar)"; codigo=$?
grep -q 'não tem tag (alfa-v1.1.0)' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "verificar acusa a versão sem tag" || { nok "versão sem tag passou"; mostra "${saida}"; }
garantir_sandbox
git add -A alfa && git commit -qm "release: alfa 1.1.0" && git tag -a alfa-v1.1.0 -m "alfa 1.1.0"
saida="$(v verificar)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "com commit e tag, verificar exit 0" || { nok "exit ${codigo} depois de commit e tag"; mostra "${saida}"; }

titulo "6. lancar sem nada em 'Não lançado' ⇒ exit 1 e nada muda"
montar
saida="$(v lancar alfa patch)"; codigo=$?
grep -q 'nada a lançar' <<<"${saida}" && ok "recusou" || { nok "lançou versão vazia"; mostra "${saida}"; }
[[ "${codigo}" -eq 1 ]] && ok "exit 1" || nok "exit ${codigo}"
git diff --quiet && ok "nenhum arquivo mudou" || nok "mexeu em arquivo ao recusar"

titulo "7. patch e major sobem o número certo"
montar
entrada "conserto"
v lancar alfa patch >/dev/null
[[ "$(cat alfa/VERSION)" == "1.0.1" ]] && ok "patch: 1.0.0 → 1.0.1" || nok "patch deu $(cat alfa/VERSION)"
montar
entrada "quebra contrato"
v lancar alfa major >/dev/null
[[ "$(cat alfa/VERSION)" == "2.0.0" ]] && ok "major: 1.0.0 → 2.0.0" || nok "major deu $(cat alfa/VERSION)"

titulo "8. Versões fora de ordem e título fora do formato ⇒ exit 1"
montar
sed -i 's/^## \[1.0.0\] - 2026-01-01$/## [0.9.0] - 2025-12-01\n\n## [1.0.0] - 2026-01-01/' "${CL}"
printf '[0.9.0]: https://exemplo.invalid/r/x\n' >> "${CL}"
saida="$(v verificar)"; codigo=$?
grep -q 'fora de ordem' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou 0.9.0 acima de 1.0.0" || { nok "ordem errada passou"; mostra "${saida}"; }
montar
sed -i 's/^## \[1.0.0\] - 2026-01-01$/## [1.0.0] 2026-01-01/' "${CL}"
saida="$(v verificar)"; codigo=$?
grep -q 'fora do formato' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "acusou o título sem ' - '" || { nok "título malformado passou"; mostra "${saida}"; }

titulo "9. Uso inválido ⇒ exit 2"
montar
v lancar alfa enorme >/dev/null; [[ $? -eq 2 ]] && ok "nível inválido" || nok "aceitou nível 'enorme'"
v verificar naoexiste >/dev/null; [[ $? -eq 2 ]] && ok "skill inexistente" || nok "aceitou skill inexistente"
v lancar fantasma minor >/dev/null; [[ $? -eq 2 ]] && ok "pasta fora do git não é skill" || nok "lançou a pasta fora do git"

titulo "10. lancar com os testes vermelhos ou incompletos ⇒ exit 1 e nada muda"
montar
entrada "conserto"
antes="$(cat "${CL}")"
saida="$(TESTAR_SAIDA=1 v lancar alfa patch)"; codigo=$?
grep -q 'estão vermelhos' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "recusou com teste vermelho" || { nok "lançou com teste vermelho"; mostra "${saida}"; }
[[ "$(cat alfa/VERSION)" == "1.0.0" && "$(cat "${CL}")" == "${antes}" ]] \
    && ok "VERSION e CHANGELOG intocados" || nok "mexeu no VERSION ou no CHANGELOG ao recusar"
saida="$(TESTAR_SAIDA=2 v lancar alfa patch)"; codigo=$?
grep -q 'não rodaram por inteiro' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "teste que não rodou também não lança" || { nok "lançou com teste incompleto"; mostra "${saida}"; }

titulo "11. lancar sem a rodada verde da camada 3 ⇒ exit 1; sem os scripts de teste ⇒ exit 2"
montar
entrada "regra nova"
saida="$(SELO_SAIDA=1 v lancar alfa minor)"; codigo=$?
grep -q 'selo (dublê): --conferir-selo alfa alfa-v1.0.0' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "perguntou o selo da alfa desde alfa-v1.0.0 e recusou" || { nok "lançou sem o selo"; mostra "${saida}"; }
[[ "$(cat alfa/VERSION)" == "1.0.0" ]] && ok "VERSION intocado" || nok "VERSION mudou ao recusar"
garantir_sandbox
rm scripts/testar.sh
v lancar alfa minor >/dev/null; [[ $? -eq 2 ]] && ok "sem scripts/testar.sh, falha fechado" || nok "lançou sem os testes"

titulo "12. O selo de verdade: instrução mudada exige rodada verde do conteúdo atual"
montar
garantir_sandbox
cp "${SCRIPTS}/../testes/comportamento/rodar.sh" testes/comportamento/rodar.sh
git add testes && git commit -qm "camada 3 de verdade"
s() { ./testes/comportamento/rodar.sh "$@" 2>&1; }
printf 'nota\n' >> alfa/HISTORICO.md
saida="$(s --conferir-selo alfa alfa-v1.0.0)"; codigo=$?
grep -q 'a camada 3 não é exigida' <<<"${saida}" && [[ "${codigo}" -eq 0 ]] \
    && ok "só o HISTORICO mudou: não exige" || { nok "exigiu a camada 3 sem instrução mudada"; mostra "${saida}"; }
printf 'regra nova\n' >> alfa/SKILL.md
saida="$(s --conferir-selo alfa alfa-v1.0.0)"; codigo=$?
grep -q 'alfa/SKILL.md' <<<"${saida}" && [[ "${codigo}" -eq 1 ]] \
    && ok "SKILL.md mudou e não há selo: exige, listando o arquivo" || { nok "deixou passar sem selo"; mostra "${saida}"; }
mkdir -p "$(dirname "$(git rev-parse --git-path sessao-testes/comportamento.selo)")"
printf 'conteudo=%s\nrodada=teste\n' "$(s --selo)" > "$(git rev-parse --git-path sessao-testes/comportamento.selo)"
saida="$(s --conferir-selo alfa alfa-v1.0.0)"; codigo=$?
[[ "${codigo}" -eq 0 ]] && ok "com o selo do conteúdo atual, aceita" || { nok "recusou o selo certo"; mostra "${saida}"; }
printf 'outra regra\n' >> alfa/SKILL.md
saida="$(s --conferir-selo alfa alfa-v1.0.0)"; codigo=$?
[[ "${codigo}" -eq 1 ]] && ok "o conteúdo mudou depois da rodada: o selo não vale mais" || { nok "aceitou selo velho"; mostra "${saida}"; }
git status --porcelain | grep -q selo \
    && nok "o selo apareceu no working tree" || ok "o selo fica dentro do .git, fora do commit"

echo
if [[ "${falhas}" -ne 0 ]]; then
    echo "🔴 AUTOTESTE REPROVADO — ${falhas} verificação(ões) falharam."
    exit 1
fi
echo "✅ AUTOTESTE APROVADO — 12 casos. Cobre: estado coerente e pasta fora do git ignorada; mudança"
echo "   sem CHANGELOG (arquivo alterado e arquivo novo); entrada em 'Não lançado'; VERSION ≠"
echo "   CHANGELOG; o lancar (título, links, VERSION, sem commit nem tag sozinho) e a versão sem tag;"
echo "   nada a lançar; patch e major; ordem e formato dos títulos; uso inválido; o lancar recusando"
echo "   teste vermelho, incompleto, sem selo ou sem os scripts; e o selo da camada 3 de verdade."

# CLAUDE.md — <NOME_DO_PROJETO>

> **Leia [`AGENTS.md`](AGENTS.md) antes de agir.** É o protocolo permanente do repositório: papéis
> 🧠 Planejador / ⚙️ Executor, ritual de fim de turno, convenções de commit e guardrails permanentes.
> Este `CLAUDE.md` é o índice — não duplique conteúdo aqui.

## 🎯 Escopos de trabalho (um escopo = uma pasta)

Cada frente de trabalho tem seu próprio `PLAN.md` (fonte única de verdade daquele escopo) e seus
relatórios, em `docs/sessoes/<escopo>/`. **Leia o PLAN do escopo da sessão — só dele.** Se mais de um
estiver ativo e a intenção não estiver clara, pergunte a <SEU_NOME> qual é.

| Escopo                | Estado   | PLAN                                                    |
|-----------------------|----------|---------------------------------------------------------|
| <título do escopo>    | 🟡 Ativo | [`docs/sessoes/<slug>/PLAN.md`](docs/sessoes/<slug>/PLAN.md) |

**Trocar de escopo:** o escopo é **argumento**, não estado — `/sessao start <slug> [nota]`,
`/sessao end <slug>`. Omitindo o slug, vale: único 🟡 ativo → branch atual casando com a "Branch de
trabalho" do PLAN → pergunta. `/sessao escopos` lista todos com estado, branch e baton, sem alterar
nada. **Um escopo por vez em cada working tree** (paralelo de verdade só com `git worktree`).

**Escopo novo:** `/sessao init` cria só `docs/sessoes/<novo-slug>/PLAN.md` e acrescenta uma linha nesta
tabela. `AGENTS.md` e [`docs/sessoes/template-relatorio.md`](docs/sessoes/template-relatorio.md) são
reusados, nunca copiados. Escopo terminado vira 🟢 Concluído aqui — a pasta permanece como histórico.

**Legenda:** 🟡 Ativo · 🟢 Concluído · 🔴 Bloqueado/pausado.

> ⚠️ `docs/sessoes/**` e este índice são **documentação, não código da feature**: mantenha-os na branch
> base e mergeie cedo. O PLAN é versionado — em branch errada, a sessão lê estado errado.

## 📚 Referência técnica

- <[`README.md`](README.md) — o que o projeto faz>.
- <outros documentos de arquitetura/deploy que o agente deve conhecer>.

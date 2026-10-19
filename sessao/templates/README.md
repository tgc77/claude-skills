# templates/ — o que o `init` copia para um projeto

| Arquivo | Vai para | Observação |
|---|---|---|
| `AGENTS.template.md` | `AGENTS.md` (1ª instalação) | Índice de escopos, regras do projeto e o **bloco gerenciado** (entre `<!-- sessao:inicio` e `<!-- sessao:fim -->`), que o `/sessao update` mantém igual a este template. Nada de protocolo além do bloco: ele mora na skill. |
| `CLAUDE.template.md` | `CLAUDE.md` (1ª instalação) | Só o import `@AGENTS.md`: o Claude Code lê `CLAUDE.md`, o Codex lê `AGENTS.md`. |
| `PLAN.template.md` | `docs/sessoes/<slug>/PLAN.md` (todo escopo novo) | Fonte única de verdade do escopo. O portão e o autoteste dependem do formato dele. Nasce com o parâmetro **OpenSpec**, que liga o item ⑦. |
| `template-relatorio.md` | `docs/sessoes/template-relatorio.md` (1ª instalação) | Gabarito de relatório de bloco, compartilhado por todos os escopos. |

O lançador do portão não está aqui: o `init` copia `../scripts/conferencia_saida.shim.sh` para
`scripts/conferencia_saida.sh` do projeto. A pasta `openspec/` também não: o `init` a cria com
`../scripts/openspec_ambiente.sh --preparar-repo` (`openspec init --tools none` + `schema: sessao`).

⚠️ **Mexeu no `PLAN.template.md` ou no bloco gerenciado do `AGENTS.template.md`? Rode
`../scripts/autoteste_portao.sh`.** O portão lê o PLAN pelo formato dele, e os dois já se
desentenderam uma vez sem nenhum aviso (ver `../HISTORICO.md`, 2026-08-24). Depois de mudar o bloco
gerenciado, rode `/sessao update` em cada projeto.

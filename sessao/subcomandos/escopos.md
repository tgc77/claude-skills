# `escopos [<slug>]` — listar os escopos do repo e onde cada um parou

Responde "quais escopos existem aqui?" e "onde eu estava?". **Não altera nada e não assume escopo** —
listar não é `start`.

1. Leia a tabela **🎯 Escopos de trabalho** do `AGENTS.md` (em projeto legado, do `CLAUDE.md`).
2. Para cada slug, rode `scripts/conferencia_saida.sh <slug> --estado` e use o JSON que ele imprime.
   Não leia o PLAN inteiro nem relatórios. (Repo sem o lançador: leia só o cabeçalho de parâmetros e o
   "🔎 Agora" de cada PLAN, e recomende o `update`.)
3. Apresente nesta ordem de colunas — o slug primeiro, porque é o que se digita:

   | Slug | Escopo | Estado | Branch | Bloco ativo | 🎬 Próximo | Última atualização |
   |---|---|---|---|---|---|---|
   | `<slug>` | <descrição curta> | 🟡/🟢/🔴 | `<branch>` | `<bloco>` | ⚙️/🧠 + ponto de entrada | <data> |

4. Feche com 1 linha: para entrar num escopo, `/sessao start <slug>`. Se a branch atual coincide com a
   "Branch de trabalho" de algum escopo, diga isso como informação — nunca como escopo assumido.
5. Sinalize, 1 linha cada e sem corrigir nada:
   - slug diferente do nome da pasta do PLAN;
   - escopo com sessões no §8 e log de apontamento inexistente (`apontamento.existe: false` no JSON);
   - baton incoerente com o Board (o `--estado` sai com exit 1);
   - bloco gerenciado do `AGENTS.md` ausente ou desatualizado (`scripts/bloco_agents.sh --verificar`
     da skill), ou `scripts/conferencia_saida.sh` que é cópia integral do portão — nos dois casos, a
     correção é o `update`.

`/sessao escopos <slug>` detalha um só.

# `end` — fim de sessão

Opera o escopo do `start` desta sessão, ou o slug passado (`/sessao end <slug>`); sem nenhum dos dois,
pergunte. Leia antes: [`../referencia/conferencia.md`](../referencia/conferencia.md),
[`../referencia/apontamentos.md`](../referencia/apontamentos.md) e
[`../referencia/protocolo.md`](../referencia/protocolo.md) (fronteira de papel). Commit destinado a
deploy: [`../referencia/deploy.md`](../referencia/deploy.md). Bloco com change do OpenSpec:
[`../referencia/openspec.md`](../referencia/openspec.md).

## Duas metades, com gatilhos diferentes

| Metade | O que é | Quando dispara |
|---|---|---|
| **Relatório** (passo 1) | o detalhe denso do bloco | só quando o **bloco fecha**, ou o usuário pede |
| **Registro da sessão** (passos 2–6) | PLAN in-place · **linha no §8** · baton · validação → apontamento → portão → commit | em **toda** sessão que termina, tenha fechado bloco ou não |

## Três portas de entrada

- **O usuário pede o `end`** no meio de um bloco → sem relatório; **com** registro da sessão.
- **Fechamento de bloco inteiro** (toda a DoD satisfeita) → o Executor auto-dispara este ritual, sem o
  usuário pedir, antes de passar o baton. É a **única** porta que gera relatório.
- **PARADA no meio do bloco** — condição terminal que não é o fechamento (critério que não bateu,
  decisão de design ausente, estado inesperado, autorização faltando, limite técnico da ferramenta) →
  o Executor auto-dispara o registro da sessão, **sem relatório**: PLAN in-place (checkboxes, o motivo
  da parada, baton `🧠 Planejador`), linha nova no §8, e então validação → apontamento → portão →
  commit.

O índice do registro é um só: **a sessão terminou.**

## Passos

1. **Relatório** (só se o bloco fechou ou o usuário pediu): na pasta e no padrão de nome que a linha
   `Relatórios` do cabeçalho do PLAN declara — default
   `docs/sessoes/<slug>/RELATORIO_<bloco>_<AAAA-MM-DD>.md` —, pelo template compartilhado
   `docs/sessoes/template-relatorio.md`. Escopo migrado que declara outro padrão: respeite o declarado,
   não renomeie a convenção dele no meio do caminho. Detalhe denso: comandos, saídas, números.
2. **Atualize o PLAN in-place** (nunca duplique linhas): "🔎 Agora", Board, checkboxes do bloco ativo
   e **uma linha nova no fim do §8** (1 linha + link).
   ⚠️ "O bloco fechou" só é verdade se **todos** os critérios de aceite foram medidos e bateram. Um que
   mede diferente do alvo impede o 🟢: o bloco continua aberto, você registra a medição crua, grava o
   baton `🧠 Planejador` com o motivo e para.
   Se o bloco fechou, depende de quem está na sessão: o **🧠 Planejador** promove o próximo bloco de
   rascunho a detalhado e replaneja o resto; o **⚙️ Executor** marca o bloco 🟢, grava o baton
   `🧠 Planejador` com o motivo e **para** — não promove, não detalha, não replaneja.
   **Bloco fechou e o contrato declara uma change do OpenSpec?** Valide-a e arquive-a
   (`openspec archive <id> -y`) antes do portão: é o que funde o delta nas specs vivas, e o ⑦ reprova
   bloco concluído com a change aberta. Se o comportamento entregue diverge do delta, não arquive: é
   escalonamento ([`openspec.md`](../referencia/openspec.md)).
3. **Grave o baton** com o papel da próxima sessão e o ponto de entrada: `⚙️ Executor` se o bloco segue
   executor-ready; `🧠 Planejador` se a fronteira exige (re)planejamento (bloco fechou e o próximo está
   em rascunho, ou surgiu decisão de design em aberto).
4. **O escopo inteiro fechou?** Marque-o 🟢 Concluído no índice do `AGENTS.md` (a pasta fica como
   histórico). Opcional, só onde a ferramenta tiver memória automática: atualize os ponteiros se algo de
   alto nível mudou.
5. **Peça a validação do commit:** apresente o que foi feito e pergunte se pode commitar. Sem o "ok",
   tudo fica no working tree. Questionamento aberto ⇒ pare e pergunte.
6. **Com o "ok", nesta ordem:** escreva o apontamento ([`apontamentos.md`](../referencia/apontamentos.md))
   → rode o portão ([`conferencia.md`](../referencia/conferencia.md)) → commite.
   - Só o que é deste escopo e desta sessão (`openspec/` incluído); nada de `git add -A` cego. Arquivo modificado alheio à
     sessão: liste ao usuário e deixe de fora.
   - Sessão que tocou mais de um repo (repos irmãos): commite em cada um.
   - Na branch default, use a branch de trabalho declarada no PLAN.
   - Mensagem no padrão do projeto. Reporte o(s) hash(es).
   - `push` é pedido à parte, também com validação — inclusive quando o commit se destina a deploy.

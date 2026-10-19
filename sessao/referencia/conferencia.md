# Conferência de saída — obrigatória antes de qualquer commit de `end` ou `handoff`

O sistema falha por **inconsistência de registro**, não por falta de boa intenção: o agente escreve a
verdade em 3 lugares, esquece o 4º, e a sessão seguinte lê o 4º. Por isso o fechamento não depende de
cuidado — depende desta conferência, que é mecânica e se responde com o arquivo aberto e um comando.
Rode todos os itens e **não commite com nenhum vermelho**: vermelho é PARADA, não ressalva no
relatório.

## 🔒 Ordem canônica do fechamento — a validação do usuário é o eixo

1. Prepare tudo no working tree: `PLAN.md` in-place (cabeçalho, Board, checkboxes, **linha 🎬**, linha
   nova no §8), o relatório, se houver, e — se o bloco concluiu com uma change do OpenSpec — o
   `openspec archive <id> -y` ([`openspec.md`](openspec.md)).
2. Apresente ao usuário o que foi feito e **peça validação para commitar**.
3. **Sem o "ok": PARA.** Nada de commit, nada de push, nada de escrever no `work-log`.
4. Com o "ok": escreva o apontamento em `<work-log>/<slug>.md` ([`apontamentos.md`](apontamentos.md))
   — automático a partir daqui, não peça duas vezes.
5. Rode o portão (abaixo), com o apontamento já no lugar — antes disso o item ⑤ reprova por um motivo
   falso.
6. Commite.
7. `push` só com validação própria, pedida em separado.

O log vem depois do aval porque é append-only e fica fora do repo: apontamento gravado sobre trabalho
que o usuário rejeitou vira histórico falso que nenhum `git reset` desfaz.

## ⓪ O portão — rode e cole a saída crua no resumo da sessão

```bash
scripts/conferencia_saida.sh <slug> <commit em que esta sessão começou>
```

A ref-base é o `git rev-parse HEAD` anotado no `start`; se esqueceu, é o último commit da sessão
anterior. O portão sai com **exit 1** quando:

| Item | Reprova quando |
|---|---|
| ① | a linha `🎬 Próximo` falta ou está duplicada |
| ② | o parágrafo do baton (a linha e suas continuações indentadas) está **intacto** desde o início da sessão — o baton foi narrado, não passado |
| ③ | o ponto de entrada citado no baton é tarefa já `[x]` (baton podre) |
| ④ | o registro de sessões (§8) não ganhou linha nova |
| ⑤ | alguma linha nova do §8 não tem a **sua** chave `**Sessão:**` no log de apontamento |
| ⑥ | a sessão escreveu contrato de bloco e passou o baton para ⚙️ **sem** uma linha `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)` nova no PLAN |
| ⑦ | só em escopo com o módulo OpenSpec: o contrato do bloco ativo não traz a linha `- **OpenSpec:**` com a change ou com o motivo de não haver uma (cobrado com o baton no ⚙️ ou com o bloco concluído); ou a change declarada não existe, não valida, tem `skip_specs`, continua aberta com o bloco concluído, ou não há CLI para validá-la ([`openspec.md`](openspec.md)) |

**Declarar que conferiu não substitui rodar.** Exit 2 é erro de uso ou portão que não rodou (o
lançador não achou a skill) — nunca é aprovação.

Repo sem o portão, ou com a **cópia integral** dele em `scripts/conferencia_saida.sh` no lugar do
lançador: rode o `update` ([`../subcomandos/update.md`](../subcomandos/update.md)), que instala o
lançador. Cópia integral fica congelada na versão do dia em que foi copiada.

⚠️ **Mexeu no portão ou no `PLAN.template.md`? Rode `scripts/autoteste_portao.sh` da skill** antes de
commitar. Ele monta repositórios descartáveis a partir dos templates e afirma que cada item dispara
quando deve e fica verde quando deve.

## Os itens que seguem na mão (o portão cobre só ①-⑦)

1. **Critérios de aceite — cada um MEDIDO** (comando + saída crua) e batendo com o alvo. Um só que não
   bata ⇒ o bloco **não** fecha: nada de 🟢, nada de "fechado com ressalva", nada de reinterpretar o
   critério pela intenção que você lê nele. Registre o que mediu, grave o baton `🧠 Planejador` com o
   motivo e pare.
2. **Baton — a linha, não a prosa.** Ela diz o papel e o ponto de entrada certos **para depois desta
   sessão**? Confira contra o Board: bloco citado 🟢 ou tarefa citada `[x]` ⇒ linha podre; corrija
   antes do commit. Escrever "baton → 🧠" só no resumo, no relatório ou na mensagem de commit não troca
   o baton.
3. **Um estado, um lugar.** Cabeçalho, Board, §8 e mensagem de commit batem com a linha 🎬? Divergiu,
   a linha 🎬 vence e os resumos se ajustam a ela.
4. **Board × checkboxes.** Todo bloco 🟢 tem todas as tarefas `[x]`; nenhum bloco com tarefa aberta
   está 🟢.
5. **Número e append vêm do arquivo, não da memória.** A chave da linha nova do §8 sai da própria
   tabela ([`apontamentos.md`](apontamentos.md)): com coluna de número, o último valor da tabela + 1
   (nunca o número do relatório, que tem série própria); sem ela, `<AAAA-MM-DD>#<k>` — não invente
   número. O nome do relatório segue o padrão declarado no cabeçalho do PLAN, conferindo o último
   gravado na pasta.
6. **In-place, sem 2ª cópia:** o que você escreveu atualizou o campo existente, em vez de criar uma
   segunda cópia dele em outro ponto do arquivo.
7. **`git status` limpo de estranhos:** só o que é deste escopo e desta sessão entra no commit.
8. **Documento de interface não envelheceu.** Se a sessão mudou comportamento que algum documento
   voltado a terceiro descreve (chefe ou negócio, DBA, README do escopo, contrato publicado), ele foi
   atualizado nesta sessão, ou a pendência está escrita com dono. É o único item cuja falha ninguém
   descobre lendo código nem rodando teste. Com o módulo OpenSpec, o comportamento tem fonte única em
   `openspec/specs/` e o ⑦ confere a change; este item continua para os documentos voltados a terceiros
   que descrevem o mesmo comportamento — o que puder, aponte para a spec em vez de repeti-la.
9. **Nenhuma decisão pendente foi selada por fora.** Decisão do usuário que ficou sem resposta não
   vira premissa do contrato, "recomendação" no fim da mensagem nem tarefa do Executor: ou foi
   respondida, ou o bloco não fecha. O ⑥ pega a **falta** de aceite; este pega o aceite obtido sobre um
   plano **incompleto**, que nenhum comando enxerga.

**Por que checklist e não "seja cuidadoso":** transparência no relatório não impede que a próxima
sessão leia o campo errado; só a conferência impede.

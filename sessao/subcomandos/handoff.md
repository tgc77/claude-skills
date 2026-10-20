# `handoff` — preparar a troca de modelo (Planejador → Executor)

**Quem dispara:** o 🧠 Planejador, sozinho, quando o bloco que ele planejou fica executor-ready — é o
fechamento de uma sessão aberta com `start` e baton 🧠. O usuário só digita `/sessao handoff [<slug>]`
para ir direto a este ponto, por exemplo logo depois do `init`, na mesma sessão. Para ver onde o escopo
parou — se o baton foi mesmo para o Executor, por exemplo —, o caminho é o `escopos` ou um `start` com
nota de briefing, que não alteram nada: rodado de novo sobre um bloco já entregue, o `handoff` refaz o
ritual.

Opera o escopo do `start` desta sessão, ou o slug passado (`/sessao handoff <slug>`); sem nenhum dos
dois, pergunte. Leia antes: [`../referencia/protocolo.md`](../referencia/protocolo.md) (DoD do
planejamento), [`../referencia/conferencia.md`](../referencia/conferencia.md),
[`../referencia/apontamentos.md`](../referencia/apontamentos.md) e, se o PLAN tem o parâmetro
**OpenSpec**, [`../referencia/openspec.md`](../referencia/openspec.md).

1. **Verifique se o bloco ativo está executor-ready** (DoD do planejamento): tarefas atômicas com
   checagem verificável; decisões resolvidas; comandos, paths e valores preenchidos; DoR satisfeito;
   escalonamento definido. Se o bloco muda comportamento descrito em documento de interface (chefe ou
   negócio, DBA, README do escopo), a atualização daquele documento entra como **tarefa do bloco, com
   o arquivo nomeado** — não como lembrete no fim.
2. **MEÇA cada critério de aceite no estado atual antes de fixá-lo como alvo — nenhum é deduzido.**
   Rode o comando do critério no commit do handoff e escreva o valor observado ao lado do alvo. Se o
   baseline já reprova o critério: mude o alvo, ou torne a correção tarefa explícita do bloco.
3. **Escopo com o módulo OpenSpec: declare o bloco no contrato**, numa das duas formas:

   ```text
   - **OpenSpec:** change `<id>`
   - **OpenSpec:** não se aplica — <motivo>
   ```

   A change, quando o bloco muda comportamento de que alguém depende: crie-a, escreva a proposta e o
   delta e valide-a ([`openspec.md`](../referencia/openspec.md)). Sem a declaração, o ⑦ do portão
   reprova o handoff.
4. Ajuste o que faltar no PLAN do escopo e confirme que um executor consegue tocar à risca.
5. **Grave o baton** no "🔎 Agora": `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <1ª tarefa não
   concluída>`, listando quais gates por-sessão reestabelecer antes (DoR + setup vivo). É esse baton
   que faz o `start` seguinte entrar como Executor sem perguntar. **Acrescente a linha desta sessão no
   fim do §8** — handoff é sessão como qualquer outra, e é dessa linha que sai a chave do apontamento.
6. **Mostre o plano ao usuário e peça o aceite — e, com ele, a validação do commit.** Com change do
   OpenSpec, mostre também a proposta e o delta: o aceite cobre os dois.
   ⛔ Pré-condição dos passos 7–9: o plano foi **mostrado e aceito**, e o bloco ganhou a linha
   `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)`. Um handoff é contrato novo indo para o Executor; sem
   aceite, não commite e não escreva no log. Responder às perguntas do agente não é aceitar o plano. Se
   houver questionamento aberto, pare e pergunte. Sem o "ok", as edições ficam no working tree.
7. **Registre o apontamento da sessão** ([`apontamentos.md`](../referencia/apontamentos.md)), só depois
   do "ok". Handoff não gera relatório; a fonte é a linha do §8, as Decisões e os commits da sessão.
8. **Rode a Conferência de saída** ([`conferencia.md`](../referencia/conferencia.md)), agora com o
   apontamento no lugar: baton coerente com o Board, resumos batendo com a linha 🎬, sem 2ª cópia de
   campo, aceite registrado e, com o módulo OpenSpec, change válida (⑦).
9. **Commite as edições do handoff** (mesma regra do `end`): só o que é do escopo e da sessão, `openspec/` incluído. Reporte
   o hash. `push` é pedido à parte.
10. **Feche com os próximos passos** ([`conferencia.md`](../referencia/conferencia.md), seção "Próximos
    passos"): a próxima sessão é a do ⚙️ Executor, com um modelo mais barato.

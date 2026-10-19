# `handoff` — preparar a troca de modelo (Planejador → Executor)

Opera o escopo do `start` desta sessão, ou o slug passado (`/sessao handoff <slug>`); sem nenhum dos
dois, pergunte. Leia antes: [`../referencia/protocolo.md`](../referencia/protocolo.md) (DoD do
planejamento), [`../referencia/conferencia.md`](../referencia/conferencia.md) e
[`../referencia/apontamentos.md`](../referencia/apontamentos.md).

1. **Verifique se o bloco ativo está executor-ready** (DoD do planejamento): tarefas atômicas com
   checagem verificável; decisões resolvidas; comandos, paths e valores preenchidos; DoR satisfeito;
   escalonamento definido. Se o bloco muda comportamento descrito em documento de interface (chefe ou
   negócio, DBA, README do escopo), a atualização daquele documento entra como **tarefa do bloco, com
   o arquivo nomeado** — não como lembrete no fim.
2. **MEÇA cada critério de aceite no estado atual antes de fixá-lo como alvo — nenhum é deduzido.**
   Rode o comando do critério no commit do handoff e escreva o valor observado ao lado do alvo. Se o
   baseline já reprova o critério: mude o alvo, ou torne a correção tarefa explícita do bloco.
3. Ajuste o que faltar no PLAN do escopo e confirme que um executor consegue tocar à risca.
4. **Grave o baton** no "🔎 Agora": `🎬 Próximo: ⚙️ Executor · Ponto de entrada: <1ª tarefa não
   concluída>`, listando quais gates por-sessão reestabelecer antes (DoR + setup vivo). É esse baton
   que faz o `start` seguinte entrar como Executor sem perguntar. **Acrescente a linha desta sessão no
   fim do §8** — handoff é sessão como qualquer outra, e é dessa linha que sai a chave do apontamento.
5. **Mostre o plano ao usuário e peça o aceite — e, com ele, a validação do commit.**
   ⛔ Pré-condição dos passos 6–8: o plano foi **mostrado e aceito**, e o bloco ganhou a linha
   `**Aceite:** <quem>, <AAAA-MM-DD> (bloco <id>)`. Um handoff é contrato novo indo para o Executor; sem
   aceite, não commite e não escreva no log. Responder às perguntas do agente não é aceitar o plano. Se
   houver questionamento aberto, pare e pergunte. Sem o "ok", as edições ficam no working tree.
6. **Registre o apontamento da sessão** ([`apontamentos.md`](../referencia/apontamentos.md)), só depois
   do "ok". Handoff não gera relatório; a fonte é a linha do §8, as Decisões e os commits da sessão.
7. **Rode a Conferência de saída** ([`conferencia.md`](../referencia/conferencia.md)), agora com o
   apontamento no lugar: baton coerente com o Board, resumos batendo com a linha 🎬, sem 2ª cópia de
   campo, aceite registrado.
8. **Commite as edições do handoff** (mesma regra do `end`): só o que é do escopo e da sessão. Reporte
   o hash. `push` é pedido à parte.

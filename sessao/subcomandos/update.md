# `update` — pôr o projeto em dia com a skill

Age só sobre o repositório atual. **Não assume escopo e não lê PLAN.** `<skill>` abaixo é o diretório
desta skill.

1. **Bloco gerenciado do `AGENTS.md`.** Rode `<skill>/scripts/bloco_agents.sh --verificar AGENTS.md`.
   - **Exit 0** → em dia.
   - **Desatualizado** → mostre o diff que o script imprime e, com o "ok", rode `--aplicar`: ele
     reescreve só o que está entre `<!-- sessao:inicio` e `<!-- sessao:fim -->` e não toca no resto
     do arquivo.
   - **Sem marcadores** (o `AGENTS.md` ainda tem o protocolo copiado, de antes do bloco gerenciado) →
     **migração**, feita por você com o usuário:
     1. Separe o que é **do projeto** — introdução, índice de escopos, convenções, repos irmãos,
        guardrails permanentes e qualquer regra que só exista neste repo — do que é **protocolo
        genérico**: leitura obrigatória no início de sessão, papéis 🧠/⚙️, ritual de fim de turno,
        Conferência de saída, regras de troca de escopo.
     2. Monte o arquivo novo no formato de `templates/AGENTS.template.md`: o que é do projeto fica, o
        protocolo genérico sai (ele mora na skill) e o bloco gerenciado entra logo depois da
        introdução.
     3. Regra que só existe neste repo e parece protocolo: **não apague**. Mantenha-a numa seção
        "Notas deste projeto" e aponte-a ao usuário.
     4. Mostre o diff e só grave com o "ok".
   - **Marcadores duplicados ou fora de ordem** → o script recusa; corrija à mão com o usuário.
2. **Lançador do portão.** `scripts/conferencia_saida.sh` tem de ser o lançador (o cabeçalho dele diz
   "LANÇADOR do portão"). Se for a cópia integral do portão, ou não existir, copie
   `<skill>/scripts/conferencia_saida.shim.sh` para lá e dê `chmod +x`. Cópia integral fica congelada
   na versão do dia em que foi copiada.
3. **`CLAUDE.md`.** Tem de importar o `AGENTS.md` (`@AGENTS.md`). Se ele ainda carrega o índice de
   escopos (layout legado), ofereça movê-lo para o `AGENTS.md` — o Codex não lê `CLAUDE.md`. Texto que
   descreve o `AGENTS.md` como "protocolo permanente" ficou falso: ajuste.
4. **Ambiente do OpenSpec** ([`../referencia/openspec.md`](../referencia/openspec.md)). Rode
   `<skill>/scripts/openspec_ambiente.sh --verificar`. Ele confere a máquina (CLI e versão mínima,
   `node`, telemetria desligada, schema `sessao` ligado à skill) e, se o repositório tem `openspec/`, o
   `config.yaml` e a ausência de cópia local do schema. Symlink ou telemetria → `--aplicar`, com o
   "ok"; CLI ausente → mostre os comandos de instalação e ofereça rodá-los, como no `init`. Só pesa para escopos com o
   parâmetro **OpenSpec**; repositório sem nenhum escopo assim não precisa do OpenSpec.
5. **Commit isolado, com validação do usuário**, só com os arquivos acima. Reporte o hash e pergunte se
   pode fazer o push — em separado do ok do commit.

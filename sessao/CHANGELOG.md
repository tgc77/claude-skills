# Changelog — skill `sessao`

O que muda para quem usa a skill, versão a versão. Formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
numeração [SemVer](https://semver.org/lang/pt-BR/), com o critério de MAJOR, MINOR e PATCH descrito na seção
[Versionamento](../README.md#versionamento) do README. O porquê de cada regra mora no
[`HISTORICO.md`](HISTORICO.md); aqui ficam o quê e o quando.

## [Não lançado]

### Corrigido
- `HELP.md`, `referencia/protocolo.md` e `referencia/layout.md` descrevem o bloco gerenciado inteiro: a
  ativação explícita e as duas regras que valem em qualquer sessão. O layout do projeto mostra a pasta
  `openspec/`, e o `README.md` da skill lista o `referencia/openspec.md` entre as referências.
- A forma `não se aplica — <motivo>` aparece como código no `SKILL.md`, no `HELP.md`, no
  `HISTORICO.md` e na entrada da 3.1.0: fora de código, o `<motivo>` era lido como tag HTML e sumia da
  página renderizada.

## [3.1.0] - 2026-10-19

**Ação nos projetos:** rode `/sessao update` em cada repositório que usa a skill: o bloco gerenciado
ganhou a regra "identificador sozinho não é contexto". Escopo novo passa a exigir o CLI do OpenSpec na
máquina (instalação em `referencia/openspec.md`); os escopos que já existem seguem sem o módulo.

### Adicionado
- **Módulo OpenSpec: specs vivas por bloco.** Todo escopo novo nasce com o parâmetro **OpenSpec** no
  PLAN, e o contrato de cada bloco declara a sua change (proposta + delta das specs, validada antes do
  aceite e arquivada quando o bloco conclui) ou `não se aplica — <motivo>`. Vem com o schema `sessao`
  (proposta + specs, sem tarefas), ligado ao OpenSpec por symlink, e com `referencia/openspec.md`.
- Item ⑦ do portão: cobra a declaração e, havendo change, que ela exista, valide e seja arquivada ao
  concluir o bloco; sem o CLI, falha fechado. O `--estado` ganha o campo `openspec`.
- `scripts/openspec_ambiente.sh` (`--verificar`, `--aplicar`, `--preparar-repo`): CLI e versão mínima,
  telemetria sempre desligada, schema ligado à skill e `openspec/` no repositório. O `init` e o
  `update` o usam.
- Regra "identificador sozinho não é contexto", no bloco gerenciado e nas regras invioláveis: pergunta
  ao usuário traz, ao lado de cada rótulo interno, o que ele é e o que muda em cada opção.
- Casos 41 a 54 do autoteste, um deles com o OpenSpec real.

### Modificado
- O item 8 da Conferência (documento de interface) aponta para a spec viva nos escopos com o módulo.
- Os exemplos de slug e de capacidade deixam de usar nomes de um projeto específico.

## [3.0.0] - 2026-10-19

Terceira geração do Controle de Sessões: o protocolo sai dos repositórios e passa a morar só na skill.

**Ação nos projetos:** rode `/sessao update` em cada repositório que usa a skill. O `AGENTS.md` com o
protocolo copiado passa a ter o bloco gerenciado, e o conteúdo próprio do projeto fica. Os 7
repositórios da Cobrança foram migrados em 2026-10-19.

### Adicionado
- Subcomando `update` e o script `scripts/bloco_agents.sh` (`--verificar` e `--aplicar`). Eles mantêm
  o bloco gerenciado do `AGENTS.md`, entre `<!-- sessao:inicio` e `<!-- sessao:fim -->`, igual ao
  template, sem tocar no resto do arquivo.
- Modo `--estado` do portão: devolve o estado do escopo em JSON (baton e a coerência dele, bloco ativo,
  tarefas, gates 🔁, sessões no registro, apontamento). O `start` e o `escopos` passam a usá-lo em vez
  de o modelo interpretar o PLAN sozinho.
- `HISTORICO.md`, com o incidente que originou cada regra, fora do que é carregado para operar.
- Casos 33 a 40 do autoteste: bloco gerenciado, `--estado` e o ⑥ com "⚙" sem seletor de variação.

### Modificado
- **O protocolo mora só na skill.** O `AGENTS.template.md` fica com o bloco gerenciado, o índice de
  escopos, as convenções e os guardrails do projeto, e cai de 3.839 para 449 palavras.
- **Ativação só explícita.** O `start` exige o slug escrito e não deduz mais o escopo pelo único ativo
  nem pela branch. Fora de `/sessao start <slug>`, todo pedido é avulso.
- **Leitura sob demanda.** O `SKILL.md` vira roteador e cai de 10.038 para 1.229 palavras. Cada
  subcomando ganha um arquivo em `subcomandos/`, as regras de apoio vão para `referencia/` e o
  `HELP.md` vira índice.
- Os templates do `CLAUDE.md` e do `PLAN.md` apontam para a skill em vez de repetir o protocolo.

### Removido
- `templates/BOOTSTRAP.md`: o `init` já faz o que ele fazia.

### Corrigido
- Item ⑥ do portão: um baton escrito "⚙ Executor", sem o seletor de variação (U+FE0F), deixava
  passar contrato sem aceite.

## Antes do versionamento

Até a 3.0.0 a skill não tinha número. O primeiro commit (2026-06-26) já a chamava de "controle de
sessões v2", e a reestruturação de 2026-10-19 quebrou o contrato dessa v2; daí a 3.0.0. Marcos da v2,
do mais recente ao mais antigo (os detalhes estão no `git log`):

- **2026-09-25** — o ⑤ confere a chave de cada sessão nova; o portão enxerga PLAN fora do git. Último
  commit da v2: `193cfdb`.
- **2026-09-07 a 09-11** — o portão vira lançador (uma cópia só, na skill), lê checkbox de gate e
  aceita registro retroativo; autoteste ampliado; o ② mede o parágrafo do baton; o ⑥ enxerga dois
  aceites no mesmo dia.
- **2026-09-01 a 09-04** — o Executor segue até uma condição terminal; PARADA no meio do bloco;
  `agents/openai.yaml` bloqueia a invocação implícita no Codex.
- **2026-08-29 a 08-30** — aceite de plano, autoteste do portão e compatibilidade com o Codex; índice
  de escopos no `AGENTS.md`.
- **2026-08-17 a 08-19** — gate em vez de recomendação; apontamento por sessão; gate de documento de
  interface; a Conferência de saída vira portão executável.
- **2026-08-05 a 08-06** — layout multi-escopo (um `PLAN.md` por escopo); escopo como argumento; slug
  como identificador único.
- **2026-07-18 a 07-22** — integração com a `resumo-trabalho`; entrega destinada a deploy (o push no
  mesmo turno foi revogado em 2026-08-24).
- **2026-07-03 a 07-06** — baton de papel e gates por sessão; fronteira de papel e PARADA (o Executor
  não se autopromove).
- **2026-06-26** — nasce a skill; ela vira a fonte canônica e o kit passa a ser espelho.

[Não lançado]: https://github.com/tgc77/claude-skills/compare/sessao-v3.1.0...HEAD
[3.1.0]: https://github.com/tgc77/claude-skills/compare/sessao-v3.0.0...sessao-v3.1.0
[3.0.0]: https://github.com/tgc77/claude-skills/compare/193cfdb...sessao-v3.0.0

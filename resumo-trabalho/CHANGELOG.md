# Changelog — skill `resumo-trabalho`

O que muda para quem usa a skill, versão a versão. Formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
numeração [SemVer](https://semver.org/lang/pt-BR/), com o critério de MAJOR, MINOR e PATCH descrito na seção
[Versionamento](../README.md#versionamento) do README.

## [Não lançado]

### Corrigido
- Pedido de resumo sem card, numa conversa sem label nem escopo ativo, pergunta o card em vez de
  escolher o escopo pelo índice do `AGENTS.md` do repositório. A escolha contradizia a ativação
  explícita da `sessao`, que o bloco gerenciado do `AGENTS.md` também exige. O agente ainda pode listar
  os escopos do índice como opções na pergunta.

## [1.0.1] - 2026-10-19

### Modificado
- O exemplo de referência cruzada de MR deixa de usar o nome de um repositório específico.

## [1.0.0] - 2026-10-19

Primeira versão numerada. O conteúdo é o mesmo do commit `0edce24` (2026-09-25) e nada muda no
comportamento.

### Adicionado
- Log de trabalho por label (card do GitLab), fora de qualquer repositório, alimentado por sessões de
  projetos diferentes: `label`, `registrar` e `listar`.
- Resumo no modelo "Apontamentos" (markdown GitLab, pt-BR, copiável) com `gerar <card>`: de hoje, de
  uma data ou completo. O agregado do dia (`gerar dia`) sai só sob pedido explícito.

## Antes do versionamento

Marcos, do mais recente ao mais antigo (os detalhes estão no `git log`):

- **2026-09-25** — caminho do log, índice de escopos no `AGENTS.md` e chave de sessão.
- **2026-09-22** — o link de todo documento gerado entra no apontamento.
- **2026-09-04** — título de subseção não carrega horário.
- **2026-08-18** — o alvo do `gerar` é o escopo ativo, não o agregado do dia.
- **2026-07-22** — regra do leitor não técnico: explicar antes, sem cortar detalhe.
- **2026-07-18** — a skill entra no repositório, junto com a integração com a `sessao`.

[Não lançado]: https://github.com/tgc77/claude-skills/compare/resumo-trabalho-v1.0.1...HEAD
[1.0.1]: https://github.com/tgc77/claude-skills/compare/resumo-trabalho-v1.0.0...resumo-trabalho-v1.0.1
[1.0.0]: https://github.com/tgc77/claude-skills/releases/tag/resumo-trabalho-v1.0.0

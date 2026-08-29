@AGENTS.md

## Claude Code

> Todo o conteúdo — protocolo permanente **e** índice de escopos — mora no
> [`AGENTS.md`](AGENTS.md), importado pela linha acima. **Não duplique nada aqui.**
>
> **Por que assim:** o Claude Code lê `CLAUDE.md` e **não** lê `AGENTS.md`; o Codex (e demais agentes
> que seguem a convenção `AGENTS.md`) lê `AGENTS.md` e **não** lê `CLAUDE.md`. Com o import, os dois
> leem exatamente a mesma fonte, sem cópia e sem risco de divergirem. Se o índice de escopos ficasse
> só aqui, o Codex não o enxergaria por conta própria.
>
> ⛔ **Não crie `AGENTS.override.md`.** No Codex ele **substitui** o `AGENTS.md` do mesmo nível em vez
> de somar ("uses only the first non-empty file"), o que faria sombra no protocolo inteiro — e, se
> cada ferramenta lesse um arquivo diferente, dois agentes rodariam protocolos divergentes sobre o
> mesmo PLAN. O override é recurso temporário, não endereço permanente.

<Instruções específicas do Claude Code, se houver — ex.: usar plan mode em `src/x/`.>

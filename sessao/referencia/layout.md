# Layout, slug e resolução de escopo

> Lido por `init`, `start`, `escopos` e `update`. O porquê das regras está em
> [`../HISTORICO.md`](../HISTORICO.md).

## Layout canônico (um repo, vários escopos)

Um repositório vive mais que um escopo: hoje é uma feature, amanhã uma correção, depois uma
investigação. **O protocolo mora na skill; o plano é por escopo.** A raiz do projeto nunca cresce a
cada frente nova:

```
<repo>/
├── CLAUDE.md                  ← `@AGENTS.md` (+ seção do Claude Code, se houver)
├── AGENTS.md                  ← índice de escopos + regras do projeto + bloco gerenciado da skill
├── scripts/
│   └── conferencia_saida.sh   ← LANÇADOR do portão: acha a skill e roda o portão dela
└── docs/sessoes/
    ├── template-relatorio.md  ← um por repo, reusado por todo escopo
    └── <slug>/                ← um escopo = uma pasta
        ├── PLAN.md            ← fonte única de verdade daquele escopo
        └── RELATORIO_<bloco>_<AAAA-MM-DD>.md
```

**O que vai onde — não misture:**

| Na skill `sessao` | No `AGENTS.md` do projeto | No `PLAN.md` do escopo |
|---|---|---|
| Papéis 🧠/⚙️, DoD do planejamento, ritual de fechamento, portão | O **bloco gerenciado** (ativação explícita + questionamento aberto), mantido pelo `update` | Escopo, objetivo, Board, blocos, contrato de execução |
| Regras de slug, layout e resolução de escopo | O **índice de escopos** (slug → PLAN, com estado) | Slug e descrição daquele escopo |
| Integração com o `resumo-trabalho` | Convenções de commit, idioma, tratamento do usuário, repos irmãos | Branch de trabalho do escopo |
| | Guardrails **permanentes** do projeto (segredos, produção, ações destrutivas) | Ambiente, `KUBECONFIG`, namespaces e guardrails **daquele** escopo |

**Nada de protocolo copiado no `AGENTS.md`:** cópia congela na versão do dia em que foi feita. O
`AGENTS.md` carrega só o bloco gerenciado, curto, que o `update` mantém igual ao template. E nada
específico de escopo entra no `AGENTS.md`, senão o próximo escopo herda restrição que não é dele.

**`CLAUDE.md` × `AGENTS.md`:** o Claude Code lê `CLAUDE.md` e não lê `AGENTS.md`; o Codex lê
`AGENTS.md` e não lê `CLAUDE.md`. Por isso tudo mora no `AGENTS.md`, e o `CLAUDE.md` é só o import
`@AGENTS.md` (mais instruções específicas do Claude Code, se houver). Nunca duplique conteúdo nos dois:
se o índice ficasse só no `CLAUDE.md`, o Codex não o enxergaria.

⛔ **Não use `AGENTS.override.md`.** No Codex ele **substitui** o `AGENTS.md` do mesmo nível em vez de
somar ("uses only the first non-empty file at this level"), e dar arquivos diferentes a ferramentas
diferentes fabrica dois agentes com protocolos divergentes sobre o mesmo PLAN. O conflito real entre
ferramentas não é de arquivo, é de **working tree**: duas sessões na mesma árvore ao mesmo tempo
colidem em arquivos e commits.

**Layout legado (compatibilidade):** projetos instalados antes do modelo multi-escopo têm o `PLAN.md`
na raiz e o índice (ou o protocolo) no `CLAUDE.md`. Continue operando neles como estão — `start`,
`handoff` e `end` funcionam igual. Migre só se o usuário pedir, ou ofereça a migração quando ele for
abrir um segundo escopo no mesmo repo. O suporte ao legado nos scripts (PLAN na raiz, índice no
`CLAUDE.md`, §8 numerado) é deliberado: não remova como limpeza.

## Escopo × slug

| | O que é | Onde vive |
|---|---|---|
| **slug** | o identificador único do escopo; tudo o mais deriva dele | coluna `Slug` do índice, linha `Slug` do PLAN, nome da pasta, nome do log de apontamento |
| **escopo** | a descrição legível daquele slug | coluna `Escopo` do índice, `**Escopo:**` do PLAN |

**Invariantes do slug (valem em qualquer repo):**

1. **Um escopo, um nome — sem apelidos.** Nome que precisa mudar é **rename**, não um segundo nome.
2. **Único globalmente**, não só no repo, porque o log de apontamento é global (`<work-log>/<slug>.md`).
   Prefira nomes distintivos (`upgrade-postgres-16`, `poc-cache-redis`) a genéricos (`upgrade`,
   `poc`), que colidem com outro projeto no dia seguinte.
3. **slug == nome da pasta** (`docs/sessoes/<slug>/`) **== label do `resumo-trabalho`**. Uma string
   só, sem campo separado de label.
4. **kebab-case**, sem espaço nem acento — ele é nome de pasta e de arquivo.

⚠️ Enquanto um escopo antigo tiver pasta ≠ slug (migração não feita), o caminho do PLAN vem da
**coluna PLAN do índice**, não da derivação. Isso não é apelido: o nome continua um só, só o caminho
não é calculável. Escopo novo sempre nasce com slug == pasta.

**Renomear o slug (ato explícito, nunca automático):** `git mv` da pasta para o slug novo · atualizar
a linha `Slug` do PLAN e a coluna `Slug` do índice · reescrever os caminhos que citam a pasta antiga ·
decidir o log (`<work-log>/<slug-velho>.md`): renomeá-lo junto, ou manter o antigo como histórico e o
slug seguir o log — o que preserva histórico vence. Diga ao usuário o que aconteceu com o log; nunca
deixe apontamento órfão em silêncio.

## Resolução de escopo

Sintaxe: `/sessao <subcomando> [<slug>] [<texto livre>]`. **O escopo é argumento, não estado:** não
existe ponteiro de "escopo ativo" guardado em lugar nenhum (ponteiro fica velho, é global enquanto a
sessão é local, e não acompanha a troca de branch).

- **`start` exige o slug escrito:** `/sessao start <slug> [nota]`. Sem slug, não escolha: liste os
  escopos e pergunte qual.
- **`handoff` e `end`** operam o escopo do `start` desta sessão, ou o slug passado explicitamente
  (`/sessao end <slug>`). Sem nenhum dos dois, pergunte.
- **Nunca deduza o escopo** pela branch atual, por haver um único escopo 🟡 ativo, pelo índice ou pelo
  repositório.
- **Match exato:** procure o slug na coluna `Slug` do índice (no `AGENTS.md`; em projeto legado, no
  `CLAUDE.md`). Nome que não está lá ⇒ pare e liste os slugs que existem. Não aproxime para o
  parecido, não crie escopo por engano e não invente um segundo nome para um escopo que já tem o seu.
- Diga em 1 linha qual escopo assumiu.

**Um escopo por vez em cada working tree.** Escopos são isolados por pasta (baton, Board, checkboxes e
relatórios próprios), então alternar entre eles é seguro; o que não é seguro é duas sessões
simultâneas no mesmo working tree. Paralelo real: `git worktree`. Vale igual entre Claude Code e Codex.

⚠️ **O PLAN é versionado: quem determina o estado que a sessão enxerga é a branch, não o índice.** Se o
escopo A vive na branch `feature/a` e o B na `feature/b`, ao trabalhar em B o PLAN de A pode estar
ausente ou velho, e parece que o trabalho sumiu. Por isso `docs/sessoes/**` e o `AGENTS.md` vivem na
**branch base** compartilhada — mergeie cedo e com frequência (são documentação, não código da
feature). Se o usuário mantém PLANs em branches separadas, avise do risco antes de operar.

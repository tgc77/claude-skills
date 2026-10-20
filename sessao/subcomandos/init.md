# `init` — abrir um escopo (instalando o sistema, se ainda não houver)

Leia antes: [`../referencia/layout.md`](../referencia/layout.md) (layout do projeto e regras do slug) e
[`../referencia/openspec.md`](../referencia/openspec.md) (todo escopo novo nasce com o módulo OpenSpec).

## 0. Detecte o estado do repo antes de qualquer coisa — `init` nunca sobrescreve instalação existente

- **Repo virgem** (sem `AGENTS.md`/`CLAUDE.md` de controle e sem escopo no índice) → instalação
  completa (passos 1–6).
- **Repo já instalado** (há índice com escopos, mesmo que nenhum deles em `docs/sessoes/`) → é escopo
  novo: crie **só** `docs/sessoes/<slug>/PLAN.md`, acrescente a linha do escopo no índice do
  `AGENTS.md` (em projeto legado que ainda não migrou o índice, no `CLAUDE.md`) e prepare o OpenSpec
  (passo 4). Não recrie nem
  reescreva `AGENTS.md`, `CLAUDE.md` (fora a linha nova) ou o template de relatório. Se o `AGENTS.md`
  ainda tiver o protocolo copiado em vez do bloco gerenciado, ofereça o `update` antes.
- **Layout legado** (PLAN na raiz) → diga isso e ofereça migrar para o layout canônico antes de abrir o
  escopo novo; se o usuário recusar, **não** invente um segundo PLAN na raiz.

## 1. Leia os templates necessários ao caso

`templates/AGENTS.template.md`, `templates/CLAUDE.template.md` e `templates/PLAN.template.md` — só os
que o caso detectado pede.

## 2. Levante os `<PLACEHOLDERS>` com o usuário — não invente

- **Sempre (por escopo):** o **slug** (identificador único: vira pasta, label e nome do log) e o
  **escopo** (descrição legível de 1 linha); o que fica **fora** dele; a lista inicial de blocos (id +
  título + tipo 🔧 mecânico / 🔬 descoberta); a **branch de trabalho**; o **ambiente** (cluster,
  `KUBECONFIG`, namespaces, dados) e os **guardrails específicos**.
- **Valide o slug antes de aceitá-lo** — ele é chave primária, e corrigir depois custa rename:
  kebab-case; ainda não existe na coluna `Slug` do índice deste repo; e não colide globalmente —
  confira `ls "${SESSAO_WORKLOG_DIR:-$HOME/.claude/work-log}"` e, se já houver um `<slug>.md` de outro
  trabalho, proponha um nome mais distintivo (`upgrade-postgres-16`, não `upgrade`).
- **Não pergunte o label de apontamento** — ele **é** o slug. Quem quer apontar num card já existente
  escolhe o slug igual ao card; não existe segundo campo.
- **Não pergunte a pasta de relatórios** — ela é `docs/sessoes/<slug>/`.
- **Só na 1ª instalação (por repo):** como tratar o usuário; idioma; política de commit; repos irmãos
  que uma sessão pode tocar; guardrails permanentes.

## 3. Confirme a estrutura antes de criar

Mostre em texto a árvore, o Board e os guardrails. Só crie depois do "ok".

## 4. Crie os arquivos

- **Só na 1ª instalação:**
  - `AGENTS.md`, a partir de `templates/AGENTS.template.md`: o **bloco gerenciado** copiado sem
    alteração (do marcador `<!-- sessao:inicio` até `<!-- sessao:fim -->`), o índice de escopos, as
    convenções e os guardrails permanentes. **Nada de protocolo além do bloco** — ele mora na skill.
  - `CLAUDE.md`, a partir de `templates/CLAUDE.template.md`: só o import `@AGENTS.md` (mais uma seção
    do Claude Code, se houver). ⛔ Nada de `AGENTS.override.md`.
  - `docs/sessoes/template-relatorio.md` (copiado de `templates/`).
  - `scripts/conferencia_saida.sh`: copie o **lançador** `scripts/conferencia_saida.shim.sh` da skill
    e dê `chmod +x`. ⛔ Não copie o portão em si: o lançador resolve a skill em tempo de execução
    (`$SESSAO_SKILL_DIR` → `~/.claude/skills/sessao` → `~/.codex/skills/sessao` →
    `<repo>/.agents/skills/sessao`) e falha fechado (exit 2) se não a achar — portão que não roda não
    pode parecer portão que passou.
- **Sempre, o OpenSpec:** rode `<skill>/scripts/openspec_ambiente.sh --verificar`. Falta symlink ou
  telemetria desligada → `--aplicar`. **CLI ausente → PARE**, mostre os comandos de instalação de
  [`../referencia/openspec.md`](../referencia/openspec.md) e ofereça rodá-los: a decisão de instalar é
  do usuário, a execução é sua. Com o ok, rode-os na ordem, a conferência de assinaturas incluída, e
  siga; assinatura que não confere ⇒ PARE e mostre a saída. Com o ambiente pronto, `--preparar-repo`
  cria `openspec/` (`openspec init --tools none`, sem arquivos de ferramenta) com `schema: sessao`.
- **Sempre:** `docs/sessoes/<slug>/PLAN.md`. Detalhe **só o bloco B1**; os demais em uma linha,
  marcados `(rascunho)`. Preencha o cabeçalho de parâmetros (slug, branch, ambiente, namespaces,
  relatórios) e a seção "🚧 Guardrails deste escopo". O parâmetro **OpenSpec** vem ligado do template:
  não o remova. A declaração do contrato do B1 (`change` ou `não se aplica — <motivo>`) é decidida no
  `handoff`; se o B1 já nasce executor-ready, decida-a aqui.
- Acrescente a linha do escopo na tabela **🎯 Escopos de trabalho** do `AGENTS.md`, com estado
  🟡 Ativo, neste formato — é por ela que o portão acha o PLAN:
  ``| `<slug>` | <descrição> | 🟡 Ativo | [`docs/sessoes/<slug>/PLAN.md`](docs/sessoes/<slug>/PLAN.md) |``

## 5. Grave o baton no "🔎 Agora" do PLAN novo — nunca em branco

Sem baton, o `start` fica adivinhando o papel. B1 🔬 descoberta, ou ainda não executor-ready →
`🧠 Planejador`; B1 🔧 mecânico e já executor-ready → `⚙️ Executor`.

## 6. Commite a instalação — com validação do usuário

PLAN não-commitado faz a próxima sessão ler estado do working tree; mas commit é ato que o usuário
autoriza. A pasta `openspec/` entra no mesmo commit. Na branch default, use a branch de trabalho declarada no PLAN. Reporte o hash e mostre a
árvore criada.

## 7. Feche com os próximos passos

Como no fim de toda sessão ([`../referencia/conferencia.md`](../referencia/conferencia.md), seção
"Próximos passos"): o comando completo da próxima sessão, pelo baton do passo 5. Com o baton em 🧠,
ofereça também seguir, nesta mesma sessão, direto para o handoff do B1.

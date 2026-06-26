---
name: sessao
description: >-
  Monta e opera o sistema de Controle de Sessões (v2) para projetos de escopo definido — fonte única
  de verdade PLAN.md + protocolo planner/executor + rolling-wave. Use quando o usuário quiser
  inicializar o controle de sessões num projeto, criar/montar um PLAN.md (ou AGENTS.md/CLAUDE.md de
  controle), ou rodar o ritual de início, handoff (troca de modelo planejador→executor) ou fim de
  sessão. Gatilhos: "controle de sessões", "montar o PLAN", "bootstrap do playbook de sessões",
  "/sessao", "iniciar/encerrar sessão do projeto".
---

# Skill: sessao — Controle de Sessões (v2)

Sistema para tocar um projeto de escopo definido com agentes de I.A. mantendo cada sessão enxuta de
contexto e zero perda de continuidade. **Princípio único:** cada fato mora em UM arquivo; o resto
aponta (link), nunca copia. O plano se detalha em rolling-wave (perto detalhado, longe em rascunho).

Os templates ficam em `templates/` ao lado deste arquivo. O panorama completo do modelo está em
`templates/README.md` — leia-o se precisar de contexto antes de agir.

## Subcomando (deduza do argumento ou pergunte)

O argumento após `/sessao` indica a operação. Sem argumento, pergunte qual é.

### `init` — instalar o sistema num projeto novo
1. Leia `templates/AGENTS.template.md` e `templates/PLAN.template.md`.
2. Levante os `<PLACEHOLDERS>` com o usuário (não invente): nome do projeto; escopo; lista inicial de
   blocos (id + título + tipo 🔧 mecânico / 🔬 descoberta); como tratá-lo; ambiente/guardrails;
   política de commit; idioma; pasta de relatórios.
3. Crie no projeto: `AGENTS.md` (ou `CLAUDE.md` se já existir) e `PLAN.md` (raiz ou subpasta do
   escopo), preenchidos. Detalhe **só o bloco B1**; deixe os demais em uma linha, marcados `(rascunho)`.
   Copie `templates/template-relatorio.md` para a pasta de relatórios.
4. Confirme o plano da estrutura ANTES de criar; depois mostre a árvore criada.

### `start` — início de sessão
1. Leia só o cabeçalho "🔎 Agora" + o bloco ativo do `PLAN.md` do projeto (não releia relatórios).
2. Diga onde paramos, o bloco ativo e o próximo passo. Identifique o papel da sessão (🧠 Planejador /
   ⚙️ Executor) e confirme o foco.

### `handoff` — preparar a troca de modelo (Planejador → Executor)
1. Verifique se o bloco ativo está **"executor-ready"** (DoD do planejamento): tarefas atômicas com
   checagem verificável; decisões resolvidas; comandos/paths/valores preenchidos; DoR satisfeito;
   escalonamento definido.
2. Ajuste o que faltar no `PLAN.md` e confirme que um executor consegue tocar à risca.

### `end` — fim de sessão (só quando o usuário pedir)
1. Gere `RELATORIO_<bloco>_<AAAA-MM-DD>.md` na pasta de relatórios, pelo template (detalhe denso:
   comandos, saídas, números).
2. Atualize o `PLAN.md` **in-place** (nunca duplique linhas): cabeçalho "Agora"; Board; checkboxes do
   bloco ativo; se o bloco fechou, **promova o próximo de rascunho a detalhado e replaneje o resto**;
   registro de sessões (1 linha + link).
3. Atualize ponteiros de memória só se algo de alto nível mudou.

## Regras invioláveis (valem em qualquer subcomando)

- **Anti-duplicação:** estado/plano → `PLAN.md`; detalhe denso → relatórios; ganchos → memória. Nunca
  suba detalhe de relatório para o PLAN.
- **Rolling-wave:** detalhe só o bloco ativo (+ próximo). Replanejar na fronteira do bloco é ritual.
- **Papéis:** Planejador (modelo forte) deixa o bloco executor-ready e NÃO implementa, especificando
  decisões e restrições — não keystrokes. Executor (modelo barato) executa à risca, e ao divergir do
  plano PARA e escala de volta — não improvisa decisão de design. Auto-verifica contra a DoD.
- **Estimativas são guia de fatiamento, não SLA.** Gere RELATÓRIO só quando o usuário pedir.

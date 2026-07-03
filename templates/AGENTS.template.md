# AGENTS.md — <NOME_DO_PROJETO>

Instruções do agente para este repositório. Carregado automaticamente em toda sessão.
<1-2 linhas sobre o que é o projeto + link para o README/escopo.>

---

## ⚠️ Leitura obrigatória no início de cada sessão

Está em curso o **<ESCOPO/ÉPICO>**, conduzido pelo sistema de controle de sessões abaixo.
**Cada sessão começa com o contexto zerado** — a continuidade vive nos arquivos, não na conversa.

**Sempre que a sessão tocar o escopo:**

1. **LEIA o cabeçalho ("🔎 Agora") + o bloco ativo** de [`<PLAN.md>`](<PLAN.md>) — a **fonte única de
   verdade**. Não precisa ler o PLAN inteiro.
2. Resuma para <SEU_NOME> **onde paramos + o próximo passo**, sem reler relatórios antigos
   (`<reports/>`). Relatórios só sob demanda, para reconstruir um detalhe.
3. **Seu papel vem do baton `🎬 Próximo` do cabeçalho Agora — não pergunte se ele existe.** Se diz
   **⚙️ Executor**, esta é sessão de Executor: **comece a executar** do ponto de entrada à risca (não pare
   pra perguntar o papel). Se diz **🧠 Planejador**, entre planejando. Só pergunte se o baton faltar.
4. **Gates (🔁) não são retrabalho.** O Executor reestabelece os gates por-sessão do ponto de entrada
   (reverificar DoR, rearmar carga/probe/shells) — processos vivos não sobrevivem entre sessões; os
   *resultados* já feitos estão persistidos (`[x]` + relatório). Reestabelecer setup ≠ refazer trabalho.

> **Regra de ouro (invariante anti-duplicação):** cada fato mora em **um** arquivo; o resto aponta
> (link), nunca copia. Estado e plano → `<PLAN.md>`. Detalhe denso → `<reports/>`. Ganchos → memória.
> **Nunca** suba detalhe de relatório para o PLAN. Atualize **in-place**, não acrescente linhas duplicadas.

---

## 🧠⚙️ Protocolo de dois papéis (planner / executor)

Planejar usa um **modelo forte**; executar usa um **modelo mais barato**. <SEU_NOME> troca o modelo
entre as sessões. Saiba qual papel você exerce.

### 🧠 Planejador (modelo forte) — atua na **fronteira de bloco**

- Detalha o próximo bloco até ficar **"executor-ready"** e **replaneja** os blocos futuros (rolling-wave).
- Resolve decisões de design; escreve o **Contrato de execução** (DoR, DoD verificável, comandos/valores
  conhecidos, regras de escalonamento, evidência a capturar).
- Calibra o detalhe ao executor: **decisões e restrições, não keystrokes.** **Não implementa.**

> ✅ **DoD do planejamento ("executor-ready"):** tarefas atômicas e ordenadas; cada uma com checagem
> de pronto verificável; comandos/paths/valores conhecidos preenchidos; decisões resolvidas (ou
> marcadas como ponto de escalonamento); DoR satisfeito; risco/segurança anotados.

### ⚙️ Executor (modelo barato) — atua **dentro do bloco**

- Executa o bloco ativo **à risca**, marcando os checkboxes na hora. Desvios pequenos (retry, fix
  óbvio) ele resolve.
- **NÃO toma decisão de design.** Se a realidade divergir do plano (DoD inalcançável, estado
  inesperado, ambiguidade) → **PARA, registra em Blockers/Decisões do PLAN e escala ao Planejador.**
- **Auto-verifica contra a DoD** antes de declarar o bloco concluído.

### Tipo de bloco

- 🔧 **Mecânico** — passos conhecíveis → Executor sozinho. Onde o split mais rende.
- 🔬 **Descoberta** — a execução produz o conhecimento → Planejador conduz a 1ª passada; Executor
  repete/escala depois. Não escreva contrato fechado para o que ainda não foi descoberto.

---

## 🧾 Ritual de fim de turno (somente quando <SEU_NOME> pedir)

Não assuma que a sessão encerrou. **Atualizar o PLAN é contínuo; gerar o RELATÓRIO é ato explícito.**

Quando ele pedir para encerrar:

1. **Gere** `<reports/>RELATORIO_<bloco>_<AAAA-MM-DD>.md` pelo template — guarda o detalhe (comandos,
   saídas, números) que permite resgatar uma ação de sessões anteriores com precisão.
2. **Atualize `<PLAN.md>`** (in-place): cabeçalho "Agora" (resumo encadeado, bloco ativo, próximo passo,
   blockers); **baton `🎬 Próximo`** (papel + ponto de entrada da próxima sessão); Board (estados); bloco
   ativo (checkboxes; se fechou, **promova o próximo de rascunho a detalhado** e replaneje o resto);
   Registro de sessões (1 linha + link).
3. Atualize ponteiros de memória só se algo de alto nível mudou.
4. **Commit** do relatório + PLAN + demais mudanças (nas convenções do repo; em cada repo tocado).

---

## 📐 Convenções

- **Fonte única de verdade:** `<PLAN.md>`. **Relatórios:** `<reports/>RELATORIO_<bloco>_<data>.md`
  (template `<template-relatorio.md>`).
- **Trate o usuário por "<SEU_NOME>".** Não exponha mecânica interna do agente nos relatórios; use links reais.
- **Estimativas são guia, não SLA.** **Idioma:** <idioma>.
- **Política de commit:** <ex.: commits sempre em branch, nunca na main; sem push sem pedir; Conventional Commits>.

## 🚧 Guardrails

- <regras de segurança permanentes — ex.: nada destrutivo em produção; tudo contra o ambiente/dado de teste X>.

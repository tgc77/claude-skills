# Prompts — Bootstrap e dia a dia

## 1) Prompt de Bootstrap (cole na 1ª sessão, com um modelo forte)

> Substitua os `<PLACEHOLDERS>`.

```
Vamos adotar neste projeto o SISTEMA DE CONTROLE DE SESSÕES (v2) com FONTE ÚNICA DE VERDADE,
rolling-wave e protocolo planner/executor. Objetivo: cada sessão futura carrega lendo só o cabeçalho
"Agora" + o bloco ativo de UM arquivo (PLAN.md), sem reprocessar histórico.

CONTEXTO
- Projeto: <NOME_DO_PROJETO>
- Escopo definido: <ÉPICO/SPRINT/MIGRAÇÃO/POC> — <breve descrição> (slug da pasta: <escopo-slug>)
- Itens/blocos do escopo (id + título + tipo mecânico/descoberta): <liste, ou diga onde estão>
- Me trate por "<SEU_NOME>".
- Branch de trabalho deste escopo: <branch>.
- Ambiente/guardrails DESTE escopo: <ex.: só homolog; KUBECONFIG=...; nada destrutivo>.
- Política de commit (permanente): <ex.: branch nunca na main; sem push sem pedir>.

MONTE A ESTRUTURA (princípio: cada fato mora em UM arquivo; o resto aponta, nunca copia — e o
protocolo é permanente enquanto o plano é POR ESCOPO, porque este repo vai ter outras frentes depois):
1. AGENTS.md na raiz — PROTOCOLO PERMANENTE, agnóstico de escopo: leitura obrigatória (identificar o
   escopo → cabeçalho + bloco ativo do PLAN dele); protocolo de dois papéis (🧠 Planejador modelo forte
   / ⚙️ Executor modelo barato) com a DoD "executor-ready", a regra de escalonamento e a Fronteira de
   papel; ritual de fim de turno; convenções de commit; guardrails PERMANENTES. Nada específico de
   escopo aqui.
2. CLAUDE.md na raiz — índice curto: aponta o AGENTS.md e lista os escopos numa tabela
   (slug | escopo/descrição | estado | link do PLAN). Sem duplicar o protocolo.
3. docs/sessoes/<escopo-slug>/PLAN.md — FONTE ÚNICA daquele escopo: cabeçalho de parâmetros (branch,
   slug, ambiente/variáveis, namespaces); guardrails DO ESCOPO; "🔎 Agora" com o baton
   🎬 Próximo; Board único (bloco | tipo | estim. | estado); bloco ativo DETALHADO com Contrato de
   execução (DoR, DoD verificável, decisões resolvidas, escalonamento, evidência) + checklist; blocos
   futuros em UMA LINHA cada, marcados (rascunho); decisões/gotchas; registro de sessões.
4. docs/sessoes/template-relatorio.md — seções fixas + guia de estilo (conta a história, traduz jargão,
   mantém todos os detalhes técnicos, explica o porquê). Um por repo, reusado por todo escopo.

REGRAS (registre no AGENTS.md e siga sempre):
- Rolling-wave: detalhe só o bloco ativo (+ próximo); o resto é rascunho provisório. Replanejar na
  fronteira de cada bloco é ritual, não desvio.
- Como Planejador: deixe o bloco "executor-ready" (decisões e restrições, NÃO keystrokes) e pare.
- Como Executor: execute à risca, marque checkboxes, e ESCALE de volta se a realidade divergir do
  plano — não improvise decisão de design. Auto-verifique contra a DoD. Ao fechar um bloco inteiro,
  gere o relatório e commite por si; mas NÃO promova nem detalhe o próximo bloco (Fronteira de papel).
- Atualize o PLAN in-place (nunca duplique linhas). Gere RELATÓRIO quando eu pedir ou ao fechar um
  bloco inteiro — nunca por terminar alguns steps no meio do bloco.
- Escopo novo no futuro: só uma pasta nova em docs/sessoes/<slug>/ com PLAN.md + uma linha no índice
  do CLAUDE.md. AGENTS.md e template-relatorio.md são reusados, NUNCA copiados.
- Memória: só ponteiros de alto nível, nunca o que já está no código ou nos relatórios.

Comece confirmando o plano da estrutura e, se eu aprovar, crie os arquivos.
```

---

## 2) Início de sessão (curto)

```
Leia o cabeçalho "Agora" + o bloco ativo do PLAN.md do escopo <escopo-slug> e me diga: onde paramos,
qual o bloco ativo e o próximo passo. Não releia relatórios. Seu papel vem do baton 🎬 Próximo.
```

## 3) Fim de sessão (quando você decidir encerrar)

```
Encerrando a sessão de <DATA>. Gere o relatório pelo template na pasta do escopo e atualize o PLAN.md
in-place (Agora, baton 🎬 Próximo, Board, checkboxes do bloco ativo, registro de sessões). Se o bloco
fechou: como Planejador, promova o próximo de rascunho a detalhado e replaneje o resto; como Executor,
marque 🟢, grave o baton 🧠 Planejador com o motivo e pare.
```

## 4) Handoff Planejador → Executor (ao trocar de modelo)

```
Antes de eu trocar para o modelo executor: o bloco ativo do PLAN.md está "executor-ready"? Cheque a
DoD do planejamento (tarefas atômicas com checagem verificável, decisões resolvidas, comandos/valores
preenchidos, escalonamento definido). Ajuste o que faltar e confirme que um executor consegue tocar à risca.
```

## 5) Resgatar um detalhe específico (raro)

```
Preciso reconstruir <detalhe X>. Procure no relatório <RELATORIO_...> em vez de no PLAN.
```

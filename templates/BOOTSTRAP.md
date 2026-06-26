# Prompts — Bootstrap e dia a dia

## 1) Prompt de Bootstrap (cole na 1ª sessão, com um modelo forte)

> Substitua os `<PLACEHOLDERS>`.

```
Vamos adotar neste projeto o SISTEMA DE CONTROLE DE SESSÕES (v2) com FONTE ÚNICA DE VERDADE,
rolling-wave e protocolo planner/executor. Objetivo: cada sessão futura carrega lendo só o cabeçalho
"Agora" + o bloco ativo de UM arquivo (PLAN.md), sem reprocessar histórico.

CONTEXTO
- Projeto: <NOME_DO_PROJETO>
- Escopo definido: <ÉPICO/SPRINT/MIGRAÇÃO/POC> — <breve descrição>
- Itens/blocos do escopo (id + título + tipo mecânico/descoberta): <liste, ou diga onde estão>
- Me trate por "<SEU_NOME>".
- Ambiente/guardrails: <ex.: rodar só em desenv; nada destrutivo; tudo contra o dado de teste X>.
- Política de commit: <ex.: branch nunca na main; sem push sem pedir>.

MONTE A ESTRUTURA (princípio: cada fato mora em UM arquivo; o resto aponta, nunca copia):
1. AGENTS.md (ou CLAUDE.md) com: leitura obrigatória (cabeçalho + bloco ativo do PLAN); protocolo de
   dois papéis (🧠 Planejador modelo forte / ⚙️ Executor modelo barato) com a DoD "executor-ready" e a
   regra de escalonamento; ritual de fim de turno; convenções; guardrails.
2. PLAN.md como FONTE ÚNICA: cabeçalho "🔎 Agora"; Board único (bloco | tipo | estim. | estado);
   bloco ativo DETALHADO com Contrato de execução (DoR, DoD verificável, decisões resolvidas,
   escalonamento, evidência) + checklist; blocos futuros em UMA LINHA cada, marcados (rascunho);
   decisões/gotchas; registro de sessões (1 linha + link).
3. template-relatorio.md com seções fixas + guia de estilo (conta a história, traduz jargão, mantém
   todos os detalhes técnicos, explica o porquê).

REGRAS (registre no AGENTS.md e siga sempre):
- Rolling-wave: detalhe só o bloco ativo (+ próximo); o resto é rascunho provisório. Replanejar na
  fronteira de cada bloco é ritual, não desvio.
- Como Planejador: deixe o bloco "executor-ready" (decisões e restrições, NÃO keystrokes) e pare.
- Como Executor: execute à risca, marque checkboxes, e ESCALE de volta se a realidade divergir do
  plano — não improvise decisão de design. Auto-verifique contra a DoD.
- Atualize o PLAN in-place (nunca duplique linhas). Gere RELATÓRIO só quando eu pedir.
- Memória: só ponteiros de alto nível, nunca o que já está no código ou nos relatórios.

Comece confirmando o plano da estrutura e, se eu aprovar, crie os arquivos.
```

---

## 2) Início de sessão (curto)

```
Leia o cabeçalho "Agora" + o bloco ativo do PLAN.md e me diga: onde paramos, qual o bloco ativo e o
próximo passo. Não releia relatórios. Seu papel nesta sessão é <Planejador | Executor>. Confirme o foco.
```

## 3) Fim de sessão (quando você decidir encerrar)

```
Encerrando a sessão de <DATA>. Gere o relatório pelo template e atualize o PLAN.md in-place (Agora,
Board, checkboxes do bloco ativo; se o bloco fechou, promova o próximo de rascunho a detalhado e
replaneje o resto; registro de sessões). Próxima sessão: <quando / qual papel>.
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

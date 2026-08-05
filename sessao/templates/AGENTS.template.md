# AGENTS.md — <NOME_DO_PROJETO>

Instruções do agente para este repositório — **como trabalhar**. Este arquivo é **permanente e
agnóstico de escopo**: vale para qualquer feature, correção ou investigação conduzida pelo sistema de
controle de sessões. O **quê** (escopo, board, branch, ambiente, guardrails específicos, label do card)
vive no `PLAN.md` de cada escopo, em `docs/sessoes/<escopo>/PLAN.md`. Escopos ativos e arquivados estão
listados em [`CLAUDE.md`](CLAUDE.md).

<1-2 linhas sobre o que é o projeto + link para o README/documentação técnica.>

> **Um escopo = uma pasta.** `docs/sessoes/<escopo>/` contém o `PLAN.md` daquele escopo e seus
> relatórios. Escopos não se misturam: fechar um não mexe no outro, e um escopo novo não herda o
> estado do anterior — só este protocolo.

---

## ⚠️ Leitura obrigatória no início de cada sessão

**Cada sessão começa com o contexto zerado** — a continuidade vive nos arquivos, não na conversa.

1. **Identifique o escopo** da sessão pela lista em [`CLAUDE.md`](CLAUDE.md). Se mais de um escopo
   estiver ativo e a intenção de <SEU_NOME> for ambígua, **pergunte qual** antes de agir.
2. **LEIA o cabeçalho ("🔎 Agora") + o bloco ativo** do `PLAN.md` **daquele escopo** — a **fonte única
   de verdade** dele. Não precisa ler o PLAN inteiro, e não leia o PLAN de outro escopo.
3. Resuma para <SEU_NOME> **onde paramos + o próximo passo**, sem reler relatórios antigos. Relatórios
   só sob demanda, para reconstruir um detalhe.
4. **Seu papel vem do baton `🎬 Próximo` do cabeçalho Agora — não pergunte se ele existe.** Se diz
   **⚙️ Executor**, esta é sessão de Executor: **comece a executar** do ponto de entrada à risca (não
   pare pra perguntar o papel). Se diz **🧠 Planejador**, entre planejando. Só pergunte se o baton faltar.
5. **Gates (🔁) não são retrabalho.** O Executor reestabelece os gates por-sessão do ponto de entrada
   (reverificar DoR, rearmar carga/probe/shells, exportar variáveis de ambiente) — processos vivos não
   sobrevivem entre sessões; os *resultados* já feitos estão persistidos (`[x]` + relatório).
   Reestabelecer setup ≠ refazer trabalho.
6. **Obedeça aos guardrails do escopo** (seção 🚧 no topo do `PLAN.md`) — são específicos daquela frente
   e **sobrepõem** qualquer hábito geral.

> **Regra de ouro (invariante anti-duplicação):** cada fato mora em **um** arquivo; o resto aponta
> (link), nunca copia. Regras de trabalho → **este arquivo**. Estado e plano → `PLAN.md` do escopo.
> Detalhe denso → relatórios do escopo. Ganchos → memória. **Nunca** suba detalhe de relatório para o
> PLAN. Atualize **in-place**, não acrescente linhas duplicadas.

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
- **Fecha o próprio bloco:** ao satisfazer toda a DoD, dispara o ritual de fim de turno por si
  (relatório + PLAN + commit) — sem esperar pedido — e só então passa o baton.
- **Fronteira de papel = PARADA de sessão:** nunca vira Planejador na mesma sessão. Ao fechar o bloco,
  ou ao topar com algo que exija (re)planejar, grava `🎬 Próximo: 🧠 Planejador` junto do motivo e para.
  **Não** promove o próximo bloco de rascunho a detalhado, **não** escreve contrato novo.

### Tipo de bloco

- 🔧 **Mecânico** — passos conhecíveis → Executor sozinho. Onde o split mais rende.
- 🔬 **Descoberta** — a execução produz o conhecimento → Planejador conduz a 1ª passada; Executor
  repete/escala depois. Não escreva contrato fechado para o que ainda não foi descoberto.

---

## 🧾 Ritual de fim de turno

**Atualizar o PLAN é contínuo; gerar o RELATÓRIO é ato explícito** — quando <SEU_NOME> pedir **ou**
quando um **bloco inteiro fecha** (aí o Executor dispara sozinho, ver acima). Terminar alguns steps no
meio de um bloco não gera relatório.

1. **Gere** `docs/sessoes/<escopo>/RELATORIO_<bloco>_<AAAA-MM-DD>.md` pelo template
   [`docs/sessoes/template-relatorio.md`](docs/sessoes/template-relatorio.md) — guarda o detalhe
   (comandos, saídas, números) que permite resgatar uma ação de sessões anteriores com precisão.
2. **Atualize o `PLAN.md` do escopo** (in-place): cabeçalho "Agora"; **baton `🎬 Próximo`** (papel +
   ponto de entrada da próxima sessão); Board; checkboxes do bloco ativo; Registro de sessões (1 linha
   + link). Se o bloco fechou: **Planejador** promove o próximo de rascunho a detalhado e replaneja o
   resto; **Executor** só marca 🟢, grava o baton `🧠 Planejador` com o motivo e para.
3. Se o **escopo inteiro** fechou, marque-o 🟢 na tabela de escopos do [`CLAUDE.md`](CLAUDE.md) — a pasta
   fica como histórico. Atualize ponteiros de memória só se algo de alto nível mudou.
4. **Registre o apontamento do dia no `resumo-trabalho`**, se o escopo declarar um **label de
   apontamento** no cabeçalho do seu `PLAN.md`: para cada `RELATORIO_*_<hoje>.md` ainda não registrado
   (idempotência pelo basename no log do label), sintetize uma entrada `registrar` a partir do relatório
   e faça append em `~/.claude/work-log/<label>.md` com a linha `**Relatório-fonte:**`. Log
   global/append-only — não entra no commit. Escopo sem label → pule este passo.
5. **Commit** do relatório + PLAN + demais mudanças, em **cada** repo tocado, na branch de trabalho
   declarada no PLAN do escopo.

---

## 📐 Convenções

- **Trate o usuário por "<SEU_NOME>".** Não exponha mecânica interna do agente nos relatórios; use
  links reais.
- **Estimativas são guia, não SLA.** **Idioma:** <idioma>.
- **Escopos:** um escopo = uma pasta `docs/sessoes/<slug>/`. Escopo novo = `/sessao init` cria só o
  `PLAN.md` na pasta nova e soma uma linha no índice; este protocolo e o template de relatório são
  **reusados, nunca copiados**. Escopo concluído vira 🟢 em [`CLAUDE.md`](CLAUDE.md) — a pasta fica.
- **Política de commit:** <ex.: Conventional Commits; nunca na main, sempre na branch de trabalho do
  escopo; sem push sem pedir — exceto commit destinado a deploy, que leva push + bump de versão no
  mesmo turno>.
- **Repos irmãos** (uma sessão pode tocar mais de um; commite em cada, e diga em qual está mexendo):
  - <`../repo-irmao` — para que serve>.

## 🚧 Guardrails permanentes (independem de escopo)

- <regras de segurança que valem sempre — ex.: segredos referenciados por chave, nunca por valor;
  produção não é laboratório; config entra pelo git, não por edição viva; ações destrutivas exigem
  ordem explícita>.

> Guardrails **específicos** de uma frente de trabalho (ambiente, cluster, `KUBECONFIG`, dados de
> teste) **não** entram aqui — vão na seção 🚧 do `PLAN.md` daquele escopo, senão o próximo escopo
> herda restrição que não é dele.

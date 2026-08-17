# AGENTS.md — <NOME_DO_PROJETO>

Instruções do agente para este repositório — **como trabalhar**. Este arquivo é **permanente e
agnóstico de escopo**: vale para qualquer feature, correção ou investigação conduzida pelo sistema de
controle de sessões. O **quê** (slug, descrição, board, branch, ambiente, guardrails específicos)
vive no `PLAN.md` de cada escopo, em `docs/sessoes/<escopo>/PLAN.md`. Escopos ativos e arquivados estão
listados em [`CLAUDE.md`](CLAUDE.md).

<1-2 linhas sobre o que é o projeto + link para o README/documentação técnica.>

> **Um escopo = uma pasta.** `docs/sessoes/<escopo>/` contém o `PLAN.md` daquele escopo e seus
> relatórios. Escopos não se misturam: fechar um não mexe no outro, e um escopo novo não herda o
> estado do anterior — só este protocolo.

---

## ⚠️ Leitura obrigatória no início de cada sessão

**Cada sessão começa com o contexto zerado** — a continuidade vive nos arquivos, não na conversa.

1. **Identifique o escopo** da sessão e **diga qual assumiu**, nesta ordem: slug passado no comando →
   único 🟡 ativo na lista de [`CLAUDE.md`](CLAUDE.md) → escopo cuja "Branch de trabalho" é a branch
   atual → **pergunte** a <SEU_NOME>. Nunca chute, e **nunca opere dois escopos na mesma sessão**.
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

- **Todo critério de aceite é MEDIDO no estado atual antes de virar alvo — nenhum é deduzido.** Rode o
  comando do critério **no commit do handoff** e escreva o valor observado ao lado do alvo. Se o
  baseline já reprova o critério, há duas saídas honestas: **mudar o alvo**, ou tornar a correção
  **tarefa explícita do bloco**. Alvo escrito por raciocínio ("o código novo será vetorizado, logo o
  grep dará 0") **nasce falso**: é inatingível dentro do contrato, e quem paga é o Executor, que trava
  numa medição que nunca poderia bater. Vale para grep, contagem de teste, diff, tempo — qualquer
  medida. E **grep de código mede a chamada** (`\.foo(`), não a palavra solta: senão comentário correto
  reprova código correto.

> ✅ **DoD do planejamento ("executor-ready"):** tarefas atômicas e ordenadas; cada uma com checagem
> de pronto verificável; comandos/paths/valores conhecidos preenchidos **e medidos**; decisões
> resolvidas (ou marcadas como ponto de escalonamento); DoR satisfeito; risco/segurança anotados.

### ⚙️ Executor (modelo barato) — atua **dentro do bloco**

- Executa o bloco ativo **à risca**, marcando os checkboxes na hora. Desvios pequenos (retry, fix
  óbvio) ele resolve.
- **NÃO toma decisão de design.** Se a realidade divergir do plano (DoD inalcançável, estado
  inesperado, ambiguidade) → **PARA, registra em Blockers/Decisões do PLAN e escala ao Planejador.**
- **Auto-verifica contra a DoD** antes de declarar o bloco concluído.
- **Critério de aceite que não bateu = PARADA — mesmo que a intenção pareça cumprida.** Se qualquer
  critério mede diferente do alvo, o bloco **não fecha 🟢**: registre o que mediu (comando + saída
  crua), grave o baton `🧠 Planejador` com o motivo e **pare**. Nunca ajuste o alvo, e **nunca releia o
  critério pela intenção que você enxerga nele** ("o alvo era 0 para garantir código vetorizado, e o
  meu é vetorizado, então vale") — julgar se um critério errado ainda serve é do 🧠. **Registrar o
  achado com transparência não substitui a parada.**
- **Fecha o próprio bloco:** ao satisfazer toda a DoD, dispara o ritual de fim de turno por si
  (relatório + PLAN + commit) — sem esperar pedido — e só então passa o baton.
- **O baton é a linha `🎬 Próximo:` do cabeçalho 🔎 Agora — não é a prosa em volta dela.** Escrever
  "baton → 🧠 Planejador" no resumo da sessão, no relatório ou na mensagem de commit e **deixar a linha
  `🎬` com o papel e o ponto de entrada antigos** entrega à sessão seguinte um bloco já fechado como se
  fosse tarefa aberta — ela entra como Executor e refaz o que já está feito. Atualize **aquela linha**,
  in-place, antes do commit de fechamento; o resto do cabeçalho é resumo, ela é a fonte de verdade.
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
4. **Registre o apontamento do dia no `resumo-trabalho`** — o label **é o slug** do escopo: para cada
   `RELATORIO_*_<hoje>.md` ainda não registrado (idempotência pelo basename no log), sintetize uma
   entrada `registrar` a partir do relatório e faça append em `~/.claude/work-log/<slug>.md` com a
   linha `**Relatório-fonte:**`. Log global/append-only — não entra no commit.
5. **✅ Conferência de saída — antes do commit, sempre.** Mecânica, não subjetiva; qualquer item
   vermelho é **PARADA**, nunca "ressalva no relatório":
   ① todo critério de aceite **medido** (comando + saída) e batendo — um só que não bata impede o 🟢;
   ② a **linha** `🎬 Próximo` diz o papel e o ponto de entrada certos **para depois desta sessão**, e
   não contradiz o Board (bloco 🟢 ou tarefa `[x]` citada como ponto de entrada = baton podre);
   ③ cabeçalho, Board, registro de sessões e mensagem de commit **batem com a linha `🎬`** — ela vence;
   ④ todo bloco 🟢 tem todas as tarefas `[x]`;
   ⑤ o identificador da linha nova do registro de sessões vem do **último valor da própria tabela + 1**,
   não do número do relatório (série própria, quase nunca coincide);
   ⑥ tudo escrito **in-place**, sem 2ª cópia de campo que já existia;
   ⑦ `git status` sem arquivos alheios ao escopo/sessão.
6. **Commit** do relatório + PLAN + demais mudanças, em **cada** repo tocado, na branch de trabalho
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

- **🛑 QUESTIONAMENTO ABERTO = REGISTRO CONGELADO (inviolável, não editar/remover).** Quando o usuário
  questiona, discorda ou pede para validar algo, **para de escrever imediatamente**: nada entra em
  `PLAN.md`, `AGENTS.md`, relatório, memória ou commit até ele **concordar com tudo** — não com a parte
  que pareceu resolvida. Concordar com um ponto não libera os outros; silêncio não é aval.
  **Por quê:** registrar é o que transforma hipótese em verdade oficial do projeto; o PLAN é lido por
  sessões futuras como fato estabelecido. Enquanto há questionamento aberto, a análise **ainda não é**
  conclusão: é proposta.
  **No lugar:** apresentar a **evidência crua** (diff, saída de comando, trecho de arquivo) + a
  conclusão + as opções, e **perguntar**. Mudanças ficam no working tree, sem commit.
  **Não vale como desculpa:** "era só documentar", "é reversível", "o ritual de `end` manda commitar" —
  o ritual não sobrepõe esta regra. **Se já registrou antes do aval:** dizer na primeira frase, oferecer
  o `git reset --soft` e esperar.
  **Exceção única:** trabalho mecânico já contratado num bloco executor-ready (marcar checkbox, gerar
  relatório de bloco fechado). Conclusão nova, reenquadramento de causa raiz, mudança de contrato,
  criação/cancelamento de bloco e reordenação de Board **nunca** são mecânicos.
- <regras de segurança que valem sempre — ex.: segredos referenciados por chave, nunca por valor;
  produção não é laboratório; config entra pelo git, não por edição viva; ações destrutivas exigem
  ordem explícita>.

> Guardrails **específicos** de uma frente de trabalho (ambiente, cluster, `KUBECONFIG`, dados de
> teste) **não** entram aqui — vão na seção 🚧 do `PLAN.md` daquele escopo, senão o próximo escopo
> herda restrição que não é dele.

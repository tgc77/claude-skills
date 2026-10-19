# AGENTS.md — <NOME_DO_PROJETO>

<1-2 linhas sobre o que é o projeto + link para o README/documentação técnica.>

<!-- sessao:inicio — bloco gerenciado pela skill `sessao`. Não edite à mão: para atualizar, rode `/sessao update`. -->
## 🧭 Controle de Sessões

Este repositório usa a skill `sessao`. **O protocolo — papéis, ritual de fim de sessão, portão — mora
na skill, não neste arquivo**, e só vale quando o usuário a invoca.

- **Ativação só explícita:** `/sessao start <slug>` no Claude Code; `$sessao start <slug>` ou
  `@sessao start <slug>` no Codex. Os demais subcomandos (`escopos`, `init`, `handoff`, `end`,
  `update`, `help`) fazem só o que pedem e não equivalem a um `start`.
- **Fora disso, todo pedido é avulso:** não leia `docs/sessoes/**` por conta própria, não deduza escopo
  pela branch nem pela tabela de escopos e não rode ritual de sessão.
- A tabela **🎯 Escopos de trabalho** abaixo é só um índice: diz onde mora o PLAN de cada slug.
- **🛑 Questionamento aberto = registro congelado — vale em qualquer sessão, com ou sem a skill.**
  Quando o usuário questiona, discorda ou pede para validar algo, pare de registrar: nada entra em
  PLAN, `AGENTS.md`, relatório, memória ou commit até ele concordar com tudo, não só com a parte que
  pareceu resolvida. Silêncio não é aval, e responder às perguntas do agente não é aceitar um plano.
  Mostre a evidência crua, a conclusão e as opções, e pergunte. Se já registrou antes do aval, diga
  isso na primeira frase e ofereça desfazer.
- **🗣️ Identificador sozinho não é contexto — vale em qualquer sessão, com ou sem a skill.** Ao levar
  uma pergunta ou decisão ao usuário, escreva ao lado de cada rótulo interno (`T3`, `B2`, `D7`, nome de
  arquivo, flag, evento) o que ele é, em uma linha, e o que muda em cada opção. O rótulo é controle do
  PLAN, não memória de quem decide, e decisão tomada sem entender a pergunta é pior que decisão adiada.
<!-- sessao:fim -->

## 🎯 Escopos de trabalho

| Slug     | Escopo (o que é)            | Estado   | PLAN                                                         |
|----------|-----------------------------|----------|--------------------------------------------------------------|
| `<slug>` | <descrição curta da frente> | 🟡 Ativo | [`docs/sessoes/<slug>/PLAN.md`](docs/sessoes/<slug>/PLAN.md) |

**Legenda:** 🟡 Ativo · 🟢 Concluído · 🔴 Bloqueado/pausado. Escopo concluído continua na tabela; a
pasta dele fica como histórico.

## 📐 Convenções

- **Trate o usuário por "<SEU_NOME>".** **Idioma:** <idioma>.
- **Política de commit:** <ex.: Conventional Commits; nunca na main, sempre na branch de trabalho do
  escopo>. Commit e push exigem validação explícita do usuário — sem exceção, nem para deploy.
- **Repos irmãos** (uma sessão pode tocar mais de um; commite em cada um e diga em qual está mexendo):
  - <`../repo-irmao` — para que serve>.

## 🚧 Guardrails permanentes (independem de escopo)

- <regras de segurança que valem sempre — ex.: segredos referenciados por chave, nunca por valor;
  produção não é laboratório; config entra pelo git, não por edição viva; ações destrutivas exigem
  ordem explícita>.

> Guardrails de uma frente de trabalho (ambiente, cluster, `KUBECONFIG`, dados de teste) vão na seção
> 🚧 do `PLAN.md` daquele escopo, não aqui — senão o próximo escopo herda restrição que não é dele.

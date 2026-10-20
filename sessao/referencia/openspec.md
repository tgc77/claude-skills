# Módulo OpenSpec — specs vivas por bloco

O `PLAN.md` guarda a **execução** do escopo: tarefas, baton, registro de sessões. O que o sistema
**faz** — o comportamento de que alguém depende — não tinha registro vivo: ficava espalhado em
relatórios, em documentos de interface e no código. O módulo usa o [OpenSpec](https://github.com/Fission-AI/OpenSpec)
para isso: `openspec/specs/` é a fonte única do comportamento, e cada bloco que o muda traz uma
**change** (proposta + delta das specs) que, quando o bloco conclui, é arquivada e fundida nas specs.

A skill usa o OpenSpec como ferramenta, sob o protocolo dela. Quem fala com o OpenSpec é a skill, pelo
CLI: nada de `/opsx:*` nem de skills do OpenSpec nos repositórios (`openspec init --tools none`), e
nada de `tasks.md` nem de fase `apply` — as tarefas moram no PLAN, para que exista uma lista só. O
OpenSpec nunca mexe no git; commit e push seguem as regras de sempre.

## Onde vale

- **Todo escopo que o `init` cria a partir da 3.1.0.** O PLAN nasce com o parâmetro
  `| **OpenSpec** | ativo … |` no cabeçalho, e é ele que liga o item ⑦ do portão.
- **Qualquer tipo de repositório.** O critério é o bloco, não o repositório: chart, imagem e cluster
  também têm contratos de que outros dependem (os `values` do chart e os recursos que ele gera, a versão
  e os providers da imagem, a política de backup do cluster).
- **Escopo anterior à 3.1.0 não tem o módulo** e o portão não cobra nada dele. Para aderir: acrescente
  o parâmetro ao cabeçalho do PLAN, rode `<skill>/scripts/openspec_ambiente.sh --preparar-repo` e
  declare o OpenSpec no contrato do bloco ativo.

## A decisão do bloco — no handoff

O Planejador declara no contrato do bloco, numa linha só, uma das duas formas:

```text
- **OpenSpec:** change `<id>`
- **OpenSpec:** não se aplica — <motivo>
```

- **change** — o bloco muda um comportamento de que alguém depende: quem chama, quem opera ou quem lê
  o resultado notaria a diferença;
- **não se aplica** — não muda: deploy do que já está especificado, medição, investigação, refatoração
  sem efeito observável, documentação.

Na dúvida, pergunte-se: *se isto quebrar depois, alguém vai reclamar de um comportamento?* Se sim, é
change. "Não se aplica" sem motivo, ou change com `skip_specs: true`, o portão reprova: são formas de
esconder a decisão, e o ⑦ existe para que ela nunca suma em silêncio.

| Bloco | Declaração |
|---|---|
| Bloquear a conta depois de cinco senhas erradas | change `bloqueio-login` |
| Novo value `workers.replicas` no chart | change `replicas-de-workers` |
| Deploy em produção da versão já validada | não se aplica — deploy; o comportamento é o da change `bloqueio-login`, já arquivada |
| Medir a latência do serviço sob carga | não se aplica — bloco de medição, não muda comportamento |

## Os comandos, papel a papel

**Planejador, no `handoff`:**
1. `openspec list --specs` — o que já está especificado. Reuse o nome exato de uma capacidade que já
   existe, em vez de criar outra parecida.
2. `openspec new change <id> --schema sessao` — o id em kebab-case, com verbo ou resultado
   (`bloqueio-login`).
3. Escreva `openspec/changes/<id>/proposal.md` e um `specs/<capacidade>/spec.md` por capacidade (formato
   abaixo; `openspec instructions proposal --change <id>` mostra o modelo do schema).
4. `openspec validate <id> --type change --strict` — resolva toda pendência, **menos** o aviso "should contain SHALL
   or MUST", que é o único que o portão ignora.
5. Mostre a proposta e o delta ao usuário **junto com o contrato**: o aceite cobre os dois.

**Executor:** o delta é parte do contrato. Entregue o comportamento descrito, cenário por cenário. Se o
comportamento precisar ser diferente do delta, é escalonamento: PARE e devolva ao Planejador — o
Executor não reescreve o delta sozinho, como não reescreve o contrato.

**Quem conclui o bloco** (o `end` que marca a última tarefa):
1. `openspec validate <id> --type change --strict`, de novo;
2. `openspec archive <id> -y` — funde o delta em `openspec/specs/` e move a change para
   `openspec/changes/archive/<data>-<id>/`;
3. confira a spec viva resultante e commite `openspec/` junto com o PLAN.

Nunca `--no-validate` nem `--skip-specs`: o primeiro funde delta quebrado, o segundo arquiva sem
fundir.

## O formato

O OpenSpec lê os títulos e as palavras-chave **em inglês**; o texto é **em português**.

- **Proposta:** `## Why` (o problema, e de onde vem: escopo e bloco), `## What Changes`,
  `## Capabilities` (`### New Capabilities` e `### Modified Capabilities`) e `## Impact`.
- **Delta:** `## ADDED Requirements` para requisito novo; `## MODIFIED Requirements` copia o requisito
  inteiro da spec viva, com todos os cenários, e o edita; `## REMOVED Requirements` leva **Reason** e
  **Migration**.
- **Requisito:** `### Requirement: <nome>` e o texto com **DEVE** ou **NÃO DEVE** — um comportamento
  por requisito, em até 500 caracteres. O OpenSpec só reconhece SHALL/MUST e avisa sobre texto em
  português; o aviso é esperado e o portão o ignora.
- **Cenário:** ao menos um por requisito, `#### Scenario: <nome>` (quatro `#`) com `- **WHEN** …` e
  `- **THEN** …`. Cada cenário é um teste em potencial.
- **Capacidade nova** começa com `## Purpose`: uma ou duas frases, com 50 caracteres ou mais.

## O que o portão confere (item ⑦)

| Situação no fechamento | ⑦ |
|---|---|
| PLAN sem o parâmetro **OpenSpec** (escopo anterior) | não aparece |
| Contrato sem declaração, baton com o 🧠 | ⚠️ aviso: é cobrada quando o baton passar ao ⚙️ |
| Contrato sem declaração, baton com o ⚙️ ou bloco concluído | 🔴 |
| `não se aplica` sem motivo, ou declaração fora do formato | 🔴 |
| `não se aplica — <motivo>` | ✅ |
| change que não existe, ou com `skip_specs: true` | 🔴 |
| change aberta que não passa no `validate --strict` (fora o aviso de SHALL/MUST) | 🔴, com as pendências |
| change aberta e válida, bloco em andamento | ✅ |
| change aberta e bloco concluído | 🔴: arquive antes do commit |
| change arquivada | ✅ |
| change declarada sem o CLI ou o `node` para validá-la | 🔴: o portão falha fechado |

O `--estado` traz o mesmo dado no campo `openspec` (módulo, declaração, change, situação, motivo), para
o `start` mostrar ao Executor o delta que ele vai entregar.

## Ambiente — uma vez por máquina

Requisitos: Node ≥ 20.19 e o CLI `openspec` ≥ 1.14.3 (a versão contra a qual o portão e o autoteste
foram escritos).

```bash
# Prefixo do usuário: o npm global do sistema costuma exigir sudo. --ignore-scripts: nada roda na instalação.
npm install -g --prefix ~/.local --ignore-scripts @fission-ai/openspec@1.14.3
# Assinaturas e proveniência, numa instalação de conferência (o `npm audit signatures` não aceita -g):
(cd "$(mktemp -d)" && npm init -y >/dev/null && npm install --ignore-scripts @fission-ai/openspec@1.14.3 >/dev/null && npm audit signatures)
# Telemetria desligada já no primeiro uso; depois, o schema ligado à skill:
OPENSPEC_TELEMETRY=0 openspec config set telemetry.enabled false
<skill>/scripts/openspec_ambiente.sh --aplicar
```

- **Quem roda estes comandos é o agente.** O `init` e o `update` conferem o ambiente e, faltando o CLI,
  mostram os comandos acima e oferecem rodá-los; com o ok do usuário, o agente os roda na ordem.
- **`openspec_ambiente.sh --verificar`** confere tudo: CLI e versão mínima, `node`, telemetria
  desligada, o schema `sessao` ligado à skill e, no repositório atual, o `config.yaml` e a ausência de
  cópia local do schema. O `update` o roda.
- **O schema mora na skill** (`openspec-schema/`) e chega ao OpenSpec por um symlink em
  `~/.local/share/openspec/schemas/sessao`. Cópia em cada projeto envelheceria; uma cópia local em
  `openspec/schemas/` do projeto **sobrepõe** a da skill e é acusada.
- **A telemetria fica sempre desligada.** Ela não traz função nenhuma para quem usa (manda, a cada
  comando, o nome do comando, a versão e um identificador fixo), faz uma chamada de rede por comando — o
  que a política de algumas empresas proíbe — e, na mesma chave, desliga o aviso de versão nova. Isso é
  desejável aqui: o portão depende do formato da resposta do CLI, então atualizar é decisão deliberada.
  As chamadas que a skill faz forçam `OPENSPEC_TELEMETRY=0` de qualquer forma.
- **Para atualizar o CLI:** prefira uma versão publicada há pelo menos duas semanas, confira as
  assinaturas como acima, leia o CHANGELOG do OpenSpec e rode o autoteste do portão — o caso 51 usa o
  OpenSpec real e pega mudança no formato da resposta. Só então suba `OPENSPEC_MINIMO` no
  `openspec_ambiente.sh`.

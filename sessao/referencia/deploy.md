# Entrega destinada a deploy

> Lido por `end` e `handoff` quando o commit existe para ser deployado.

**O `push` pede validação, sempre.** Quando o commit existe para ser deployado, deixá-lo só local é
entrega incompleta: quem builda (Jenkins/CI) lê do **remoto**, então um commit não-pushado vira um
deploy que "não mudou nada", sem erro nenhum — o modo de falha mais caro e mais confuso, porque parece
problema de deploy e é falha de autoria. Por isso, ao commitar para deploy, **peça a validação do push
no mesmo turno** e explique que sem ele o deploy roda e não muda nada. **Avise, e espere:** `push`
publica para fora e não se desfaz sem estrago.

**E o push não é o último elo.** Antes de anunciar "versão X pronta para deployar", confira a cadeia
inteira — qualquer elo faltando produz o mesmo sintoma silencioso (deploy roda, nada muda):

1. **Versão bumpada** onde o projeto exige (ex.: `Chart.yaml` **e** `VERSION` juntos) — sem bump, o
   deploy não rola release nova.
2. **Commit + push** — o CI builda do remoto, não do working tree.
3. **Job de build/publicação** rodado depois do push — é ele que empacota e publica o artefato
   (`.tgz`, imagem). Pular este elo faz o job de deploy reusar o artefato anterior, que continua lá.
4. **Job de deploy selecionando a versão nova** — se o deploy escolhe versão de uma lista, escolher a
   antiga é no-op.

Ao delegar a um humano, **peça os jobs explicitamente e por nome** ("rode o build e depois o deploy
selecionando a versão X"); dizer só "deploya a versão X" já custou ciclos.

**Diagnóstico barato (5 s) quando o deploy "não pegou":** leia o estado **vivo** do objeto (ex.:
`kubectl get deploy <x> -o jsonpath='{.spec.template.spec.containers[0].args}'`) e a idade do pod. Se
os args são os antigos e o pod não foi recriado, o artefato nunca mudou, e a pergunta é **qual elo
faltou**, não "o deploy falhou". Não presuma qual foi: verifique (o remoto tem o commit? o artefato
novo existe?) antes de apontar a causa.

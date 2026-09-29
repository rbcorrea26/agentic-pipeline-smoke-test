## O que muda

<!-- resumo objetivo da mudança -->

Issue: <!-- #numero -->

## Decisão registrada

<!-- Obrigatório quando a mudança tomou decisão durável. Aponte o arquivo e a seção
(doc, ADR do projeto ou regra em .cline/rules/). Se não houve decisão durável,
escreva "nenhuma". -->

## Gates executados

<!-- Cole os comandos e o resultado observado (verde/vermelho). Não cole números
transitórios como prova: a evidência oficial é o CI. -->

```
scripts/agent/preflight.sh --gates
```

## Riscos e limitações

<!-- o que pode quebrar, o que ficou de fora, o que precisa de acompanhamento -->

## Checklist

- [ ] branch dedicada (não a branch padrão)
- [ ] apenas o escopo da issue foi alterado
- [ ] testes ajustados/criados para o comportamento novo
- [ ] `scripts/agent/preflight.sh --gates` verde
- [ ] nenhum segredo, token ou chave adicionado
- [ ] decisão durável registrada (ou "nenhuma")
- [ ] PR aberto como **Draft** (o merge é decisão humana)

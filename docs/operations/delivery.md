# Publicação do item de trabalho (gates → Draft PR → CI → handoff)

Como o item de trabalho sai do workspace e chega ao humano. O comportamento vem do
bloco `delivery` de [`WORKFLOW.md`](../../WORKFLOW.md); o Symphony é quem executa —
este projeto **não** publica por conta própria.

## Sequência

```text
turns do agente no workspace
  -> gates do projeto (`delivery.gates`)           # exit != 0 = execução falhou
  -> branch `pipeline/<identificador>` + commit
  -> push para `origin`                            # nunca para a branch padrão
  -> Draft PR (base = `delivery.base_branch`)
  -> CI do repositório (GitHub Actions)
  -> candidate stable                              # SHA com gates + CI verdes
  -> review one-shot (quando disponível)
  -> ready-for-human                               # merge é decisão humana
```

## Regras

| Regra | Efeito |
|---|---|
| gates com exit != 0 | nada é publicado (sem branch, sem PR): o item volta ao ciclo de trabalho |
| gates válidos | a branch e o Draft PR são criados **pelo Symphony**, a partir do workspace |
| CI obrigatório | sem check run concluído com sucesso não existe `candidate stable` — CI pendente, ausente ou vermelho bloqueia a promoção |
| push novo durante a observação | invalida o candidato; a observação recomeça no novo SHA (nunca promove um SHA que não é mais o topo) |
| `ready-for-human` | aplica o rótulo de handoff, remove o rótulo de entrada e comenta o candidato na issue |
| nova tentativa | reconciliação: se o Draft PR já existe, ele é reaproveitado (sem segunda branch, segunda PR, segundo comentário ou novo trabalho pago) |
| review | uma por candidato; indisponibilidade é registrada como tal e **não** bloqueia o handoff |
| merge | nunca automático |

## O que o projeto precisa garantir

1. `scripts/agent/gates.sh` determinístico (mesma entrada → mesmo resultado) e igual
   ao que o CI roda;
2. CI presente em `.github/workflows/` rodando os gates;
3. `PROJECT_REPO`/`origin` corretos em `scripts/agent/project.env` — o pipeline
   publica **no repositório do projeto**, nunca em outro;
4. nenhum segredo versionado: o token do tracker vem do ambiente do Symphony
   (`$GITHUB_TOKEN`) e nunca é impresso, commitado ou colocado em `argv`.

## Evidência

O resultado de cada rodada (SHA do candidato, número da PR, conclusão do CI) é
**transitório**: vive no GitHub (PR, checks, comentário de handoff) e não é copiado
para a documentação.

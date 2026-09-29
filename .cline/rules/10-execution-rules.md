# Regras de execução

## Antes de começar

- `scripts/agent/preflight.sh` deve passar (ele confirma identidade do repositório,
  ausência de placeholders de template, contrato presente e state do Git).
- Confirme a branch: `git rev-parse --abbrev-ref HEAD` — nunca trabalhe em
  `main`.

## Durante

- Menor mudança coerente com a issue; siga os padrões já existentes no projeto.
- Comportamento novo ⇒ teste novo/ajustado no mesmo PR.
- Não altere arquivo fora do escopo da issue; não refatore "de passagem".
- Não desative nem contorne gate, teste ou verificação de CI.

## Gates e evidência

- `scripts/agent/gates.sh` é a definição oficial de "passou" e roda localmente o
  mesmo conjunto do CI (`preflight.sh --gates` executa).
- Falha em gate: corrija a causa. Se o gate for instável (flaky) ou estiver errado,
  isso é defeito do projeto e deve ser tratado em issue própria — nunca mascarado.
- Não copie número transitório (cobertura, duração, SHA) para documentação.

## PR e handoff

- Quando o pipeline publica (`delivery.enabled` em `WORKFLOW.md`), **você não cria
  branch, commit nem PR**: deixe as mudanças no worktree, rode os gates e pare. O
  Symphony publica a branch `pipeline/<identificador>`, abre o Draft PR, espera o
  CI e só então marca `ready-for-human`.
- Sem o pipeline publicando, o PR é seu: Draft PR com o template do projeto (o que
  muda, decisão registrada, gates executados, riscos, o que não foi feito).
- Sem merge automático: `ready-for-human` exige gates e CI verdes e a revisão
  limitada definida no handoff de `WORKFLOW.md`.
- Bloqueio (falta de acesso, requisito ambíguo): registre na issue e pare — não
  invente credencial nem requisito.

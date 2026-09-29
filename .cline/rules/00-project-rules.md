# Regras do projeto (carregadas pelo agente)

Projeto: `agentic-pipeline-smoke-test` — repositório `rbcorrea26/agentic-pipeline-smoke-test`.

## Fonte da verdade

- Vale o que está **versionado** neste repositório: `AGENTS.md`, `WORKFLOW.md`,
  este diretório, `docs/development/`, `docs/operations/` e o código.
- Chat, memória de agente e prompt anterior **não** são estado autoritativo.
- Decisão durável descoberta durante o trabalho é registrada **no mesmo PR**.
- Métricas transitórias (cobertura, duração, SHA) não são copiadas para
  documentação: a evidência é o CI e o PR.

## Git

- Confirme identidade antes de mudar: `git remote -v`, `git branch --show-current`,
  `git rev-parse HEAD`, `git status --short`.
- Trabalhe em branch dedicada; nunca em `main`.
- Não altere repositórios que não sejam `rbcorrea26/agentic-pipeline-smoke-test`.
- Revise o diff completo (`git diff --stat`, `git diff`) antes de commitar.

## Segredos

- Nunca escreva token, chave ou senha em arquivo, commit, issue, PR ou log.
- Use referência por variável de ambiente (`$GITHUB_TOKEN`, chaves do provedor de
  modelo) e o gerenciador de segredos do projeto.

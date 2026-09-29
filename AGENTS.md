# AGENTS.md — contrato de agentes deste projeto

Projeto: `agentic-pipeline-smoke-test` (`rbcorrea26/agentic-pipeline-smoke-test`), branch padrão
`main`. Este arquivo descreve **como agentes trabalham
aqui**; o contrato de execução (tracker, workspace, prompt, gates) está em
[`WORKFLOW.md`](WORKFLOW.md).

## 1. Antes de editar

1. Leia, nesta ordem: este arquivo → [`WORKFLOW.md`](WORKFLOW.md) →
   [`.cline/rules/`](.cline/rules/) → `docs/development/` → `docs/operations/`.
2. Verifique o estado real do Git antes de mudar qualquer coisa:

   ```bash
   git remote -v; git branch --show-current; git rev-parse HEAD; git status --short
   ```

3. Rode o preflight — ele confirma identidade do repositório, placeholders,
   arquivos de contrato e worktree:

   ```bash
   scripts/agent/preflight.sh
   ```

4. Não use chat, memória de agente ou prompt anterior como estado autoritativo do
   projeto. Se o projeto tiver documentação canônica própria (ADR, decisões),
   ela vence a memória da conversa.

## 2. Durante o trabalho

- Trabalhe em branch dedicada; **nunca** direto em
  `main`. Exceção: quando o pipeline publica
  (`delivery.enabled` em `WORKFLOW.md`), o workspace é descartável e a publicação é
  do Symphony — nesse caso **não** crie branch, commit nem PR; deixe as mudanças no
  worktree.
- Decisão durável descoberta durante o trabalho entra **no mesmo PR** (doc, ADR do
  projeto ou regra em `.cline/rules/`).
- Não duplique métricas/resultados transitórios (cobertura, duração, SHA) em
  documentação versionada: a evidência é o CI e o PR.
- Não registre segredos, tokens ou chaves em arquivo, commit, issue ou PR; use
  `$VAR` e o gerenciador de segredos do projeto.
- Mudança de comportamento exige teste e gate correspondente em
  `scripts/agent/gates.sh`.
- Não altere repositórios que não sejam `rbcorrea26/agentic-pipeline-smoke-test` (a plataforma e o
  Symphony têm repos próprios).

## 3. Antes de push/PR

- `scripts/agent/preflight.sh --gates` verde (mesmos gates do CI);
- revise o diff completo antes de commitar (`git diff --stat`, `git diff`);
- PR em **Draft** seguindo [`.github/pull_request_template.md`](.github/pull_request_template.md),
  com: o que muda, decisão registrada (arquivo), gates executados e riscos;
- sem merge automático: o item vai para `ready-for-human` e um humano decide.

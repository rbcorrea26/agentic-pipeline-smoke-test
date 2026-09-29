---
# Contrato de execucao de agentic-pipeline-smoke-test.
#
# Schema do front matter: Symphony (SPEC.md secao 5.3) — este projeto NAO inventa
# chaves novas. Nenhum valor de segredo e literal: use $VAR.
tracker:
  kind: github
  provider:
    repo: "rbcorrea26/agentic-pipeline-smoke-test"        # owner/repo deste projeto (nunca outro)
    token: $GITHUB_TOKEN            # variavel de ambiente, fora do Git
  required_labels:
    - "pipeline:ready"     # rotulo que torna a issue executavel
  active_states:
    - open
  terminal_states:
    - closed

polling:
  interval_ms: 30000

workspace:
  # Workspace descartavel por issue. NUNCA aponta para o clone de trabalho.
  # Lifecycle nativo do Symphony: reutilizado em retries e continuacoes.
  # Sem worktree ou limpeza customizada neste marco.
  root: "~/automation/workspaces/agentic-pipeline-smoke-test"

hooks:
  after_create: |
    git clone "https://github.com/rbcorrea26/agentic-pipeline-smoke-test.git" .   # PROJECT_CLONE_URL: em scripts/agent/project.env
    # Instale so o necessario no workspace; toolchain vem do ambiente
    # (agentic-dev-environment), nunca embutido no projeto.
  before_remove: |
    :

agent:
  max_concurrent_agents: 1          # comece conservador; aumente com evidencia
  # Enquanto a issue esta em estado ativo, o runner encadeia turnos ate este limite.
  # Com `delivery.enabled`, e o delivery que tira a issue do estado ativo (removendo
  # o rotulo de entrada) ao entregar: limite pequeno evita turnos pagos repetidos.
  max_turns: 1

# Executor: o fork do Symphony fala ACP com o agente lancado por `acp.command`.
# O comando CANONICO e o wrapper CONTIDO da plataforma
# (`$HOME/automation/bin/cline-sandboxed`, instalado pelo agentic-dev-environment):
# ele monta uma allowlist de filesystem com bubblewrap e lanca o Cline dentro dela
# (workspace da issue RW; HOME real, ~/projects, /mnt, ~/.ssh, ~/.config/gh,
# ~/.cline, o estado do Cline do pipeline e sockets do host NAO existem la dentro).
# O Codex app-server continua suportado como caminho alternativo: para usa-lo,
# troque `executor.kind` para `codex` e remova o bloco `acp`.
executor:
  kind: acp

acp:
  command: "$HOME/automation/bin/cline-sandboxed --acp"
  # Execucao headless: nao existe operador para aprovar um pedido de permissao do
  # agente. Com o default `false` (fail-closed) o primeiro pedido e negado e a
  # execucao termina em `{:approval_required, _}` sem produzir nada -- medido na fase
  # 6 da plataforma. Por isso o pipeline aprova os pedidos do agente.
  #
  # Isto NAO e a contencao: a contencao e a allowlist de filesystem do wrapper
  # contido (`acp.command` acima), decidida em
  # rbcorrea26/agentic-dev-environment (ADR-0008, issue #26). O que vale registrar:
  #   * o ACP nao promete sandbox: `codex.thread_sandbox`/`turn_sandbox_policy` nao
  #     sao enviados ao agente ACP;
  #   * o cwd e validado sob o workspace root, mas isso e diretorio de trabalho;
  #   * o isolamento de filesystem/processo vem do wrapper sandboxed; a REDE e
  #     compartilhada com o host (nao ha isolamento de rede -- risco residual);
  #   * se o wrapper contido nao conseguir montar a allowlist, o agente NAO roda
  #     (fail-closed): nunca ha fallback para execucao sem contencao.
  # O cliente ACP remove o token do tracker do processo do agente (`unset`) e nao
  # anuncia capabilities `fs`/`terminal` -- isso limita o que o agente poderia pedir
  # AO SYMPHONY, nao o que ele faz por conta propria.
  auto_approve_requests: true

# Publicacao: gates do projeto -> branch -> Draft PR -> CI -> handoff.
# Sem este bloco o Symphony apenas executa os turnos e nao publica nada.
delivery:
  enabled: true
  gates: "scripts/agent/preflight.sh --gates"   # a DEFINICAO de "passou" deste projeto
  gates_timeout_ms: 900000
  base_branch: "main"
  branch_prefix: "pipeline/"
  handoff_label: "pipeline:ready-for-human"
  remove_entry_labels: true        # tira o rotulo de entrada ao entregar (evita re-dispatch)
  commit_name: "agentic pipeline"
  commit_email: "pipeline@users.noreply.github.com"
  ci_timeout_ms: 1800000
  ci_poll_interval_ms: 15000
  # Review one-shot: pedida uma vez, depois do candidato estavel. Indisponibilidade
  # e registrada como tal e nunca inventada (o handoff nao depende dela).
  request_review: true
---

# Prompt de trabalho (template por issue)

O corpo deste arquivo é o **prompt template por issue** (Symphony `SPEC.md` §5.4).
Mantenha as variáveis de runtime do Symphony (por exemplo `{{ issue.identifier }}`)
onde fizer sentido.

## Contexto

Você trabalha na issue `{{ issue.identifier }}` — `{{ issue.title }}` — do
repositório `rbcorrea26/agentic-pipeline-smoke-test`, branch base `main`.
Leia antes de agir: `AGENTS.md`, `WORKFLOW.md`, `.cline/rules/`,
`docs/development/` e `docs/operations/`.

## Objetivo

Entregar exatamente o que a issue pede — nada além. Se o pedido estiver ambíguo
ou faltar informação de acesso, **pare e registre o bloqueio** na própria issue;
não invente credencial, escopo, dependência nem requisito.

## Como trabalhar

1. rode `scripts/agent/preflight.sh` e confirme que está no repositório certo;
2. faça a menor mudança coerente com o pedido, seguindo os padrões do projeto;
3. teste o que mudou (teste automatizado quando houver comportamento novo);
4. rode `scripts/agent/gates.sh` (são os mesmos gates do CI);
5. registre decisão durável no mesmo PR (doc, ADR do projeto ou regra em
   `.cline/rules/`).

**Quem publica é o pipeline, não você.** Quando `delivery.enabled` está ligado
(este arquivo), **não** crie branch, **não** faça commit e **não** abra PR: deixe
as mudanças no worktree do workspace. O Symphony roda os gates, cria a branch
`pipeline/<identificador>` e o Draft PR, espera o CI e marca o item como
`ready-for-human`.

## Proibido

- escrever em `main`, dar merge ou publicar release;
- criar branch, commit ou PR por conta própria quando o pipeline publica
  (`delivery.enabled`): a publicação é do Symphony;
- alterar repositórios que não sejam `rbcorrea26/agentic-pipeline-smoke-test`;
- registrar segredo, token ou chave em qualquer arquivo, commit, issue ou PR;
- enfraquecer, desativar ou marcar como `skip` um gate só para "passar";
- alterar arquivos fora do escopo da issue.

## Evidência esperada no PR

- Draft PR seguindo `.github/pull_request_template.md`;
- o que mudou e por quê; decisão registrada (arquivo/seção);
- gates executados e o resultado;
- riscos, limitações e o que não foi feito.

## Handoff

O contrato alvo é: gates verdes → Draft PR → CI verde → candidate stable →
Copilot review one-shot → `ready-for-human`. Correções decorrentes da review
passam novamente pelos gates e CI. O merge é decisão humana.

A política autoritativa está no
[ADR-0006 da plataforma](https://github.com/rbcorrea26/agentic-dev-environment/blob/main/docs/architecture/adr/0006-revisao-e-gates-deterministicos.md):
`Review new pushes = OFF`, uma review por padrão e no máximo uma segunda quando
a primeira provocou mudança substancial, sensível ou arquitetural, com motivo
registrado no PR. Nunca há loop automático de re-review.

O humano só reentra em `ready-for-human`, bloqueio real que o executor não
consegue resolver ou operação `privileged` com autorização humana explícita.
O perfil padrão é `dev`; `read` é observação. Esses perfis são conceituais,
conforme as
[permissões da plataforma](https://github.com/rbcorrea26/agentic-dev-environment/blob/main/docs/security/permissions.md).

Este template documenta o contrato; a automação dessas etapas e o runner ACP
ainda dependem da implementação da plataforma.


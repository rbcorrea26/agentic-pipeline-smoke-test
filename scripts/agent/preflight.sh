#!/usr/bin/env bash
# scripts/agent/preflight.sh -- validacao antes de trabalhar neste projeto.
#
# Contrato documentado em docs/operations/preflight.md.
#   scripts/agent/preflight.sh            # verificacoes rapidas
#   scripts/agent/preflight.sh --gates    # inclui scripts/agent/gates.sh
#
# Exit codes: 0 = pode trabalhar (WARN nao bloqueia), 1 = FAIL encontrado,
#             2 = uso incorreto.
# Nunca le nem imprime segredos: apenas identidade de repositorio e presenca de
# arquivos.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

WITH_GATES=0
for arg in "$@"; do
  case "$arg" in
    --gates) WITH_GATES=1 ;;
    -h | --help)
      printf 'uso: %s [--gates]\n' "$(basename "$0")"
      exit 0
      ;;
    *)
      printf 'uso: %s [--gates]\n' "$(basename "$0")" >&2
      exit 2
      ;;
  esac
done

PASS=0
WARN=0
FAIL=0
ok() { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
warn() { printf 'WARN %s\n' "$1"; WARN=$((WARN + 1)); }
bad() { printf 'FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); }

PROJECT_ENV="$SCRIPT_DIR/project.env"
if [[ ! -f "$PROJECT_ENV" ]]; then
  bad "project-env: ausente ($PROJECT_ENV)"
  printf '\nresumo: %d pass, %d warn, %d fail\n' "$PASS" "$WARN" "$FAIL"
  exit 1
fi
# shellcheck source=project.env
. "$PROJECT_ENV"
ok "project-env: lido"

# ---------------------------------------------------------- placeholders -----

# Padrao dos tokens do template (escrito sem o prefixo literal para nao casar
# consigo mesmo). Qualquer ocorrencia significa template nao adotado.
TOKEN_PATTERN='\{\{PROJECT_[A-Z_]+\}\}'
pending="$(grep -rInE "$TOKEN_PATTERN" . \
  --exclude-dir=.git --exclude-dir=deps --exclude-dir=_build \
  --exclude-dir=node_modules --exclude-dir=cover || true)"
if [[ -n "$pending" ]]; then
  bad "placeholders de template pendentes (substitua pelos valores do projeto):"
  printf '%s\n' "$pending" | head -20
else
  ok "sem placeholders de template pendentes"
fi

# ------------------------------------------------------------- contrato ------

CONTRACT_FILES=(
  AGENTS.md
  WORKFLOW.md
  README.md
  .github/pull_request_template.md
  .github/ISSUE_TEMPLATE/task.md
  .github/workflows
  .cline/rules
  docs/development
  docs/operations
  scripts/agent/gates.sh
)
for f in "${CONTRACT_FILES[@]}"; do
  if [[ -e "$f" ]]; then
    ok "contrato presente: $f"
  else
    bad "contrato ausente: $f"
  fi
done

# ---------------------------------------------------------------- git --------

if git rev-parse --git-dir >/dev/null 2>&1; then
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  case "$remote_url" in
    *"${PROJECT_REPO:-__indefinido__}"*) ok "origin corresponde a ${PROJECT_REPO}" ;;
    "") warn "sem remote origin (esperado: ${PROJECT_REPO}); clone o projeto antes de trabalhar" ;;
    *) bad "origin NAO corresponde a ${PROJECT_REPO}: ${remote_url} (projeto errado?)" ;;
  esac

  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  if [[ "$branch" == "${PROJECT_DEFAULT_BRANCH:-main}" ]]; then
    warn "branch atual e a padrao (${PROJECT_DEFAULT_BRANCH}): crie branch dedicada"
  else
    ok "branch de trabalho: ${branch}"
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    warn "worktree com mudancas nao commitadas"
  else
    ok "worktree limpo"
  fi

  ok "HEAD $(git rev-parse --short HEAD)"
else
  bad "nao e um repositorio git"
fi

# --------------------------------------------------------------- gates -------

if ((WITH_GATES)); then
  if [[ ! -f scripts/agent/gates.sh ]]; then
    bad "gates: scripts/agent/gates.sh ausente"
  elif bash scripts/agent/gates.sh; then
    ok "gates: scripts/agent/gates.sh verde"
  else
    bad "gates: scripts/agent/gates.sh vermelho (corrija a causa)"
  fi
fi

printf '\nresumo: %d pass, %d warn, %d fail\n' "$PASS" "$WARN" "$FAIL"
if ((FAIL > 0)); then
  exit 1
fi
exit 0

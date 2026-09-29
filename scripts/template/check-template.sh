#!/usr/bin/env bash
# scripts/template/check-template.sh -- integridade DESTE template.
#
# Este script NAO e o gate de um projeto consumidor: ele valida que o repositorio
# ainda e o template distribuivel (estrutura, contratos, placeholders esperados por
# arquivo, sintaxe dos scripts e o placeholder bloqueante de gates) e e executado
# pelo job `template` de `.github/workflows/gates.yml` apenas enquanto o repositorio
# nao foi instanciado. Depois da instanciacao, o CI passa a rodar
# `scripts/agent/gates.sh` (o gate do projeto).
#
#   bash scripts/template/check-template.sh
#
# Exit codes: 0 = template integro, 1 = FAIL encontrado, 2 = uso incorreto.
# Nunca le nem imprime segredo: valida presenca de arquivo, sintaxe e contrato.
#
# NOTA DE IMPLEMENTACAO: os tokens de placeholder deste repositorio sao montados em
# tempo de execucao (prefixo + nome + sufixo) e nunca aparecem literalmente neste
# arquivo -- se aparecessem, a deteccao de "template instanciado" do CI encontraria
# placeholders em um repositorio ja instanciado e pularia os gates do projeto.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$TEMPLATE_ROOT"

PASS=0
WARN=0
FAIL=0
ok() { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
warn() { printf 'WARN %s\n' "$1"; WARN=$((WARN + 1)); }
bad() { printf 'FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); }

CHECK_LBRACE='{'
CHECK_RBRACE='}'
CHECK_TOKEN_PREFIX="${CHECK_LBRACE}${CHECK_LBRACE}PROJECT_"
CHECK_TOKEN_SUFFIX="${CHECK_RBRACE}${CHECK_RBRACE}"
CHECK_TOKEN_REGEX='\{\{PROJECT_[A-Z_]+\}\}'

token() { printf '%s%s%s' "$CHECK_TOKEN_PREFIX" "$1" "$CHECK_TOKEN_SUFFIX"; }

tokens_in() {
  grep -oE "$CHECK_TOKEN_REGEX" "$1" 2>/dev/null | sort -u || true
}

# ------------------------------------------------------------- contrato -------

CONTRACT_FILES=(
  AGENTS.md
  WORKFLOW.md
  README.md
  .github/ISSUE_TEMPLATE/task.md
  .github/pull_request_template.md
  .github/workflows/gates.yml
  .cline/rules
  docs/development
  docs/operations
  docs/operations/preflight.md
  docs/operations/delivery.md
  scripts/agent/project.env
  scripts/agent/preflight.sh
  scripts/agent/gates.sh
  scripts/template/check-template.sh
)

for f in "${CONTRACT_FILES[@]}"; do
  if [[ -e "$f" ]]; then
    ok "contrato presente: $f"
  else
    bad "contrato ausente: $f"
  fi
done

# --------------------------------------- placeholders esperados, por arquivo ---

# "arquivo|sufixos do token" -- o conjunto encontrado precisa ser EXATAMENTE este.
# Isso detecta instanciacao parcial (um arquivo substituido, outro nao), que a
# checagem global de presenca nao pega.
EXPECTED_TOKENS_BY_FILE=(
  "AGENTS.md|NAME REPO DEFAULT_BRANCH"
  "WORKFLOW.md|NAME REPO CLONE_URL DEFAULT_BRANCH READY_LABEL ACP_COMMAND"
  ".github/ISSUE_TEMPLATE/task.md|READY_LABEL"
  ".github/workflows/gates.yml|DEFAULT_BRANCH"
  ".cline/rules/00-project-rules.md|NAME REPO DEFAULT_BRANCH"
  ".cline/rules/10-execution-rules.md|DEFAULT_BRANCH"
  "docs/development/README.md|NAME"
  "scripts/agent/project.env|NAME REPO CLONE_URL DEFAULT_BRANCH READY_LABEL ACP_COMMAND"
)

expected_all=""
token_failures=0

for entry in "${EXPECTED_TOKENS_BY_FILE[@]}"; do
  file="${entry%%|*}"
  expected_list=""
  # shellcheck disable=SC2086
  for suffix in ${entry#*|}; do
    expected_list+="$(token "$suffix")"$'\n'
  done
  expected="$(printf '%s' "$expected_list" | sort -u)"
  found="$(tokens_in "$file")"

  if [[ "$expected" == "$found" ]]; then
    ok "placeholders de $file conferem"
  else
    bad "placeholders de $file divergem (esperado: $(tr '\n' ' ' <<<"$expected"))"
    printf '     encontrado: %s\n' "$(tr '\n' ' ' <<<"$found")"
    token_failures=$((token_failures + 1))
  fi

  expected_all+="$expected"$'\n'
done

all_expected="$(printf '%s' "$expected_all" | grep -v '^$' | sort -u)"
all_found="$(
  grep -rhoE "$CHECK_TOKEN_REGEX" . \
    --exclude-dir=.git --exclude-dir=deps --exclude-dir=_build --exclude-dir=node_modules | sort -u || true
)"

if [[ "$all_expected" == "$all_found" ]]; then
  ok "nenhum placeholder fora do contrato do template"
else
  bad "tokens fora do contrato ou template parcialmente instanciado:"
  diff <(printf '%s\n' "$all_expected") <(printf '%s\n' "$all_found") || true
fi

if ((token_failures == 0)); then
  ok "instanciacao parcial detectavel: ${#EXPECTED_TOKENS_BY_FILE[@]} arquivos conferidos"
fi


# ------------------------------------------------------------- sintaxe --------

syntax_failures=0
while IFS= read -r script; do
  if ! bash -n "$script" 2>/dev/null; then
    bad "sintaxe: $script"
    syntax_failures=$((syntax_failures + 1))
  fi
done < <(find . -name '*.sh' -type f \
  -not -path './.git/*' -not -path './deps/*' -not -path './_build/*' -not -path './node_modules/*' | sort)

if ((syntax_failures == 0)); then
  ok "bash -n em todos os scripts shell"
fi

# --------------------------------------------------- gates ainda bloqueante ---

if bash scripts/agent/gates.sh >/dev/null 2>&1; then
  bad "template-gates: scripts/agent/gates.sh nao bloqueia mais (o template nao pode passar por gates de projeto)"
elif grep -q 'placeholder do template' scripts/agent/gates.sh; then
  ok "template-gates: placeholder bloqueante preservado (projeto nao configurado nunca fica verde)"
else
  bad "template-gates: gates.sh falha, mas nao pelo placeholder do template (verifique o contrato)"
fi

# ------------------------------------------------- workflow de gates (CI) ------

if grep -q 'bash scripts/agent/gates.sh' .github/workflows/gates.yml; then
  ok "workflow: job de gates do consumidor executa scripts/agent/gates.sh"
else
  bad "workflow: .github/workflows/gates.yml nao executa scripts/agent/gates.sh"
fi

for marker in 'instantiated' "$(token DEFAULT_BRANCH)"; do
  if grep -qF -- "$marker" .github/workflows/gates.yml; then
    ok "workflow: marcador presente (${marker})"
  else
    bad "workflow: marcador ausente (${marker})"
  fi
done

# ------------------------------------------------------- project.env ---------

PROJECT_ENV_KEYS=(NAME REPO CLONE_URL DEFAULT_BRANCH READY_LABEL ACP_COMMAND)

for key in "${PROJECT_ENV_KEYS[@]}"; do
  if grep -q "^PROJECT_${key}=" scripts/agent/project.env; then
    ok "project.env declara PROJECT_${key}"
  else
    bad "project.env sem PROJECT_${key}"
  fi
done

# ------------------------------------------------- WORKFLOW.md (blocos) -------

for block in 'tracker:' 'workspace:' 'executor:' 'acp:' 'delivery:' 'required_labels:' 'max_turns:'; do
  if grep -qE "^[[:space:]]*${block}" WORKFLOW.md; then
    ok "WORKFLOW.md declara $block"
  else
    bad "WORKFLOW.md sem $block"
  fi
done

# -------------------------------------------------------------- segredos ------

if grep -rInE 'gh[psou]_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9]{16,}|BEGIN [A-Z ]*PRIVATE KEY' . \
  --exclude-dir=.git >/dev/null 2>&1; then
  bad "valor com aparencia de segredo encontrado no template"
else
  ok "nenhum valor com aparencia de segredo no template"
fi

printf '\nresumo: %d pass, %d warn, %d fail\n' "$PASS" "$WARN" "$FAIL"
if ((FAIL > 0)); then
  exit 1
fi
exit 0

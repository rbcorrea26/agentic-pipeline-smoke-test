#!/usr/bin/env bash
# tests/test_answer.sh -- teste determinístico de answer.sh.
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

output="$(bash "$PROJECT_ROOT/answer.sh")"

if [[ "$output" != "42" ]]; then
  echo "FAIL answer.sh imprimiu '${output}' (esperado: '42')" >&2
  exit 1
fi

echo "PASS answer.sh imprime 42"

#!/usr/bin/env bash
# scripts/agent/gates.sh -- gates determinísticos deste projeto.
#
# CONTRATO: este arquivo é a DEFINIÇÃO OFICIAL de "passou" para o projeto, e o CI
# (.github/workflows/gates.yml) roda o MESMO conjunto de comandos. Regras:
#   * determinístico (mesma entrada -> mesma saída), sem rede, sem segredo;
#   * falha = exit != 0; nada de "aviso" que não quebra;
#   * nunca desative um gate para "passar".

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo '== sintaxe =='
bash -n answer.sh
bash -n tests/test_answer.sh

echo '== testes =='
bash tests/test_answer.sh

echo '== diff =='
git diff --check

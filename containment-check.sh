#!/usr/bin/env bash
# Relatorio de contencao do agente ACP, produzido DENTRO da sandbox.
# NUNCA imprime valor de credencial: apenas presenca/ausencia de caminhos.
set -uo pipefail

echo "hostname=$(cat /proc/sys/kernel/hostname 2>/dev/null || echo '?')"
echo "pid1=$(cat /proc/1/comm 2>/dev/null || echo '?')"
echo "home=${HOME:-<vazio>}"
echo "pwd=${PWD:-<vazio>}"
echo "provider=${CLINE_PROVIDER:-<vazio>}"
echo "model=${CLINE_MODEL:-<vazio>}"
echo "credencial_presente=$([[ -n "${CLINE_API_KEY:-}" ]] && echo sim || echo nao)"
echo "tracker_token=${GITHUB_TOKEN:-ausente}"
echo "env_names=$(env | cut -d= -f1 | sort | tr '\n' ',')"

echo "--- caminhos (esperado: ausente) ---"
for p in /home/rbcorrea \
         /home/rbcorrea/projects \
         /home/rbcorrea/projects/security-canary.txt \
         /home/rbcorrea/.ssh \
         /home/rbcorrea/.config/gh \
         /home/rbcorrea/.cline \
         /home/rbcorrea/automation \
         /home/rbcorrea/automation/state/cline \
         /home/rbcorrea/automation/state/cline/data/settings/providers.json \
         /home/rbcorrea/automation/security-canaries/home-canary.txt \
         /home/rbcorrea/.config/agentic-dev-environment/env \
         /mnt/c /mnt/wsl \
         /var/run/docker.sock \
         /run/user/1000; do
  if [[ -e "$p" ]]; then echo "VISIVEL $p"; else echo "ausente $p"; fi
done

echo "--- caminhos (esperado: visivel) ---"
echo "visivel $PWD"
[[ -x /ade/node/bin/node ]] && echo "visivel /ade/node/bin/node"
[[ -x /ade/cline/node_modules/cline/bin/cline ]] && echo "visivel /ade/cline/node_modules/cline/bin/cline"

if cat /home/rbcorrea/automation/security-canaries/home-canary.txt >/dev/null 2>&1; then
  echo "canario_externo=LEGIVEL"
else
  echo "canario_externo=inacessivel"
fi

# Desenvolvimento

Como desenvolver e validar `agentic-pipeline-smoke-test` localmente. Este projeto é
um repositório **descartável** de validação do pipeline: a implementação é trivial
de propósito e os gates são curtos e determinísticos.

## Pré-requisitos

- runtime e toolchain vêm do **ambiente** (`agentic-dev-environment`); o projeto
  **não** guarda runtime embutido;
- nenhum segredo é necessário: os gates não usam rede nem credencial.

## Fluxo

```bash
scripts/agent/preflight.sh          # valida identidade, contrato e git
bash answer.sh                      # resposta do projeto
scripts/agent/preflight.sh --gates  # mesmos gates do CI
```

## Testes e gates

- `scripts/agent/gates.sh` é a definição oficial de "passou"; o CI
  (`.github/workflows/gates.yml`) roda exatamente o mesmo conjunto;
- nada de métrica transitória em documentação: a evidência é o CI/PR.

| Gate | Comando | O que cobre |
|---|---|---|
| sintaxe | `bash -n answer.sh`, `bash -n tests/test_answer.sh` | scripts íntegros |
| teste | `bash tests/test_answer.sh` | `bash answer.sh` imprime exatamente 42 |
| diff | `git diff --check` | whitespace/erro de patch |

## Documentação

- decisão durável (arquitetura, convenção, contrato) entra no mesmo PR;
- não copie métricas transitórias (cobertura, duração, SHA) para documentos;
- regras que o agente deve seguir durante o trabalho vivem em `.cline/rules/`.


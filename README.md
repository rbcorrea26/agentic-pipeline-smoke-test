# agentic-pipeline-smoke-test

Repositório **descartável**, criado exclusivamente para provar o pipeline agêntico
ponta a ponta (fase 6 do roadmap da plataforma):

```text
GitHub Issue -> Symphony -> ACP -> Cline/DeepSeek -> workspace isolado
             -> gates do projeto -> Draft PR -> CI -> ready-for-human
```

- **não** é um projeto consumidor real e não deve se tornar um;
- não contém segredo, produção, SSH, WordPress nem dependência de serviço privado;
- adota o contrato de projeto do `agentic-project-template` (`AGENTS.md`,
  `WORKFLOW.md`, `.cline/rules/`, `scripts/agent/`, `.github/`);
- a issue de teste pede uma mudança trivial e determinística em `answer.sh`.

## Como validar

```bash
bash answer.sh                        # hoje imprime 1 (a issue pede 42)
scripts/agent/preflight.sh --gates    # identidade + contrato + gates
```

| Gate | Comando | O que cobre |
|---|---|---|
| sintaxe | `bash -n answer.sh`, `bash -n tests/test_answer.sh` | scripts íntegros |
| teste | `bash tests/test_answer.sh` | `bash answer.sh` imprime exatamente 42 |
| diff | `git diff --check` | whitespace/erro de patch |

`.github/workflows/gates.yml` roda `scripts/agent/gates.sh` no CI: o mesmo
conjunto de comandos, com o resultado oficial por rodada.

## Documentação

| Assunto | Documento |
|---|---|
| contrato de execução (tracker, executor ACP, publicação) | [`WORKFLOW.md`](WORKFLOW.md) |
| como desenvolver e validar | [`docs/development/`](docs/development/) |
| preflight | [`docs/operations/preflight.md`](docs/operations/preflight.md) |
| publicação (gates -> Draft PR -> CI -> handoff) | [`docs/operations/delivery.md`](docs/operations/delivery.md) |
| regras do agente | [`AGENTS.md`](AGENTS.md), [`.cline/rules/`](.cline/rules/) |

Remoção: este repositório é evidência da fase 6 e pode ser apagado quando a
validação não for mais necessária — a decisão de manter/remover pertence à
plataforma (`agentic-dev-environment`), não a este repositório.

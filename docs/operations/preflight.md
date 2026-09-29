# Preflight / validation contract

Contrato de validação deste projeto: o que precisa ser verdade **antes** de
trabalhar e **antes** de abrir PR. O preflight é a expressão executável deste
documento (`scripts/agent/preflight.sh`) e é a primeira coisa que o pipeline roda
no workspace.

## Como rodar

```bash
scripts/agent/preflight.sh            # verificacoes rapidas (sem executar gates)
scripts/agent/preflight.sh --gates    # inclui os gates de scripts/agent/gates.sh
```

Saída no estilo `PASS <item>` / `WARN <item>` / `FAIL <item>`, com resumo final.

| Exit code | Significado |
|---|---|
| `0` | pode trabalhar (WARN não bloqueiam, mas devem ser resolvidos) |
| `1` | não pode trabalhar — corrija os `FAIL` |

## O que é verificado

| Verificação | Tipo | Como corrigir |
|---|---|---|
| placeholders de template pendentes (padrão de token deste template) | **FAIL** | substitua pelos valores reais do projeto — inclusive nesta documentação |
| arquivos de contrato presentes (`AGENTS.md`, `WORKFLOW.md`, `.github/*` incluindo `.github/workflows/`, `.cline/rules/`, `docs/*`, `scripts/agent/gates.sh`) | **FAIL** | restaure/complete a estrutura do template |
| `scripts/agent/project.env` presente e legível | **FAIL** | preencha a identidade do projeto (sem segredos) |
| `origin` corresponde a `PROJECT_REPO` de `project.env` | **FAIL** | este é o guarda contra operar no repositório errado: não contorne; corrija o clone/remote |
| branch atual é a branch padrão | WARN | crie branch dedicada para o trabalho |
| worktree com mudanças não commitadas | WARN | commite ou descarte antes de começar |
| gates (`--gates`) | **FAIL** | corrija a causa; gate vermelho não vira PR |

O preflight **nunca** lê ou imprime segredos: ele só verifica presença de arquivo e
identidade de repositório.

## Relação com o CI

- `scripts/agent/gates.sh` é a definição oficial de "passou"; o CI roda o mesmo
  conjunto e é a **evidência oficial** de execução (resultado transitório, não
  documentação).
- O preflight não substitui o CI: ele evita gastar execução com um estado
  obviamente inválido (repositório errado, template não adotado, gate quebrado).

## Guarda contra "projeto errado"

Um projeto copiado do template **não consegue operar contra outro repositório por
engano**: enquanto houver placeholders de template, o preflight falha; e se o
`origin` não corresponder ao repositório declarado em `project.env`, o preflight
falha antes de qualquer mudança.

Ao mudar de projeto (nunca por acidente), `project.env` e `WORKFLOW.md` são
atualizados no mesmo PR — e isso é decisão registrada, não ajuste silencioso.

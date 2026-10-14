---
name: coverage-gate
description: Verificação determinística de cobertura de testes. Rejeita automaticamente qualquer submissão se a porcentagem de cobertura cair (regressão) ou violar o threshold mínimo. Trabalha em conjunto com o QA Specialist e a skill test-scaffold. Use para "checar cobertura", "validar coverage" ou "gate de testes".
---

# Skill: Coverage Gate (Portão Determinístico de Cobertura)

**Objetivo:** Impor um critério matemático e determinístico de cobertura de testes automatizados. O gate calcula a cobertura das alterações e rejeita qualquer entrega caso a cobertura global regrida ou caso o código novo/alterado não atinja o threshold mínimo exigido. Opera em estreita colaboração com o **QA Specialist** e com a skill `test-scaffold`.

## Propriedade (quem usa, quando)

- **QA Specialist:** Executa a suíte com flags de cobertura durante o fan-out de verificação (`em-verificacao`) e anexa os dados no `qa-report.md`.
- **Developer:** Executa localmente antes do handoff à verificação para garantir que todo código introduzido possui cobertura adequada.
- **Tech Lead:** Valida no join de verificação se o gate de cobertura foi aprovado com base na evidência numérica real.

## 1. Comandos de Cobertura por Stack

Consulte `memories/architecture.md § Testes e Cobertura` para comandos customizados. Na ausência, utilize os padrões da stack:

| Ecossistema | Comando de Execução com Cobertura | Arquivo de Relatório Gerado |
|---|---|---|
| **Jest (Node.js)** | `npm test -- --coverage --coverageReporters="text" --coverageReporters="json-summary"` | `coverage/coverage-summary.json` |
| **Vitest** | `npx vitest run --coverage` | `coverage/coverage-summary.json` |
| **Pytest (Python)** | `pytest --cov=. --cov-report=term-missing --cov-report=json:coverage.json` | `coverage.json` |
| **Go** | `go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out` | `coverage.out` |
| **Rust** | `cargo tarpaulin --out Json --output-dir target/coverage` | `target/coverage/tarpaulin-report.json` |
| **Java (Maven/JaCoCo)** | `mvn clean test jacoco:report` | `target/site/jacoco/jacoco.csv` |
| **.NET / C#** | `dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover` | `coverage.opencover.xml` |

## 2. Regras Rígidas de Aceite (Hard Rules)

A submissão é avaliada sob duas regras matemáticas obrigatórias:

### Regra 1: Não-Regressão Global (Delta Coverage)
$$\text{Cobertura Total}_{\text{atual}} \ge \text{Cobertura Total}_{\text{baseline}}$$
- A cobertura total do repositório **NÃO PODE** ser reduzida em relação à baseline (registrada em `memories/architecture.md § Cobertura` ou no commit base da branch).
- Uma queda de até mesmo 0.1% na cobertura global resulta em **REJEIÇÃO DETERMINÍSTICA**.

### Regra 2: Threshold Mínimo do Diff (Patch Coverage)
$$\text{Cobertura do Código Modificado} \ge \text{Threshold Mínimo (Default: 80\%)}$$
- Todo arquivo tocado no `git diff` da task deve ter suas linhas e branches novas cobertas em no mínimo **80%** (ou o valor estipulado em `memories/architecture.md`).
- Arquivos de lógica de negócio e serviços críticos (`core`, `services`, `domain`) exigem **90%**.

## 3. Workflow de Execução e Bloqueio

```
[Executar Suíte com Cobertura]
         │
         ▼
[Extrair Métricas Numéricas: Linhas, Branches, Funções]
         │
         ├── Linhas novas sem teste OU Cobertura Total < Baseline?
         │
    ┌────┴──────────────────────────┐
    ▼ (SIM: Violação)               ▼ (NÃO: Aprovado)
[REJEIÇÃO DETERMINÍSTICA]       [APROVAÇÃO]
  │                               │
  ├─ Registra falha no Log        └─ Anexa relatório no qa-report.md
  ├─ Aciona test-scaffold            e no task.md § Evidências
  │  (aponta linhas descobertas)
  └─ Devolve ao Developer
```

### Em caso de REJEIÇÃO:
1. Extraia a lista de linhas e arquivos descobertos:
   ```
   arquivo.ts: Linhas sem cobertura: 42-58, 73, 90-95
   ```
2. O QA Specialist ou Developer aciona imediatamente a skill `test-scaffold`:
   - *"Acionando skill test-scaffold para gerar testes unitários focando nas linhas não cobertas de arquivo.ts"*.
3. Registre no `## Log` da task:
   `- AAAA-MM-DD — ❌ COVERAGE-GATE: cobertura insuficiente (<atual>% < <baseline>%). Linhas descobertas em <arquivo>. Despachando test-scaffold.`

## 4. Evidência Obrigatória no qa-report.md

O `qa-report.md` deve conter obrigatoriamente a tabela de cobertura preenchida com valores reais:

```markdown
### Cobertura de Testes (Coverage Gate)
- **Baseline anterior:** XX.X%
- **Cobertura atual:** YY.Y%
- **Delta:** +Z.Z% (ou -Z.Z%)
- **Status do Gate:** [ ] ✅ APROVADO | [ ] ❌ REPROVADO
- **Linhas descobertas no diff:** <listar ou 'nenhuma'>
```

## Restrições

- **Proibido arredondamento tolerante:** Se o threshold for 80%, 79.9% é reprovação.
- **Evidência de execução real:** Proibido inferir cobertura por leitura textual de arquivos de teste. A evidência só é válida com a saída do comando colada.
- **Proibido ignorar arquivos sem autorização:** Não configure regras de exclusão (`exclude`/`ignore`) em arquivos de configuração de cobertura para driblar o gate sem um ADR ou aprovação expressa do Tech Lead.

---
name: dependency-lock
description: Bloqueio determinístico de alterações não autorizadas em arquivos de dependências (manifestos e lockfiles) e auditoria estrita de vulnerabilidades via CLI. Reforça o agente Security e a skill security-audit. Use para "bloquear dependências", "verificar lockfile", "auditar pacotes" ou "travar dependências".
---

# Skill: Dependency Lock (Guardião Determinístico de Dependências)

**Objetivo:** Impedir adições ou alterações não autorizadas de dependências em manifestos (`package.json`, `requirements.txt`, etc.), garantir paridade estrita entre manifestos e lockfiles, e executar auditorias de vulnerabilidades (CVEs) baseadas exclusivamente em códigos de saída (exit codes) do CLI. Complementa o trabalho do **Security Specialist** e da skill `security-audit`.

## Propriedade (quem usa, quando)

- **Security Specialist:** No fan-out de verificação ou em auditorias diretas de superfície sensível.
- **Tech Lead:** No review e no join, verificando se o diff tocou arquivos de dependências e se houve autorização explícita.
- **Ops:** Na checagem pré-entrega para garantir que os lockfiles estão perfeitamente sincronizados e imutáveis.

## 1. Arquivos Monitorados

A skill monitora qualquer alteração nos seguintes pares de arquivos:

| Ecossistema | Manifesto de Dependências | Lockfile Obrigatório |
|---|---|---|
| **Node.js (npm)** | `package.json` | `package-lock.json` |
| **Node.js (pnpm / yarn)** | `package.json` | `pnpm-lock.yaml` ou `yarn.lock` |
| **Python (Poetry / Pipenv)** | `pyproject.toml` ou `Pipfile` | `poetry.lock` ou `Pipfile.lock` |
| **Python (pip/requirements)** | `requirements.in` ou `requirements.txt` | `requirements.txt` (com hashes sha256) |
| **Go** | `go.mod` | `go.sum` |
| **Rust** | `Cargo.toml` | `Cargo.lock` |
| **Java (Maven)** | `pom.xml` | — (validação de checksums) |
| **Ruby** | `Gemfile` | `Gemfile.lock` |

## 2. Os 3 Portões Determinísticos

### Portão 1: Autorização Prévia (Unauthorized Modification Gate)
- O script/agente avalia o diff: `git diff --name-only origin/main...HEAD`
- Se qualquer arquivo de manifesto ou lockfile estiver no diff:
  1. Verifica se a task ativa em `docs/todo/<NNN-slug>/task.md` contém autorização expressa em:
     - `## Dependências Autorizadas` (com justificativa de negócio/técnica), OU
     - `## Notas do Architect` aprovando a nova biblioteca.
  2. **Sem autorização registrada:** **BLOQUEIO IMEDIATO**. A alteração de dependências é revertida:
     ```bash
     git checkout origin/main -- package.json package-lock.json
     ```
     Registra violação no `## Log` da task:
     `- AAAA-MM-DD — 🚨 VIOLAÇÃO: tentativa de alterar dependências sem autorização formal do Architect/TL.`

### Portão 2: Paridade e Integridade do Lockfile (Lockfile Integrity Gate)
Se a alteração foi autorizada, o lockfile DEVE acompanhar o manifesto com integridade 100% verificável:
- **Proibido editar lockfile manualmente.** Ele deve ser gerado pelo gerenciador de pacotes.
- **Comandos de validação estrita (dry-run / locked):**
  - Node (npm): `npm ci --dry-run` (valida se o lockfile bate exatamente com os manifestos sem alterar nada).
  - Node (pnpm): `pnpm install --frozen-lockfile`
  - Python (Poetry): `poetry check --lock`
  - Go: `go mod verify` (valida se as somas de hash no `go.sum` estão intactas).
  - Rust: `cargo check --locked` (rejeita caso o `Cargo.lock` necessite de atualização).
- **Discrepância ou lockfile ausente:** **REJEIÇÃO DETERMINÍSTICA**.

### Portão 3: Auditoria Determinística de CVEs (Exit Code Gate)
Execução do auditor nativo configurado na stack:

```bash
# Node.js: falha se houver vulnerabilidades High ou Critical
npm audit --audit-level=high

# Python: varredura estrita de dependências
pip-audit --desc

# Rust: auditoria de vulnerabilidades de crates
cargo audit

# Go: scanner oficial de vulnerabilidades
govulncheck ./...
```

- **Exit Code != 0:** O processo é abortado imediatamente.
- Vulnerabilidades encontradas são repassadas ao **Security Specialist** para registro formal no `security-review.md`.
- Liberação permitida **única e exclusivamente** se houver Aceite de Risco registrado formalmente no procedimento único do manager § 🚧.

## 3. Supply Chain Security Hardening

Esta skill aplica verificações rígidas contra ataques de cadeia de suprimentos:
1. **Fontes Suspeitas:** Rejeita qualquer dependência apontando para URLs git diretas arbitrárias (`git://`, `http://`), tarballs externos ou registries privados não documentados em `memories/architecture.md`.
2. **Scripts Maliciosos de Instalação:** Detecta e alerta sobre scripts `postinstall` ou `preinstall` arbitrários em pacotes recém-adicionados.
3. **Typosquatting Check:** Pacotes novos devem ter seus nomes e downloads validados pelo Security Specialist antes de serem mesclados.

## Restrições

- **Proibido flags de supressão sem aprovação:** O uso de flags como `--force`, `--legacy-peer-deps` ou `--ignore-scripts` é proibido sem registro explícito de ADR via skill `guard`.
- **Integridade é inegociável:** Qualquer commit contendo alteração em manifesto sem o respectivo lockfile atualizado é rejeitado no gate de entrega do Ops.

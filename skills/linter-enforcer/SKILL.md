---
name: linter-enforcer
description: Validação sintática e de formatação estrita via ferramentas CLI nativas (ESLint, Prettier, Ruff, Biome, Clippy, etc.). Portão determinístico duro que bloqueia código antes da revisão probabilística (code-review). Use para "validar lint", "checar formatação" ou "executar linter".
---

# Skill: Linter Enforcer (Gate Sintático Determinístico)

**Objetivo:** Estabelecer um portão duro (hard gate) determinístico de conformidade sintática e de estilo usando linters e formatadores de linha de comando. Rejeita o diff **imediatamente** se houver qualquer erro sintático ou de formatação, bloqueando o código antes que ele chegue à análise probabilística da skill `code-review` (economizando tempo e tokens de LLM).

## Propriedade (quem usa, quando)

- **Developer:** Durante o ciclo TDD e obrigatoriamente no **Self-review** antes de mudar o status para `em-verificacao`.
- **Tech Lead:** Na entrada do review pré-commit (fan-out de verificação). Se o linter falhar, o review é interrompido imediatamente sem consumir análise de LLM.
- **QA Specialist:** Re-execução determinística na auditoria funcional, anexando a evidência de execução ao `qa-report.md`.

## 1. Deteção de Ferramentas por Stack

A ferramenta e o comando oficial devem ser consultados em `memories/architecture.md § Build e Ferramentas`. Na ausência de registro explícito, inspecione a raiz do projeto e execute conforme a stack:

| Stack / Ecossistema | Arquivos de Configuração | Comando Determinístico (Strict / Zero Warnings) |
|---|---|---|
| **Node.js / TypeScript** | `eslint.config.*`, `.eslintrc*`, `package.json` | `npm run lint` ou `npx eslint . --max-warnings=0` |
| **Prettier (Formatação)** | `.prettierrc*`, `prettier.config.*` | `npx prettier --check .` |
| **Biome** | `biome.json`, `biome.jsonc` | `npx @biomejs/biome check .` |
| **Python (Ruff)** | `ruff.toml`, `pyproject.toml` | `ruff check . && ruff format --check .` |
| **Python (Flake8 / Black)** | `.flake8`, `setup.cfg`, `pyproject.toml` | `flake8 . && black --check .` |
| **Go** | `.golangci.yml`, `go.mod` | `golangci-lint run ./...` e `test -z "$(gofmt -l .)"` |
| **Rust** | `Cargo.toml`, `clippy.toml` | `cargo clippy --all-targets -- -D warnings && cargo fmt --check` |
| **Java / Kotlin** | `pom.xml`, `build.gradle` | `mvn checkstyle:check` ou `./gradlew check` |
| **C# / .NET** | `*.sln`, `*.csproj`, `.editorconfig` | `dotnet format --verify-no-changes` |
| **Ruby** | `.rubocop.yml`, `Gemfile` | `bundle exec rubocop` |
| **PHP** | `phpcs.xml`, `phpstan.neon` | `./vendor/bin/phpcs && ./vendor/bin/phpstan analyse` |

## 2. Protocolo de Execução (Fail-Fast)

1. **Execução Local:**
   Execute o comando CLI diretamente no ambiente local (terminal).
2. **Avaliação Determinística por Exit Code:**
   - **Exit Code 0 (Sucesso):** Nenhuma violação sintática ou de estilo encontrada. O código está autorizado a avançar para o gate de análise arquitetural/lógica (`code-review`).
   - **Exit Code != 0 (Falha):** **REJEIÇÃO DETERMINÍSTICA IMEDIATA**. O fluxo é bloqueado.
3. **Registro de Evidências:**
   Cole a saída real do terminal (com arquivos, linhas e códigos de erro) na seção `## Evidências` do `docs/todo/<NNN-slug>/task.md`.
4. **Devolução Automática:**
   Em caso de falha durante a verificação, registre o bloqueio no `## Log` da task:
   `- AAAA-MM-DD — ❌ LINTER-ENFORCER: falha determinística de linting (<ferramenta>, exit code <N>). Devolvido ao Developer.`

## 3. Correção Automatizada (Safe Auto-Fix)

O Developer pode tentar correção automatizada para problemas puramente cosméticos:
- ESLint: `npx eslint . --fix`
- Prettier: `npx prettier --write .`
- Ruff: `ruff check --fix . && ruff format .`
- Rust: `cargo fmt`
- Go: `gofmt -w .`

> [!IMPORTANT]
> Após qualquer auto-fix, o comando de checagem estrita **DEVE** ser re-executado para garantir Exit Code 0, e a suíte de testes deve ser rodada novamente para garantir que nenhuma semântica foi alterada.

## Restrições

- **Zero Tolerance:** Warnings são tratados como erros (`--max-warnings=0` ou flags equivalentes). Não é permitido mascarar warnings com comentários `// eslint-disable` ou `# noqa` sem justificativa prévia aceita pelo Tech Lead.
- **Portão Pré-LLM:** A persona Tech Lead **NUNCA** deve redigir feedback de estilo ou Clean Code em `review.md` enquanto o `linter-enforcer` estiver falhando — a correção sintática precede qualquer avaliação subjetiva.
- **Proibido bypass:** O `linter-enforcer` não pode ser desativado no ciclo, exceto sob opt-out formal registrado conforme o manager.

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

A skill monitora qualquer alteração nos arquivos abaixo — **lista fechada**: é a mesma que `dotagents-verify.sh deps` aplica, e arquivo de dependência fora dela não é detectado. Nome faltante → registre-o em `docs/todo/backlog-compound.md` para entrar no verificador (vira item de backlog, não reabre o gate da task). Regras de casamento, **sem distinção de maiúsculas** (macOS e Windows não distinguem; a dobra é só ASCII):
- **nome do arquivo em qualquer diretório** (`*` = qualquer sequência no nome);
- **só na raiz do escopo** (nomes genéricos, que fora da raiz casariam arquivos sem relação): `WORKSPACE`, `WORKSPACE.bazel`, `global.json`, `environment.yml`, `environment.yaml`, `project.clj`, `deps.edn`;
- **pelo diretório:** `requirements/*.txt` · `requirements/*.in`, `.yarn/releases/*` · `.yarn/plugins/*`, `.mvn/extensions.xml` · `.mvn/maven.config` · `.mvn/jvm.config`, `.cargo/config` · `.cargo/config.toml`, `.bundle/config`.

O casamento por nome tem falsos positivos (ex.: `docs/requirements/login.txt`): o `deps` os lista para conferência e o `deps-revert` nunca descarta conteúdo local — antes de trocar ou remover um arquivo, ele guarda a versão da working tree (symlink como symlink, sem segui-lo) — e, quando difere da working tree e do `HEAD`, a versão do índice (`git add` seguido de edição ou de `rm`) — na quarentena `<diretório git comum>/dotagents/deps-quarantine/<data>-<pid>/` (o `.git` do repositório, compartilhado por todos os worktrees: sobrevive a `git worktree remove`), de onde é recuperável. A quarentena é **plana**: cada item é `<NNNN>-<worktree|index>-<nome do arquivo>`, e o `MANIFEST` do diretório mapeia nome → origem → path. Sem subdiretórios, um symlink guardado nunca vira caminho para a gravação seguinte, e nenhum item sobrescreve outro (destino existente → 🚨). A saída cita cada arquivo e o destino.

| Ecossistema | Manifesto / configuração do gerenciador | Lockfile Obrigatório |
|---|---|---|
| **Node.js (npm)** | `package.json`, `.npmrc` | `package-lock.json` ou `npm-shrinkwrap.json` |
| **Node.js (pnpm / yarn / bun / Deno)** | `package.json`, `pnpm-workspace.yaml`, `.pnpmfile.cjs`, `.yarnrc`, `.yarnrc.yml`, `.yarn/releases/*`, `.yarn/plugins/*`, `bunfig.toml`, `deno.json`, `deno.jsonc`, `import_map.json` | `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `bun.lockb` ou `deno.lock` |
| **Python (Poetry / Pipenv / uv / PDM / setuptools / Conda)** | `pyproject.toml`, `Pipfile`, `setup.py`, `setup.cfg`, `pip.conf`, `pip.ini`, `uv.toml`, `pdm.toml`, `environment.yml`, `environment.yaml`, `.condarc` | `poetry.lock`, `Pipfile.lock`, `uv.lock` ou `pdm.lock` |
| **Python (pip/requirements)** | `requirements*.in`, `requirements*.txt`, `constraints.txt`, `requirements/*.txt`, `requirements/*.in` | `requirements*.txt` (com hashes sha256) |
| **Go** | `go.mod`, `go.work` | `go.sum`, `go.work.sum` |
| **Rust** | `Cargo.toml`, `.cargo/config`, `.cargo/config.toml` | `Cargo.lock` |
| **JVM (Maven / Gradle / sbt / Clojure)** | `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts`, `libs.versions.toml`, `gradle.properties`, `gradlew`, `gradlew.bat`, `gradle-wrapper.properties`, `gradle-wrapper.jar`, `mvnw`, `mvnw.cmd`, `maven-wrapper.properties`, `maven-wrapper.jar`, `.mvn/extensions.xml`, `.mvn/maven.config`, `.mvn/jvm.config`, `build.sbt`, `deps.edn`, `project.clj` | `gradle.lockfile` (Maven: validação de checksums) |
| **.NET (NuGet / Paket)** | `*.csproj`, `*.fsproj`, `*.vbproj`, `packages.config`, `Directory.Packages.props`, `Directory.Build.props`, `Directory.Build.targets`, `NuGet.Config`, `global.json`, `dotnet-tools.json`, `paket.dependencies` | `packages.lock.json` ou `paket.lock` |
| **PHP (Composer)** | `composer.json` | `composer.lock` |
| **Ruby** | `Gemfile`, `gems.rb`, `*.gemspec`, `.bundle/config` | `Gemfile.lock` ou `gems.locked` |
| **Elixir · Dart · Swift · CocoaPods** | `mix.exs` · `pubspec.yaml`, `pubspec_overrides.yaml` · `Package.swift` · `Podfile` | `mix.lock` · `pubspec.lock` · `Package.resolved` · `Podfile.lock` |
| **Bazel · Nix · C/C++ (vcpkg / Conan)** | `MODULE.bazel`, `WORKSPACE`, `WORKSPACE.bazel` · `flake.nix` · `vcpkg.json`, `vcpkg-configuration.json`, `conanfile.txt`, `conanfile.py` | `MODULE.bazel.lock` · `flake.lock` · vcpkg: sem lockfile (versões fixadas por `builtin-baseline`) · `conan.lock` |

## 2. Os 3 Portões Determinísticos

### Portão 1: Autorização Prévia (Unauthorized Modification Gate)
- O script/agente lista os manifestos e lockfiles do diff — modificados, novos e **deletados**, commitados ou não: `{{AGENTS_ROOT}}/hooks/dotagents-verify.sh deps` (exit 3 → pare e registre o 🚨 do stderr). A lista de nomes monitorados é a tabela do § 1.
- Se a lista não estiver vazia:
  1. Verifica se a task ativa em `docs/todo/<NNN-slug>/task.md` contém autorização expressa em:
     - `## Dependências Autorizadas` (com justificativa de negócio/técnica), OU
     - `## Notas do Architect` aprovando a nova biblioteca.
  2. **Sem autorização registrada:** **BLOQUEIO IMEDIATO**. Os manifestos e lockfiles do diff voltam à versão do merge-base (ausentes no merge-base vão para a quarentena do § 1; a versão local dos que voltam ao merge-base também fica guardada lá) — sem digitar nomes de arquivo:
     ```bash
     {{AGENTS_ROOT}}/hooks/dotagents-verify.sh deps-revert
     ```
     Manifesto sob diretório que virou symlink → 🚨 (o script nunca escreve nem apaga através do link, nem na working tree nem na quarentena): reverta manualmente e registre no Log.
     Registra violação no `## Log` da task:
     `- AAAA-MM-DD — 🚨 VIOLAÇÃO: tentativa de alterar dependências sem autorização formal do Architect/TL.`

### Portão 2: Paridade e Integridade do Lockfile (Lockfile Integrity Gate)
Se a alteração foi autorizada e o projeto usa lockfile naquele ecossistema (coluna "Lockfile Obrigatório" do § 1 e arquivo presente no repositório), o lockfile DEVE acompanhar o manifesto com integridade 100% verificável. Arquivo de configuração do gerenciador (`.npmrc`, `.yarnrc*`, `pip.conf`, `uv.toml`, `.cargo/config*`, `NuGet.Config`, wrappers) e ecossistema sem lockfile no projeto passam só pelo Portão 1 (autorização) e pelo Portão 3:
- **Proibido editar lockfile manualmente.** Ele deve ser gerado pelo gerenciador de pacotes.
- **Comandos de validação estrita (dry-run / locked):**
  - Node (npm): `npm ci --dry-run` (valida se o lockfile bate exatamente com os manifestos sem alterar nada).
  - Node (pnpm): `pnpm install --frozen-lockfile`
  - Python (Poetry): `poetry check --lock`
  - Go: `go mod verify` (valida se as somas de hash no `go.sum` estão intactas).
  - Rust: `cargo check --locked` (rejeita caso o `Cargo.lock` necessite de atualização).
  - Outros já conhecidos: yarn `yarn install --immutable` · uv `uv lock --check` · Pipenv `pipenv verify` · Composer `composer validate` · Bundler `bundle check` · NuGet `dotnet restore --locked-mode`.
  - **Ecossistema sem comando listado:** use o comando de validação da stack registrado em `memories/architecture.md`. Sem registro → abra item em `docs/todo/backlog-compound.md` com o comando proposto; o portão fica sem veredito automático nesse ecossistema e isso é registrado no `## Log` da task.
- **Discrepância, ou lockfile ausente num projeto que usa lockfile:** **REJEIÇÃO DETERMINÍSTICA**.

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

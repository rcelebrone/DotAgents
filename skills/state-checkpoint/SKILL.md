---
name: state-checkpoint
description: Reversão automática de estado (rollback via Git). Cria snapshots antes de modificações e restaura o ambiente imediatamente à versão funcional anterior caso as alterações do agente (em comandos como dot-agent-fix-bug ou dot-agent-new-feature) falhem nos testes locais ou na compilação. Use para "criar checkpoint", "rollback automático", "restaurar estado funcional" ou "reverter alterações".
---

# Skill: State Checkpoint (Snapshot e Rollback Determinístico)

**Objetivo:** Proteger a integridade do repositório contra loops degenerados e quebras catastróficas de compilação introduzidas por agentes. Cria um snapshot determinístico (checkpoint) do Git antes que qualquer alteração de código seja iniciada (em fluxos como `dot-agent-fix-bug` ou `dot-agent-new-feature`). Caso a compilação local ou os testes essenciais falhem e não sejam corrigidos prontamente, a skill executa a restauração atômica do workspace de volta ao último estado estável conhecido.

## Propriedade (quem usa, quando)

- **Developer:** Cria o checkpoint logo antes de iniciar a primeira edição de código da task e executa rollback se introduzir erros irreparáveis de compilação.
- **Tech Lead:** Aciona rollback para abortar implementações que atingiram o limite de 3 iterações de loop com falha de build.
- **Ops:** Utiliza checkpoints na verificação pré-entrega e em recuperações rápidas locais.

## 1. Criação do Checkpoint (Snapshot Pré-Implementação)

Antes de qualquer modificação de arquivos de código (no início da task ou de uma rota de fix/feature):

```bash
# 1. Identificar o commit funcional de base
BASE_COMMIT=$(git rev-parse HEAD)
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
CHECKPOINT_NAME="checkpoint-$(date +%Y%m%d-%H%M%S)"

# 2. Criar tag local efêmera de checkpoint
git tag "dotagents/$CHECKPOINT_NAME" "$BASE_COMMIT"

# 3. Registrar o checkpoint no task.md da tarefa ativa
echo "Checkpoint criado: dotagents/$CHECKPOINT_NAME no commit $BASE_COMMIT"
```

No `## Log` de `docs/todo/<NNN-slug>/task.md`, insira:
`- AAAA-MM-DD — 📌 CHECKPOINT: snapshot criado em dotagents/<CHECKPOINT_NAME> (commit <BASE_COMMIT>).`

## 2. Teste de Compilação e Verificação Rápida

Após as alterações do Developer e antes de prosseguir com a entrega:

1. **Executar comando de compilação da stack:**
   - Node/TypeScript: `npm run build`
   - Go: `go build ./...`
   - Rust: `cargo check` ou `cargo build`
   - Python: `python3 -m py_compile $(git diff --name-only origin/main...HEAD | grep '\.py$')`
   - Java/Kotlin: `mvn compile -DskipTests` ou `./gradlew classes`
   - C#/.NET: `dotnet build`

2. **Avaliação por Código de Saída:**
   - **Exit Code 0:** Compilação verde. O código está apto para seguir para o fan-out de testes/review.
   - **Exit Code != 0:** Falha detectada. Registre o erro exato do compilador.

## 3. Protocolo de Auto-Rollback Determinístico

Se o Developer não conseguir sanar o erro de compilação ou se for atingida a 3ª iteração do loop com build quebrado, o **Auto-Rollback** é disparado imediatamente:

```bash
# 1. Backup defensivo de evidências e logs de erro
git diff > /tmp/dotagents-failed-diff.patch

# 2. Restauração atômica do código para o commit de checkpoint
git reset --hard "$BASE_COMMIT"

# 3. Remoção de arquivos novos não rastreados (órfãos) que quebraram o build
# Mantém pastas preservadas da squad (docs/ e memories/)
git clean -fd -e docs/ -e memories/

# 4. Confirmação do estado restaurado
git status
```

### Registro no Log da Task:
Após a reversão, o agente **DEVE** registrar o rollback no `## Log` do `task.md`:
`- AAAA-MM-DD — ⏪ ROLLBACK AUTOMÁTICO: compilação falhou (<saída do compilador>); ambiente restaurado deterministicamente para o commit <BASE_COMMIT>. Diff preservado em /tmp/dotagents-failed-diff.patch.`

O status da task é definido como `em-refinamento` (ou escalado ao Tech Lead para replanejamento ou divisão da task).

## 4. Limpeza de Checkpoints Efêmeros

Quando a task é finalizada e o ciclo de entrega local (`delivery`) é concluído com sucesso pelo Ops:

```bash
# Exclui tags de checkpoint locais concluídas
git tag -d $(git tag -l "dotagents/*") 2>/dev/null || true
```

## Restrições

- **Nunca aplicar `reset --hard` em branch remota compartilhada:** O checkpoint opera estritamente na branch local de trabalho da task (`feat/*`, `fix/*`, `refactor/*`).
- **Preservação de docs/ e memories/:** O comando `git clean` NUNCA deve remover arquivos de documentação da squad (`docs/todo/`, `docs/done/`, `memories/`), garantindo que o histórico e os motivos do rollback permaneçam íntegros.
- **Rollback é atômico:** Não faça rollback parcial de alguns arquivos deixando outros para trás em estado híbrido e inconsistente.

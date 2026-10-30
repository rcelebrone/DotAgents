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
   - Python: script abaixo (arquivos `.py` do diff via `dotagents-verify.sh paths -z`; não grava `__pycache__`)
   - Java/Kotlin: `mvn compile -DskipTests` ou `./gradlew classes`
   - C#/.NET: `dotnet build`

```bash
python3 - "{{AGENTS_ROOT}}/hooks/dotagents-verify.sh" <<'PY'
import subprocess, sys
listing = subprocess.run(['sh', sys.argv[1], 'paths', '-z'], stdout=subprocess.PIPE)
if listing.returncode != 0:
    sys.exit(listing.returncode)
failed = False
for path in [p for p in listing.stdout.decode('utf-8', 'surrogateescape').split('\0') if p.endswith('.py')]:
    try:
        with open(path, 'rb') as source:
            compile(source.read(), path, 'exec')
    except SyntaxError as error:
        print(f'❌ {path}:{error.lineno}: {error.msg}')
        failed = True
sys.exit(1 if failed else 0)
PY
```

Exit 3 do verificador (🚨 no stderr) é propagado — pare e registre o 🚨.

2. **Avaliação por Código de Saída:**
   - **Exit Code 0:** Compilação verde. O código está apto para seguir para o fan-out de testes/review.
   - **Exit Code != 0:** Falha detectada. Registre o erro exato do compilador.

## 3. Protocolo de Auto-Rollback Determinístico

Se o Developer não conseguir sanar o erro de compilação ou se for atingida a 3ª iteração do loop com build quebrado, o **Auto-Rollback** é disparado imediatamente:

Rode o bloco inteiro **num único shell** (salve-o num arquivo temporário fora do repositório e execute `sh <arquivo>`): cada passo aborta com exit 3 antes de descartar algo.

```bash
# 0. O reset --hard atinge o repositório inteiro (não respeita escopos aninhados): o rollback inteiro roda na raiz
cd "$(git rev-parse --show-toplevel)" || { echo "🚨 fora de um repositório git — rollback abortado"; exit 3; }

# 1. Checkpoint da task: o nome registrado no Log (📌 CHECKPOINT) — nunca "a tag mais recente", que pode vir do remoto
[ -n "${CHECKPOINT:-}" ] || { echo "🚨 defina CHECKPOINT=dotagents/checkpoint-… com o nome registrado no Log da task"; exit 3; }
git rev-parse --verify -q "refs/tags/$CHECKPOINT^{commit}" >/dev/null \
  && git merge-base --is-ancestor "refs/tags/$CHECKPOINT" HEAD \
  || { echo "🚨 checkpoint $CHECKPOINT inexistente ou fora do histórico da branch — rollback abortado"; exit 3; }

# 2. Backup defensivo de TUDO o que será descartado (rastreados e novos não ignorados), numa ref local do git.
#    Identidade fixa (não depende de user.name/email); ref única por rollback, criada só se não existir.
BACKUP_REF="refs/dotagents/backup-${CHECKPOINT#dotagents/}-$(date +%Y%m%d%H%M%S)"
git add -A \
  && TREE=$(git write-tree) \
  && BACKUP=$(git -c user.name=dotagents -c user.email=dotagents@localhost commit-tree "$TREE" -p HEAD -m "dotagents: backup antes do rollback para $CHECKPOINT") \
  && git update-ref "$BACKUP_REF" "$BACKUP" "" \
  && git reset -q \
  || { git reset -q; echo "🚨 backup falhou — rollback abortado, nada foi descartado"; exit 3; }
echo "backup: $BACKUP_REF"

# 3. Restauração do código para o checkpoint, preservando docs/ e memories/ de todos os escopos (Log das tasks, memórias).
#    Diretórios do backup E do checkpoint: um docs/ apagado inteiro durante a task (ausente no backup) volta ausente.
#    A lista é montada ANTES do reset: nome com quebra de linha aborta aqui, sem descartar nada.
for REF in "$BACKUP" "refs/tags/$CHECKPOINT"; do
  [ "$(( $(git ls-tree -r -d -z --name-only "$REF" | tr -cd '\n' | wc -c) ))" -eq 0 ] \
    || { echo "🚨 diretório com quebra de linha no nome — rollback abortado, nada foi descartado (backup em $BACKUP_REF)"; exit 3; }
done
PRESERVE=$( { git ls-tree -r -d -z --name-only "$BACKUP"; git ls-tree -r -d -z --name-only "refs/tags/$CHECKPOINT"; } \
  | tr '\0' '\n' | grep -E '(^|/)(docs|memories)$' | sort -u)
git reset --hard "refs/tags/$CHECKPOINT" || { echo "🚨 reset --hard falhou — backup em $BACKUP_REF"; exit 3; }
# restore sem overlay: o diretório fica exatamente como no backup (arquivo ou diretório apagado durante a task não reaparece)
printf '%s\n' "$PRESERVE" | while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  GIT_LITERAL_PATHSPECS=1 git restore --source="$BACKUP" --worktree -- "$dir" || exit 3
done || { echo "🚨 restauração de docs/ ou memories/ falhou — backup em $BACKUP_REF"; exit 3; }

# 4. Remoção de arquivos novos não rastreados (órfãos) que quebraram o build, preservando docs/ e memories/
git clean -fd -e docs/ -e memories/ || { echo "🚨 git clean falhou — backup em $BACKUP_REF"; exit 3; }

# 5. Confirmação do estado restaurado
git status
```

Recuperar algo do backup: `git checkout "<BACKUP_REF impresso no passo 2>" -- <arquivo>`. A ref de backup é **local** e guarda todo arquivo novo não ignorado (inclusive segredos esquecidos fora do `.gitignore`): nunca publique refs `refs/dotagents/*` (ex.: `git push --mirror`) e remova-a na limpeza (§ 4).

### Registro no Log da Task:
Após a reversão, o agente **DEVE** registrar o rollback no `## Log` do `task.md`:
`- AAAA-MM-DD — ⏪ ROLLBACK AUTOMÁTICO: compilação falhou (<saída do compilador>); ambiente restaurado deterministicamente para <CHECKPOINT>. Backup em <BACKUP_REF>.`

O status da task é definido como `em-refinamento` (ou escalado ao Tech Lead para replanejamento ou divisão da task).

## 4. Limpeza de Checkpoints Efêmeros

Quando a task é finalizada e o ciclo de entrega local (`delivery`) é concluído com sucesso pelo Ops:

```bash
# Exclui só o checkpoint e os backups desta task (nome registrado no Log)
git tag -d "$CHECKPOINT"
git for-each-ref --format='%(refname)' refs/dotagents/ | grep -F "refs/dotagents/backup-${CHECKPOINT#dotagents/}-" | while IFS= read -r ref; do git update-ref -d "$ref"; done
```

## Restrições

- **Nunca aplicar `reset --hard` em branch remota compartilhada:** O checkpoint opera estritamente na branch local de trabalho da task (`feat/*`, `fix/*`, `refactor/*`).
- **Preservação de docs/ e memories/:** O comando `git clean` NUNCA deve remover arquivos de documentação da squad (`docs/todo/`, `docs/done/`, `memories/`), garantindo que o histórico e os motivos do rollback permaneçam íntegros.
- **Rollback é atômico:** Não faça rollback parcial de alguns arquivos deixando outros para trás em estado híbrido e inconsistente.

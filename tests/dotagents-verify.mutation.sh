#!/bin/sh
# Teste de mutação da suíte: cada controle essencial do hooks/dotagents-verify.sh é removido, um de cada vez,
# e a suíte tests/dotagents-verify.test.sh precisa falhar. Um mutante que sobrevive = controle sem teste.
# Rode a partir da raiz do repositório DotAgents: sh tests/dotagents-verify.mutation.sh (leva alguns minutos)
# Exit: 0 todos os mutantes morreram · 1 algum mutante sobreviveu.
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT
cp -R "$HERE/hooks" "$HERE/tests" "$HERE/skills" "$WORK/"
SURVIVED=0

# mutate <nome> <trecho original> <trecho mutante>
mutate() {
  cp "$HERE/hooks/dotagents-verify.sh" "$WORK/hooks/dotagents-verify.sh"
  python3 - "$WORK/hooks/dotagents-verify.sh" "$2" "$3" <<'PY' || { printf '⚠️ mutante %s não aplicável (trecho não encontrado)\n' "$1"; SURVIVED=1; return; }
import sys
path, original, mutant = sys.argv[1:4]
source = open(path).read()
if original not in source:
    sys.exit(1)
open(path, 'w').write(source.replace(original, mutant, 1))
PY
  result=$(sh "$WORK/tests/dotagents-verify.test.sh" 2>&1 | tail -n 1)
  case $result in
    *" 0 falharam"*) printf '❌ sobreviveu: %s — %s\n' "$1" "$result"; SURVIVED=1 ;;
    *) printf '✅ morto: %s — %s\n' "$1" "$result" ;;
  esac
}

mutate 'lint não bloqueia a execução' '[ "$ERRORS" -eq 0 ] || die "lint reprovado — nada foi executado"' ':'
mutate 'glob * cruza diretórios' '} else re = re "[^/]*"' '} else re = re ".*"'
mutate 'glob ? sem efeito' 'else if (c == "?") re = re "[^/]"' 'else if (c == "?") re = re "?"'
mutate 'renomeação esconde deleção' 'git diff --name-only -z --no-renames --relative' 'git diff --name-only -z --relative'
mutate 'branch base por nome curto' 'candidates="refs/remotes/origin/HEAD refs/heads/main refs/heads/master"' 'candidates="origin/HEAD main master"'
mutate 'symlinks mantidos no snapshot' 'find "$SNAPSHOT" -type l -exec rm -f {} + ||' 'true ||'
mutate 'motivo de N/A livre' '[^\`\$;&|<>\\\\$Q\"]+' '.+'
mutate 'autoverificação desligada' '    die "o verificador em execução ($relative) difere do merge-base' '    return 0; die "x'
mutate 'erro do comando vira violação' '*) echo error ;; esac ;;
    *)' '*) echo violation ;; esac ;;
    *)'
mutate 'paths segue diretório-pai symlink' '[ ! -L "$path" ] && ! crosses_symlink "$path" && emit' '[ ! -L "$path" ] && emit'
mutate 'deps-revert atravessa symlink' 'crosses_symlink "$path" && die "manifesto sob diretório' 'false && die "manifesto sob diretório'

[ "$SURVIVED" -eq 0 ]

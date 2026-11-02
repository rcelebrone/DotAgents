#!/bin/sh
# Teste de mutação da suíte: cada controle essencial do hooks/dotagents-verify.sh é removido, um de cada vez,
# e a suíte tests/dotagents-verify.test.sh precisa falhar. Um mutante que sobrevive = controle sem teste.
# Rode a partir da raiz do repositório DotAgents: sh tests/dotagents-verify.mutation.sh (cerca de 1 hora: a suíte inteira roda uma vez por mutante)
# Exit: 0 todos os mutantes morreram · 1 algum mutante sobreviveu.
set -u
unset CDPATH
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT
cp -R "$HERE/hooks" "$HERE/tests" "$HERE/skills" "$WORK/"
SURVIVED=0

# mutate <nome> <trecho original> <trecho mutante> [<trecho original> <trecho mutante> …]
# (vários pares: um controle em camadas só é removido quando todas saem juntas)
mutate() {
  name=$1; shift
  cp "$HERE/hooks/dotagents-verify.sh" "$WORK/hooks/dotagents-verify.sh"
  python3 - "$WORK/hooks/dotagents-verify.sh" "$@" <<'PY' || { printf '⚠️ mutante %s não aplicável (trecho não encontrado)\n' "$name"; SURVIVED=1; return; }
import sys
path, pairs = sys.argv[1], sys.argv[2:]
source = open(path).read()
for original, mutant in zip(pairs[0::2], pairs[1::2]):
    if len(pairs) % 2 or original not in source:
        sys.exit(1)
    source = source.replace(original, mutant, 1)
open(path, 'w').write(source)
PY
  result=$(sh "$WORK/tests/dotagents-verify.test.sh" 2>&1 | tail -n 1)
  # morto só com a linha de resultado da suíte e ao menos uma falha; sem a linha (suíte interrompida) = inconclusivo
  case $result in
    *" passaram · 0 falharam · "*) printf '❌ sobreviveu: %s — %s\n' "$name" "$result"; SURVIVED=1 ;;
    *" passaram · "*" falharam · "*) printf '✅ morto: %s — %s\n' "$name" "$result" ;;
    *) printf '⚠️ inconclusivo (suíte sem linha de resultado): %s — %s\n' "$name" "$result"; SURVIVED=1 ;;
  esac
}

mutate 'lint não bloqueia a execução' '[ "$ERRORS" -eq 0 ] || die "lint reprovado — nada foi executado"' ':'
mutate 'glob * cruza diretórios' '} else re = re "[^/]*"' '} else re = re ".*"'
mutate 'glob ? sem efeito' 'else if (c == "?") re = re "[^/]"' 'else if (c == "?") re = re "?"'
mutate 'renomeação esconde deleção' 'git $ATTR_HERE diff --name-only -z --no-renames --relative' 'git $ATTR_HERE diff --name-only -z --relative'
mutate 'branch base por nome curto' 'candidates="refs/heads/main refs/heads/master"' 'candidates="main master"'
mutate 'motivo de N/A livre' '[^\`\$;&|<>\\\\$Q\"]+' '.+'
mutate 'autoverificação desligada' '    die "o verificador em execução ($relative) difere do merge-base' '    return 0; die "x'
mutate 'erro do comando vira violação' '*) echo error ;; esac ;;
    *)' '*) echo violation ;; esac ;;
    *)'
mutate 'gramática aceita segmento ..' "PATH_SEG='(\\.[A-Za-z0-9_]|[A-Za-z0-9_*])[A-Za-z0-9_.*-]*'" "PATH_SEG='[A-Za-z0-9_.*-]+'"
mutate 'paths segue diretório-pai symlink' '[ ! -L "$path" ] && ! crosses_symlink "$path" && emit' '[ ! -L "$path" ] && emit'
mutate 'deps-revert atravessa symlink' 'crosses_symlink "$path" && die "manifesto sob diretório' 'false && die "manifesto sob diretório'

mutate 'base resolvida sem show-ref' 'git show-ref --verify -q "$ref" && git rev-parse' 'git rev-parse'
mutate 'autoverificação normaliza fim de linha' 'git cat-file blob "$MERGE_BASE:$relative" 2>/dev/null | cmp -s - "$VERIFIER_PATH" && return 0' 'git diff --quiet "$MERGE_BASE" -- "$VERIFIER_PATH" 2>/dev/null && return 0'
mutate 'diff de memories/ sensível a atributos' 'diff -U0 --no-renames --no-ext-diff --no-textconv --text --no-color' 'diff -U0 --no-renames'
mutate 'rg sem busca em binários' "printf 'rg --no-config -uuu %s'" "printf 'rg --no-config -uu %s'"
mutate 'forma test -e invertida' 'test*) [ "$2" -eq 0 ] && echo conform || echo violation ;;' 'test*) [ "$2" -eq 0 ] && echo violation || echo conform ;;'
mutate 'git rm sem pathspec literal' 'GIT_LITERAL_PATHSPECS=1 git rm' 'git rm'
mutate 'DOMINIO aceita comando' 'else if ($4 ~ /`DOMINIO`/ && !ok["na_bare", n]) err("DOMINIO exige Verify-Cmd `N/A`")' 'else if (0) err("x")'
mutate 'Verify-Cmd órfão aceito' 'if ($1 == "ORFA") { err("Verify-Cmd fora de uma entrada"); next }' 'if ($1 == "ORFA") next'
mutate 'snapshot copia symlink' '[ -f "$path" ] && [ ! -L "$path" ] && ! crosses_symlink "$path" && printf' '[ -f "$path" ] && printf'
mutate 'data impossível aceita' 'if (!ok["title", n] || !real_date($3))' 'if (!ok["title", n])'

mutate 'origin/HEAD aceito como ref comum' 'origin_head=$(git symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null) && candidates="$origin_head $candidates"' 'candidates="refs/remotes/origin/HEAD $candidates"'
mutate 'diff árvore a árvore ausente' 'cat "$TMP/changed.d" "$TMP/changed.t" "$TMP/changed.c"' 'cat "$TMP/changed.d" "$TMP/changed.c"'
mutate 'working-tree-encoding ignorado no snapshot' 'check_encoding "$TMP/copylist" snapshot' ': "$TMP/copylist" snapshot'
mutate 'working-tree-encoding ignorado em memories/' 'check_encoding "$TMP/files" memories' ': "$TMP/files" memories'
mutate 'byte NUL aceito em memória' 'tr -d '"'"'\000'"'"' < "$file" | cmp -s - "$file" || die' 'true || die'

mutate 'git checkout sem pathspec literal' 'GIT_LITERAL_PATHSPECS=1 git checkout -q' 'git checkout -q'
mutate 'snapshot sem check_names' '  check_names "$TMP/visible.z"' '  :'
mutate 'Presença: erro vira violação' '      case $2 in 0) echo conform ;; 1) echo violation ;; *) echo error ;; esac ;;' '      case $2 in 0) echo conform ;; *) echo violation ;; esac ;;'
mutate 'controles não sanitizados nas entradas' 'gsub(/[\001-\010\013-\037\177]/, "?")' 'gsub(/\001/, "?")'
mutate 'probe aceita diretório' '|| [ ! -f "$2" ] || [ -L "$2" ]; then' '|| [ -L "$2" ]; then'
mutate 'glob sem âncora final' '      return re "$"' '      return re'
mutate 'raiz não corta no curinga' "        case \$segment in *'*'*) break ;; esac" '        :'

# iteração 10 (QA F1b/F11/F12/F13, Security SEC-038/041/042/043, Review R78/M10b)
mutate 'cmp não exigido no início (D02)' 'command -v cmp >/dev/null 2>&1 || die "comando indisponível (cmp)' 'true || die "comando indisponível (cmp)'
mutate 'trap sem chmod deixa o temporário (F11)' 'trap '"'"'chmod -R u+rwX "$TMP" 2>/dev/null; rm -rf "$TMP"'"'"' EXIT' 'trap '"'"'rm -rf "$TMP"'"'"' EXIT'
mutate 'DOTAGENTS_BASE_BRANCH terminado em HEAD aceito (SEC-043)' 'case /$DOTAGENTS_BASE_BRANCH in */HEAD) die' 'case /$DOTAGENTS_BASE_BRANCH in */HEAD-nunca) die'
mutate 'requirements/ por diretório ignorado (SEC-042)' 'path ~ /(^|\/)requirements\/.*\.(txt|in)$/ ||' '0 ||'
mutate 'deps-revert ignora falha do git checkout (M73)' '|| die "git checkout falhou: $path"' '|| :'
mutate 'check-attr sem lista NUL (F12/F13)' 'tr '"'"'\n'"'"' '"'"'\0'"'"' < "$1" | git $ATTR_HERE check-attr -z --stdin working-tree-encoding' 'git $ATTR_HERE check-attr --stdin working-tree-encoding < "$1"'
mutate '-working-tree-encoding (unset) vira 🚨 (R78)' '$0 != "unspecified" && $0 != "unset"' '$0 != "unspecified"'
mutate 'falha de check-attr ignorada (D05/D06)' '|| die "git check-attr falhou"' '|| :'
mutate 'checkout velho ignorado em memories/ (SEC-041)' 'check_stale_checkout "$TMP/files" memories' ':'
mutate 'checkout velho ignorado no snapshot (SEC-041)' 'check_stale_checkout "$TMP/copylist" snapshot' ':'
mutate 'arquivo modificado tratado como checkout velho' 'if ($2 in modified) print' 'if (0) print'
mutate 'normalização ignorada (CRLF e filtro viram checkout velho)' '$2 != normalized[FNR] { print $1; exit }' '{ print $1; exit }'
mutate 'falha de git ls-files -s ignorada' '|| die "git ls-files -s falhou"' '|| :'
mutate 'falha de git ls-files -m ignorada' '|| die "git ls-files -m falhou"' '|| :'
mutate 'falha de git hash-object ignorada' '[ "$raw" -eq 0 ] || die "git hash-object falhou' 'true || die "git hash-object falhou'
mutate 'cópia preserva modo de diretório 555 (F11)' 'cp --no-preserve=mode --parents' 'cp --parents'
mutate 'falha da cópia do snapshot ignorada (D12)' '[ "$raw" -eq 0 ] || die "cópia para o snapshot falhou' 'true || die "cópia para o snapshot falhou'
mutate 'montagem do snapshot sem timeout (SEC-038)' '  with_timeout sh -c '"'"'
    case $1 in' '  sh -c '"'"'
    case $1 in'
mutate 'timeout da montagem não reconhecido (SEC-038)' '[ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na montagem' 'false && die "timeout (${TIMEOUT} s) na montagem'
mutate 'cpio nunca usado (SEC-038)' '    method=cpio' '    method=loop'
mutate 'Tipo alterado não avisa (M10b)' '(Tipo|Escopo \(globs\)|Verify-Cmd)' '(Escopo \(globs\)|Verify-Cmd)'

# iteração 11 (Security SEC-041/042/045/046 residuais, QA F17/F18/F20/F22/F27, Review R83/R87)
mutate 'ramo dos arquivos modificados ignorado (F17)' '[ -s "$TMP/dirty-$2" ] || return 0' 'return 0'
mutate 'NUL nos modificados ignorado (F17)' 'if [ "$wt_nul" -gt 0 ] && {' 'if false && {'
mutate 'BOM UTF-16/32 nos modificados ignorado (F17)' 'if [ "$wt_class" != none ] && [ "$wt_class" != "$blob_class" ]; then' 'if false; then'
mutate 'guarda de estágio 0 removida (F20)' 'if (meta[3] != "0" || !($2 in want)) next' 'if (!($2 in want)) next'
mutate 'falha de cat-file nos modificados vira mensagem errada' '[ "$kind" = ERR ] && die "git cat-file falhou: $path"' ':'
mutate 'hash-object fora do timeout (F18)' "with_timeout sh -c 'list=\$1" "sh -c 'list=\$1"
mutate 'leitura dos modificados fora do timeout (F18)' 'with_timeout sh -c "$BOM_CLASS"'"'"'
    TAB=' 'sh -c "$BOM_CLASS"'"'"'
    TAB='
mutate '--review aceita worktree sujo (SEC-041)' '[ -s "$TMP/status.z" ] && die "--review exige' 'false && die "--review exige'
mutate '--review aceita merge-base = HEAD (R87)' 'die "--review com merge-base igual a HEAD' 'warn "--review com merge-base igual a HEAD'
mutate 'merge-base = HEAD sem aviso (R87)' 'if [ "$(git rev-parse HEAD)" = "$MERGE_BASE" ]; then' 'if false; then'
mutate 'falha de git status ignorada no --review' '|| die "git status falhou"' '|| :'
mutate 'deps-revert apaga em vez de pôr na quarentena (SEC-045)' '          quarantine "$path" mv' '          rm -f -- "./$path"'
mutate 'manifesto com maiúsculas ignorado (SEC-042)' '{ path = tolower($0); name = path;' '{ path = $0; name = path;'
mutate '.yarn/releases e .yarn/plugins ignorados (SEC-042)' '|| path ~ /(^|\/)\.yarn\/(releases|plugins)\// { print; next }' '{ print; next }'
mutate 'PADRAO_SEMANTICO aceita Verify-Cmd executável (R83)' 'else if ($4 ~ /`PADRAO_SEMANTICO`/ && ok["exec", n]) err(' 'else if (0) err('
mutate 'listas do git das memórias no repositório inteiro (SEC-046)' 'check_stale_checkout "$TMP/files" memories memories' 'check_stale_checkout "$TMP/files" memories'
mutate 'GIT_ATTR_SOURCE herdado do ambiente (F22)' 'RIPGREP_CONFIG_PATH GIT_ATTR_SOURCE' 'RIPGREP_CONFIG_PATH'
mutate 'linha "N blocks" do cpio no 🚨 (F27)' "\$(grep -Ev '^[0-9]+ blocks?\$' \"\$TMP/copy.err\" | head -c 300" '$(head -c 300 "$TMP/copy.err"'

# iteração 12 (Review R93/R97/R102, Security SEC-041/042/045/047/048/049, QA F29–F39)
mutate 'BOM comparado por 4 bytes, não por classe (R93)' '[ "$wt_class" != "$blob_class" ]' '[ "$(od -An -tx1 -N4 < "$path")" != "$(od -An -tx1 -N4 < "$1")" ]'
mutate 'classe do blob ignorada (F37)' '[ "$wt_class" != "$blob_class" ]' 'true'
mutate 'BOM UTF-16BE ignorado (F37)' 'feff*) echo utf16be ;;' 'feff-nunca*) echo utf16be ;;'
mutate 'BOM UTF-32BE ignorado (F37)' '0000feff*) echo utf32be ;;' '0000feff-nunca*) echo utf32be ;;'
mutate 'BOM lido em 2 bytes (F37)' 'od -An -tx1 -N4' 'od -An -tx1 -N2'
mutate 'UTF-32LE tratado como UTF-16LE (R93)' 'fffe0000*) echo utf32le ;;' 'fffe0000-nunca*) echo utf32le ;;'
mutate 'densidade de NUL ignorada com blob com NUL (SEC-041)' '|| { [ "$wt_density" -ge 250 ] && [ "$wt_density" -gt $((2 * blob_density)) ]; }' '|| false'
mutate 'densidade de NUL sem a margem do dobro (binário vira 🚨)' '-gt $((2 * blob_density))' '-ge "$blob_density"'
mutate 'falha da checagem dos modificados ignorada (F37)' '[ "$raw" -eq 0 ] || die "checagem de checkout falhou' 'true || die "checagem de checkout falhou'
mutate '--review respeita status.showUntrackedFiles (F31/SEC-047)' ' --untracked-files=all --ignore-submodules=none' ''
mutate 'attr.tree do executor no check-attr (SEC-048)' 'git $ATTR_HERE check-attr' 'git check-attr'
mutate 'nomes genéricos em qualquer diretório (F36)' '|| path in at_root {' '|| name in at_root {'
mutate 'nomes da raiz ignorados (D2)' 'name in anywhere || path in at_root {' 'name in anywhere {'
mutate 'wrapper e lockfiles novos fora da lista (SEC-042/R97)' 'module.bazel module.bazel.lock' 'module.bazel'
mutate '.yarn/plugins ignorado (F37)' '\.yarn\/(releases|plugins)\/' '\.yarn\/(releases)\/'
mutate '.mvn por diretório ignorado (SEC-042)' 'path ~ /(^|\/)\.mvn\/(extensions\.xml|maven\.config|jvm\.config)$/ { print; next }' '0 { print; next }'
mutate '.cargo/config ignorado (SEC-042)' 'path ~ /(^|\/)\.cargo\/config(\.toml)?$/ ||' '0 ||'
mutate '.bundle/config ignorado (SEC-042)' '|| path ~ /(^|\/)\.bundle\/config$/ { print; next }' '{ print; next }'
mutate 'versão local do rastreado sem backup (F30)' 'then quarantine "$path" '"'"'cp -P'"'"'; saved=' 'then :; saved='
mutate 'mensagem de quarentena sem arquivo movido (F33)' "printf 'removido do índice (ausente no merge-base e da working tree): %s%s\n'" "printf 'movido para a quarentena (ausente no merge-base): %s%s\n'"
mutate 'quarentena por worktree (F34)' 'git rev-parse --git-common-dir)' 'git rev-parse --git-dir)'
mutate 'quarentena com diretório fixo (F37)' '/dotagents/deps-quarantine/$(date +%Y%m%d%H%M%S)-$$"' '/dotagents/deps-quarantine/fixo"'
mutate 'symlink quebrado novo fica fora da quarentena (F37)' 'if [ -e "./$path" ] || [ -L "./$path" ]; then
          quarantine "$path" mv' 'if [ -e "./$path" ]; then
          quarantine "$path" mv'
mutate 'base local antes da remota (R102)' 'candidates="refs/remotes/$DOTAGENTS_BASE_BRANCH refs/heads/$DOTAGENTS_BASE_BRANCH"' 'candidates="refs/heads/$DOTAGENTS_BASE_BRANCH refs/remotes/$DOTAGENTS_BASE_BRANCH"'
mutate 'seleção do snapshot com regex (F39, busybox awk)' 'cut = last_slash(path); if (cut == 0) next; path = substr(path, 1, cut - 1)' 'if (path !~ /\//) next; sub(/\/[^\/]*$/, "", path)'

# iteração 13 (SEC-050/051/052, R104–R110, F41–F47)
mutate 'BOM no snapshot ignorado (SEC-050)' 'check_bom "$TMP/copylist" snapshot' ': "$TMP/copylist" snapshot'
mutate 'pré-filtro do BOM só com FF FE (SEC-050)' 'grep -l -e "$be" -e "$le"' 'grep -l -e "$le"'
mutate 'bytes de BOM fora do início contam como BOM (SEC-050)' '[ "$class" = none ] || {' 'false || {'
mutate 'falha do grep da checagem de BOM ignorada (SEC-050)' 'grep -l -e "$be" -e "$le" -- "$@"; [ $? -le 1 ]' 'grep -l -e "$be" -e "$le" -- "$@"; true'
mutate 'falha da leitura dos BOM ignorada (SEC-050)' '[ "$raw" -eq 0 ] || die "checagem de BOM falhou' 'true || die "checagem de BOM falhou'
mutate 'ramo dos modificados sem pré-filtro (R104)' 'if [ "$bom" = 0 ] && tr -d "\000" < "$path" | cmp -s - "./$path"; then continue; fi' ':'
mutate 'pré-filtro ignora os bytes de BOM (R104)' 'if [ "$bom" = 0 ] && tr -d' 'if tr -d'
mutate 'od ausente sem 🚨 (R105)' 'command -v od >/dev/null 2>&1 || die' 'true || die'
mutate 'CDPATH herdado desvia os cd (F41/SEC-051)' 'RIPGREP_CONFIG_PATH GIT_ATTR_SOURCE CDPATH' 'RIPGREP_CONFIG_PATH GIT_ATTR_SOURCE' \
  'abs_dir() { case $1 in /*) (cd -P -- "$1" && pwd -P) ;; *) (cd -P -- "./$1" && pwd -P) ;; esac; }' 'abs_dir() { (cd "$1" && pwd -P); }'
mutate 'índice fora do diff (F43)' 'cat "$TMP/changed.d" "$TMP/changed.t" "$TMP/changed.c" "$TMP/changed.u"' 'cat "$TMP/changed.d" "$TMP/changed.t" "$TMP/changed.u"'
mutate 'versão do índice sem backup (F44)' 'quarantine "$path" index; staged=' ':; staged='
mutate 'versão do índice igual ao HEAD também vai para a quarentena (F44)' '&& ! GIT_LITERAL_PATHSPECS=1 git diff --cached --quiet --no-ext-diff HEAD -- "$path" 2>/dev/null; then' '; then'
mutate 'limiar de densidade de NUL ausente (F47)' '[ "$wt_density" -ge 250 ] && [ "$wt_density" -gt' '[ "$wt_density" -gt'
mutate 'classe none tratada como outra classe (F47)' '[ "$wt_class" != none ] && [ "$wt_class" != "$blob_class" ]' '[ "$wt_class" != "$blob_class" ]'
mutate 'divisão por zero com blob vazio (F47)' '[ "$size" -gt 0 ] && DENSITY=' 'DENSITY='
mutate 'backup do rastreado segue o symlink (F47)' "quarantine \"\$path\" 'cp -P'; saved=\"versão local" "quarantine \"\$path\" cp; saved=\"versão local"
mutate 'symlink pendente rastreado sem backup (F47)' "if [ -e \"./\$path\" ] || [ -L \"./\$path\" ]; then quarantine \"\$path\" 'cp -P'" "if [ -e \"./\$path\" ]; then quarantine \"\$path\" 'cp -P'"
mutate 'deps -z sem NUL (F47)' 'then tr '"'"'\n'"'"' '"'"'\0'"'"' < "$TMP/deps"' 'then cat "$TMP/deps"'
mutate 'falha do awk de manifestos ignorada (F47)' '"$1" || die "awk falhou na seleção de manifestos"' '"$1" || true'
mutate 'attr.tree do executor no ls-files -m (R109)' 'git $ATTR_HERE ls-files -m' 'git ls-files -m'
mutate 'attr.tree do executor no hash-object (R109)' 'xargs -0 git $attr hash-object' 'xargs -0 git hash-object'
mutate 'attr.tree do executor no diff da working tree (R109)' 'git $ATTR_HERE diff --name-only -z --no-renames --relative "$MERGE_BASE" >' 'git diff --name-only -z --no-renames --relative "$MERGE_BASE" >'
mutate 'attr.tree do executor no status do --review (R109)' 'git --no-optional-locks $ATTR_HERE status' 'git --no-optional-locks status'
mutate 'attr.tree do executor no diff de memories/ (R109)' 'git $ATTR_HERE diff -U0' 'git diff -U0'
mutate '--review respeita diff.ignoreSubmodules (F47)' ' --untracked-files=all --ignore-submodules=none' ' --untracked-files=all'
mutate 'diff vazio sem aviso (SEC-052)' '[ -s "$TMP/changed" ] || warn "diff vazio' 'true || warn "diff vazio'
mutate '🚨 do --review com merge-base = HEAD diz que é normal (F46)' 'die "--review com merge-base igual a HEAD ($base_ref): não há commits a revisar, a base está errada' 'die "merge-base igual a HEAD ($base_ref): (normal no review pré-commit da squad) a base está errada'

# iteração 14 (SEC-053/SEC-054/R112, F48)
mutate 'quarentena hierárquica segue o symlink guardado (SEC-053)' \
  'QUARANTINED="$QUARANTINE/$(printf '"'"'%04d'"'"' "$QUARANTINE_COUNT")-$kind-${1##*/}"' 'QUARANTINED="$QUARANTINE/$1"; mkdir -p -- "${QUARANTINED%/*}"' \
  '{ [ -e "$QUARANTINED" ] || [ -L "$QUARANTINED" ]; } && die' '{ false; } && die'
mutate 'quarentena sem número por item (SEC-054)' '$(printf '"'"'%04d'"'"' "$QUARANTINE_COUNT")-$kind-${1##*/}' '$kind-${1##*/}'
mutate 'MANIFEST da quarentena não gravado (SEC-053)' 'printf '"'"'%s\t%s\t%s\n'"'"' "${QUARANTINED##*/}" "$kind" "$1" >> "$QUARANTINE/MANIFEST"' 'true'
mutate 'cmp do pré-filtro sem ./ (F48)' 'cmp -s - "./$path"; then continue; fi' 'cmp -s - "$path"; then continue; fi'

# Equivalentes, sem mutante (R100/R110):
# - a checagem de nomes das listas ls-files -s/-m (SEC-046) repete, no snapshot, a de ls-files -co (superconjunto já
#   checado em make_snapshot) e, nas memórias, a do find (pathspec memories/);
# - check_names do status do --review: status não vazio já termina em 🚨 (exit 3) na linha seguinte; tirar a checagem de
#   nomes só muda a mensagem, nunca o exit (R110);
# - --no-renames do diff árvore a árvore (changed.t): o diff da working tree (changed.d, com --no-renames e mutante próprio)
#   já lista a renomeação commitada como deleção + adição;
# - unset CDPATH e abs_dir (./ no cd relativo) são duas camadas do mesmo controle (F41): cada uma sozinha basta, então o
#   mutante 'CDPATH herdado desvia os cd' remove as duas juntas.
# - a recusa de destino existente na quarentena (SEC-054) é defesa em profundidade: com o número por item e o diretório
#   novo por execução (mkdir sem -p), o destino nunca existe — o mutante 'quarentena hierárquica' a remove junto.
# Sem mutante textual: o casamento de manifestos em lote (F29/SEC-049) é coberto pelo caso de volume (20 000 arquivos
# em menos de 5 s); o mutante da seleção com regex (F39) só morre onde há busybox awk; os mutantes de attr.tree (R109)
# só morrem com git ≥ 2.42 (a suíte pula os casos sem attr.tree).

[ "$SURVIVED" -eq 0 ]

#!/bin/sh
# DotAgents verify — verificação determinística das memórias e do diff (skill compound § 2 e § 5).
# Rode na raiz do escopo DotAgents (diretório com memories/) ou na raiz do repositório git.
# Uso:
#   dotagents-verify.sh lint                    valida memórias e INDEX (nada é executado)
#   dotagents-verify.sh list                    entradas ativas: arquivo, título, Tipo, Escopo, Regra, Verify-Cmd, Origem
#   dotagents-verify.sh fragments [path...]     fragmentos ativos para os paths dados (padrão: arquivos do diff)
#   dotagents-verify.sh diff                    review/self-review: fragmentos ativos + Verify-Cmd aplicáveis ao diff
#   dotagents-verify.sh run "<título>"          baseline de uma entrada (N/A: nada a executar)
#   dotagents-verify.sh probe "<título>" <arq>  contraprova: a entrada detecta a violação contida em <arq> ([A-Za-z0-9_./-])?
#   dotagents-verify.sh base                    commit merge-base entre HEAD e a branch padrão
#   dotagents-verify.sh paths [-z]              arquivos regulares existentes tocados pelo diff
#   dotagents-verify.sh deps [-z]               manifestos e lockfiles tocados pelo diff (inclui deletados)
#   dotagents-verify.sh deps-revert             reverte manifestos e lockfiles do diff à versão do merge-base
# Saída: tabelas e listas no stdout; ⚠️ e 🚨 no stderr (para colar tudo num artefato, use 2>&1).
# Exit: 0 conforme · 1 violação (ou contraprova não detecta) · 2 uso inválido · 3 🚨 bloqueio (pré-condição, gramática, git, ferramenta, erro de comando, timeout).
# Ambiente: DOTAGENTS_VERIFY_TIMEOUT (segundos, padrão 60) · DOTAGENTS_BASE_BRANCH (branch padrão, antes de origin/HEAD, main, master).
set -u
TAB=$(printf '\t')
IFS=$(printf ' \t\n_')
IFS=${IFS%_}
LC_ALL=C
export LC_ALL
unset GREP_OPTIONS GREP_COLOR GREP_COLORS RIPGREP_CONFIG_PATH

strip_controls() { tr -d '\000-\010\013-\037\177'; }
usage() { sed -n '4,17p' "$0" | sed 's/^# //' >&2; exit 2; }
warn() { printf '⚠️ %s\n' "$*" | strip_controls >&2; WARNINGS=$((WARNINGS + 1)); }
die() { printf '🚨 %s\n' "$*" | strip_controls >&2; exit 3; }
fail() { printf '🚨 %s\n' "$*" | strip_controls >&2; ERRORS=1; }
WARNINGS=0
ERRORS=0
VIOLATIONS=0

MODE=${1:-}
[ $# -gt 0 ] && shift
case $MODE in
  lint|list|fragments|diff|run|probe|base|paths|deps|deps-revert) ;;
  *) usage ;;
esac

TIMEOUT=${DOTAGENTS_VERIFY_TIMEOUT:-60}
case $TIMEOUT in
  ''|0*|*[!0-9]*) die "DOTAGENTS_VERIFY_TIMEOUT inválido ($TIMEOUT): inteiro ≥ 1, sem zero à esquerda" ;;
esac
TMP=$(mktemp -d 2>/dev/null) || die "mktemp -d falhou"
trap 'rm -rf "$TMP"' EXIT
trap 'exit 3' INT TERM HUP
ROOT=$(pwd -P)

# ---------------------------------------------------------------- gramática (compound § 2)
Q="'"
QUOTED="$Q[^$Q\`]*$Q"
PATH_SEG0='\.?[A-Za-z0-9_][A-Za-z0-9_.*-]*'
PATH_SEG='(\.[A-Za-z0-9_]|[A-Za-z0-9_*])[A-Za-z0-9_.*-]*'
VPATH="$PATH_SEG0(/$PATH_SEG)*/?"
TAIL='(; test \$\? -eq 1)?'
FORM_RG="rg --no-config -q( -[iFwU]| -g $QUOTED| -t [a-z0-9]+)* -e $QUOTED( $VPATH)+$TAIL"
FORM_GREP="grep -rq[EF]( -[iw])* -e $QUOTED( $VPATH)+$TAIL"
FORM_TEST="test( !)? -e $Q$VPATH$Q"
RE_EXEC="^- \*\*Verify-Cmd:\*\* \`($FORM_RG|$FORM_GREP|$FORM_TEST)\`\$"
RE_NA_BARE='^- \*\*Verify-Cmd:\*\* `N/A`$'
RE_NA_REASON="^- \*\*Verify-Cmd:\*\* \`N/A — [^\`\$;&|<>\\\\$Q\"]+\`\$"
GLOB_SEG='(\.[A-Za-z0-9_*?-]|[A-Za-z0-9_*?-])[A-Za-z0-9_.*?-]*'
GLOB="$GLOB_SEG(/$GLOB_SEG)*"
RE_GLOBS="^$GLOB(, $GLOB)*\$"
DATE='[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
RE_TITLE="^\\[$DATE\\]\\[(Task [0-9]+|bootstrap)\\] [^ ]"
RE_INDEX_DATE="^\\[$DATE\\]\$"
RE_TIPO='^- \*\*Tipo:\*\* `(DOMINIO|ARQUITETURA|PADRAO_VERIFICAVEL|PADRAO_SEMANTICO)`$'
RE_ESCOPO="^- \*\*Escopo \(globs\):\*\* \`$GLOB(, $GLOB)*\`\$"
RE_REGRA='^- \*\*Regra:\*\* (SE .+ ENTÃO .+|NUNCA .+|SEMPRE .+)$'
RE_ORIGEM='^- \*\*Origem:\*\* `(docs/done/[0-9]{3}-[a-z0-9-]+/|bootstrap)`$'

NL='
'
matches() { case $2 in *"$NL"*) return 1 ;; esac; printf '%s\n' "$2" | grep -Eq -- "$1"; }
escape_pipe() { printf '%s' "$1" | sed 's/|/\\|/g'; }
count_lines() { echo $(( $(wc -l < "$1") )); }

# ---------------------------------------------------------------- git: merge-base e arquivos do diff
require_repo_root() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "não é um repositório git: $ROOT"
  [ -d memories ] && return 0
  top=$(git rev-parse --show-toplevel 2>/dev/null) || die "git rev-parse --show-toplevel falhou"
  [ "$(cd "$top" && pwd -P)" = "$ROOT" ] || die "rode na raiz do escopo DotAgents (com memories/) ou na raiz do repositório"
}

resolve_merge_base() {
  require_repo_root
  # refs completos: uma tag ou ref homônimo vindo do remoto nunca sombreia a branch
  candidates="refs/remotes/origin/HEAD refs/heads/main refs/heads/master"
  if [ -n "${DOTAGENTS_BASE_BRANCH:-}" ]; then
    matches '^[A-Za-z0-9][A-Za-z0-9._/-]*$' "$DOTAGENTS_BASE_BRANCH" || die "DOTAGENTS_BASE_BRANCH inválido: $DOTAGENTS_BASE_BRANCH"
    candidates="refs/heads/$DOTAGENTS_BASE_BRANCH refs/remotes/$DOTAGENTS_BASE_BRANCH"
  fi
  base_ref=""
  for ref in $candidates; do
    git rev-parse --verify -q "$ref^{commit}" >/dev/null 2>&1 && { base_ref=$ref; break; }
  done
  [ -n "$base_ref" ] || die "branch padrão não resolvida ($candidates) — defina DOTAGENTS_BASE_BRANCH"
  MERGE_BASE=$(git merge-base HEAD "$base_ref" 2>/dev/null) || die "sem merge-base entre HEAD e $base_ref"
  self_check
}

# rejeita nomes com quebra de linha ou caractere de controle (listas NUL do git)
check_names() {
  [ "$(( $(cat "$@" | tr -cd '\n' | wc -c) ))" -eq 0 ] || die "path com quebra de linha no repositório — renomeie o arquivo"
  if cat "$@" | tr '\0' '\n' | grep -q '[[:cntrl:]]'; then die "path com caractere de controle no repositório — renomeie o arquivo"; fi
}

# o verificador em execução, quando está dentro do repositório, precisa ser idêntico ao do merge-base
# (cópia fora do repositório — ex.: a versão do merge-base extraída para revisão — não se checa)
self_check() {
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  top=$(cd "$top" && pwd -P)
  script="$(cd "$(dirname "$0")" && pwd -P)/${0##*/}"
  case $script in "$top"/*) ;; *) return 0 ;; esac
  relative=${script#"$top"/}
  if git cat-file -e "$MERGE_BASE:$relative" 2>/dev/null; then
    git diff --quiet "$MERGE_BASE" -- "$script" 2>/dev/null && return 0
    die "o verificador em execução ($relative) difere do merge-base — rode a versão do merge-base: git show $MERGE_BASE:$relative > <arquivo fora do repo> && sh <arquivo> $MODE (skill compound § 5)"
  fi
  warn "verificador em execução ($relative) sem versão no merge-base (instalação da squad nesta branch) — revise o script manualmente (skill compound § 5)"
}

compute_changes() {
  resolve_merge_base
  git diff --name-only -z --no-renames --relative "$MERGE_BASE" > "$TMP/changed.d" || die "git diff $MERGE_BASE falhou"
  git ls-files -z --others --exclude-standard > "$TMP/changed.u" || die "git ls-files falhou"
  check_names "$TMP/changed.d" "$TMP/changed.u"
  cat "$TMP/changed.d" "$TMP/changed.u" | tr '\0' '\n' | sort -u > "$TMP/changed"
}

# exit 1 se algum diretório do caminho é symlink (ex.: diretório versionado substituído por link para fora do repo)
crosses_symlink() {
  dir=$1
  while :; do
    case $dir in */*) dir=${dir%/*} ;; *) return 1 ;; esac
    [ -L "$dir" ] && return 0
  done
}

emit() { if [ "$NUL_OUTPUT" = 1 ]; then printf '%s\0' "$1"; else printf '%s\n' "$1"; fi; }

# mesma tabela da skill dependency-lock § 1
is_dependency_file() {
  case ${1##*/} in
    package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|pyproject.toml|Pipfile|poetry.lock|Pipfile.lock|requirements.in|requirements.txt|go.mod|go.sum|Cargo.toml|Cargo.lock|pom.xml|Gemfile|Gemfile.lock) return 0 ;;
  esac
  return 1
}

NUL_OUTPUT=0
case $MODE in
  base)
    [ $# -eq 0 ] || usage
    resolve_merge_base
    printf '%s\n' "$MERGE_BASE"
    exit 0 ;;
  paths|deps)
    case $# in 0) ;; 1) [ "$1" = -z ] || usage; NUL_OUTPUT=1 ;; *) usage ;; esac
    compute_changes
    while IFS= read -r path; do
      if [ "$MODE" = paths ]; then
        # arquivo regular, sem symlink nem diretório-pai que virou symlink (que levaria a leitura para fora do repo)
        [ -f "$path" ] && [ ! -L "$path" ] && ! crosses_symlink "$path" && emit "$path"
      else
        is_dependency_file "$path" && emit "$path"
      fi
    done < "$TMP/changed"
    exit 0 ;;
  deps-revert)
    [ $# -eq 0 ] || usage
    compute_changes
    reverted=0
    while IFS= read -r path; do
      is_dependency_file "$path" || continue
      crosses_symlink "$path" && die "manifesto sob diretório que virou symlink — revert manual: $path"
      reverted=$((reverted + 1))
      if git cat-file -e "$MERGE_BASE:./$path" 2>/dev/null; then
        GIT_LITERAL_PATHSPECS=1 git checkout -q "$MERGE_BASE" -- "$path" || die "git checkout falhou: $path"
        printf 'revertido ao merge-base: %s\n' "$path"
      else
        GIT_LITERAL_PATHSPECS=1 git rm -q -f --cached --ignore-unmatch -- "$path" || die "git rm falhou: $path"
        rm -f -- "./$path" || die "rm falhou: $path"
        printf 'removido (ausente no merge-base): %s\n' "$path"
      fi
    done < "$TMP/changed"
    [ "$reverted" -eq 0 ] && printf 'nenhum manifesto ou lockfile no diff\n'
    exit 0 ;;
esac

# ---------------------------------------------------------------- memórias: pré-condições e listagem
[ -d memories ] || die "memories/ ausente — rode na raiz do escopo DotAgents"
find memories ! -type f ! -type d > "$TMP/special" || die "find falhou em memories/"
[ -s "$TMP/special" ] && die "memories/ contém symlink ou arquivo especial: $(tr '\n' ' ' < "$TMP/special")"
find memories > "$TMP/all" || die "find falhou em memories/"
grep -v '^[A-Za-z0-9_./-]*$' "$TMP/all" > "$TMP/badname"
[ -s "$TMP/badname" ] && die "nome fora de [A-Za-z0-9_./-] em memories/: $(tr '\n' ' ' < "$TMP/badname")"
find memories -type f -name '*.md' ! -path 'memories/templates/*' | sort > "$TMP/files" || die "find falhou em memories/"
CR=$(printf '\r')
while IFS= read -r file; do
  if grep -q "$CR" "$file"; then die "fim de linha CRLF em $file — converta para LF"; fi
done < "$TMP/files"

# entries: kind · arquivo · título · Tipo · Escopo · Regra · Verify-Cmd · Origem (kind: OK | DUP | ORFA | LEGADA)
: > "$TMP/entries"
while IFS= read -r file; do
  awk -v F="$file" '
    function nz(x) { return x == "" ? "-" : x }
    function flush(   kind) {
      if (title != "" && title !~ /\[SUPERSEDED em [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\]$/) {
        kind = ""
        if (dup) kind = "DUP"
        else if (fields) kind = "OK"
        else if (title ~ /^\[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\]\[/) kind = "LEGADA"
        if (kind != "") print kind "\t" F "\t" title "\t" nz(tipo) "\t" nz(escopo) "\t" nz(regra) "\t" nz(verify) "\t" nz(origem)
      }
      title = ""; tipo = ""; escopo = ""; regra = ""; verify = ""; origem = ""; dup = 0; fields = 0
    }
    function field(current) { if (current != "") dup = 1; fields = 1; return $0 }
    { gsub(/\t/, " "); gsub(/[\001-\010\013-\037\177]/, "?") }
    /^(#|##|###) / { flush() }
    /^### / { title = substr($0, 5); next }
    /^- \*\*Tipo:\*\*/ { tipo = field(tipo); next }
    /^- \*\*Escopo \(globs\):\*\*/ { escopo = field(escopo); next }
    /^- \*\*Regra:\*\*/ { regra = field(regra); next }
    /^- \*\*Verify-Cmd:\*\*/ {
      if (title == "") print "ORFA\t" F "\t(sem título)\t-\t-\t-\t" $0 "\t-"
      else verify = field(verify)
      next
    }
    /^- \*\*Origem:\*\*/ { origem = field(origem); next }
    END { flush() }
  ' "$file" >> "$TMP/entries" || die "awk falhou em $file"
done < "$TMP/files"

# index: arquivo · Globs (LEGADO · * quando há linha fora do formato tabela)
: > "$TMP/index"
if [ -f memories/implementations/INDEX.md ]; then
  awk -F'|' '
    /<!--/ { comment = 1 }
    comment { if (/-->/) comment = 0; next }
    /^\|/ {
      file = $2; globs = $3
      gsub(/^ +| +$/, "", file); gsub(/^ +| +$/, "", globs)
      if (file == "Arquivo" || file ~ /^-+$/) next
      summary = $4; updated = $5
      gsub(/^ +| +$/, "", summary); gsub(/^ +| +$/, "", updated)
      print file "\t" globs "\t" (summary == "" ? "-" : summary) "\t" (updated == "" ? "-" : updated) "\t" NF
      next
    }
    /^[ \t]*$/ || /^#/ { next }
    { print "LEGADO\t*\t-\t-\t6" }
  ' memories/implementations/INDEX.md > "$TMP/index" || die "awk falhou em memories/implementations/INDEX.md"
fi
find memories/implementations -type f -name '*.md' ! -name INDEX.md 2>/dev/null | sort > "$TMP/fragfiles"

# ---------------------------------------------------------------- lint
# oks: "<nome>\t<linha de entries>" para cada campo que casa a regex
check_field() { # $1 coluna · $2 regex · $3 nome
  cut -f"$1" "$TMP/entries" > "$TMP/column"
  grep -nE -- "$2" "$TMP/column" > "$TMP/hits"
  [ $? -le 1 ] || die "grep falhou ao validar $3"
  cut -d: -f1 "$TMP/hits" | sed "s/^/$3$TAB/" >> "$TMP/oks"
}

lint() {
  : > "$TMP/oks"
  check_field 3 "$RE_TITLE" title
  check_field 4 "$RE_TIPO" tipo
  check_field 5 "$RE_ESCOPO" escopo
  check_field 6 "$RE_REGRA" regra
  check_field 7 "$RE_EXEC" exec
  check_field 7 "$RE_NA_BARE" na_bare
  check_field 7 "$RE_NA_REASON" na_reason
  check_field 8 "$RE_ORIGEM" origem
  awk -F'\t' '
    function err(msg) { print "E\t" msg ": " loc }
    function norm(s) { s = tolower(s); gsub(/  +/, " ", s); return s }
    function expected_type(file,   name) {
      if (file == "memories/business.md") return "DOMINIO"
      if (file == "memories/architecture.md") return "ARQUITETURA"
      if (file == "memories/guidelines.md") return "PADRAO_"
      name = file; sub(/^.*\//, "", name); sub(/(-[0-9]+)?\.md$/, "", name)
      if (name ~ /-dominio$/) return "DOMINIO"
      if (name ~ /-arquitetura$/) return "ARQUITETURA"
      if (name ~ /-padrao-verificavel$/) return "PADRAO_VERIFICAVEL"
      if (name ~ /-padrao-semantico$/) return "PADRAO_SEMANTICO"
      return "?"
    }
    FILENAME == ARGV[1] { ok[$1, $2] = 1; next }
    {
      n = FNR; loc = $2 " › " $3
      if ($1 == "LEGADA") { print "W\tentrada legada sem campos canônicos (não executável): " loc; next }
      if ($1 == "DUP") { err("campo repetido na entrada"); next }
      if ($1 == "ORFA") { err("Verify-Cmd fora de uma entrada"); next }
      if (!ok["title", n]) err("título sem [AAAA-MM-DD][Task NNN] ou [AAAA-MM-DD][bootstrap]")
      if (!ok["tipo", n]) err("Tipo inválido ou ausente")
      else {
        want = expected_type($2)
        if (want == "?") err("fragmento fora da nomeação <segmento>-<tipo>[-N].md")
        else if (index($4, "`" want) == 0) err("Tipo incompatível com o arquivo de destino (esperado " want ")")
      }
      if (!ok["escopo", n]) err("Escopo (globs) inválido ou ausente (globs relativos, sem ./, / inicial ou .., separados por \", \")")
      if (!ok["regra", n]) err("Regra ausente ou fora do formato SE … ENTÃO … | NUNCA … | SEMPRE …")
      if (!ok["origem", n]) err("Origem ausente ou fora do formato docs/done/NNN-slug/ | bootstrap")
      if (!ok["exec", n] && !ok["na_bare", n] && !ok["na_reason", n]) err("Verify-Cmd fora da gramática (não executável)")
      else if ($4 ~ /`DOMINIO`/ && !ok["na_bare", n]) err("DOMINIO exige Verify-Cmd `N/A`")
      else if ($4 ~ /`PADRAO_VERIFICAVEL`/ && !ok["exec", n]) err("PADRAO_VERIFICAVEL exige Verify-Cmd executável")
      else if ($4 ~ /`(PADRAO_SEMANTICO|ARQUITETURA)`/ && ok["na_bare", n]) err("N/A sem motivo: use `N/A — <motivo>`")
      if (ok["escopo", n]) {
        globs = $5; sub(/^[^`]*`/, "", globs); sub(/`$/, "", globs)
        k = split(globs, g, ", ")
        for (i = 2; i <= k; i++) if (("" g[i]) <= ("" g[i - 1])) { err("Escopo fora da ordem lexicográfica (LC_ALL=C) ou com glob repetido"); break }
      }
      key = $5 SUBSEP $4 SUBSEP norm($6)
      if (key in seen) err("entrada duplicada (mesmo Escopo, Tipo e Regra) de " seen[key])
      else seen[key] = loc
    }
  ' "$TMP/oks" "$TMP/entries" > "$TMP/lint" || die "awk falhou no lint"

  awk -F'\t' '
    FILENAME == ARGV[1] { row[$1] = $2; if ($1 == "LEGADO") legacy = 1; next }
    FILENAME == ARGV[2] { name = $0; sub(/^.*\//, "", name); frag[name] = 1; next }
    $1 == "OK" && $2 ~ /^memories\/implementations\// {
      name = $2; sub(/^.*\//, "", name)
      if (!(name in row)) next
      globs = $5; sub(/^[^`]*`/, "", globs); sub(/`$/, "", globs)
      k = split(globs, g, ", "); m = split(row[name], r, ", ")
      for (i = 1; i <= k; i++) {
        found = 0
        for (j = 1; j <= m; j++) if (g[i] == r[j]) found = 1
        if (!found) print "E\tEscopo da entrada fora dos Globs do INDEX (" g[i] "): " $2 " › " $3
      }
    }
    END {
      for (name in frag) if (!(name in row)) {
        if (legacy) print "W\tfragmento sem linha no INDEX (INDEX legado): " name
        else print "E\tfragmento sem linha no INDEX: " name
      }
      if (legacy) print "W\tINDEX legado: todos os fragmentos tratados como ativos (*) — o compound converte na próxima escrita"
    }
  ' "$TMP/index" "$TMP/fragfiles" "$TMP/entries" >> "$TMP/lint" || die "awk falhou no lint do INDEX"

  : > "$TMP/index.seen"
  while IFS="$TAB" read -r file globs summary updated columns; do
    [ "$file" = LEGADO ] && continue
    if ! matches '^[A-Za-z0-9_.-]+\.md$' "$file" || [ ! -f "memories/implementations/$file" ]; then
      printf 'E\tINDEX aponta fragmento inexistente ou inválido: %s\n' "$file" >> "$TMP/lint"
    fi
    grep -qxF -- "$file" "$TMP/index.seen" && printf 'E\tfragmento em mais de uma linha do INDEX: %s\n' "$file" >> "$TMP/lint"
    printf '%s\n' "$file" >> "$TMP/index.seen"
    [ "$columns" = 6 ] || printf 'E\tlinha do INDEX fora do formato | arquivo | globs | resumo | [AAAA-MM-DD] |: %s\n' "$file" >> "$TMP/lint"
    matches "$RE_GLOBS" "$globs" || printf 'E\tINDEX com Globs fora da gramática: %s\n' "$file" >> "$TMP/lint"
    [ "$summary" != - ] || printf 'E\tINDEX sem resumo: %s\n' "$file" >> "$TMP/lint"
    matches "$RE_INDEX_DATE" "$updated" || printf 'E\tINDEX com data fora do formato [AAAA-MM-DD]: %s\n' "$file" >> "$TMP/lint"
  done < "$TMP/index"

  while IFS="$TAB" read -r level message; do
    if [ "$level" = E ]; then fail "$message"; else warn "$message"; fi
  done < "$TMP/lint"
}

# ---------------------------------------------------------------- ativação por glob (compound § 5)
globs_match() { # $1 globs separados por ", " · lê $TMP/changed · exit 0 se algum glob casa algum path (* = sempre)
  awk -v G="$1" '
    function to_regex(glob,   re, i, c, n) {
      re = "^"; n = length(glob)
      for (i = 1; i <= n; i++) {
        c = substr(glob, i, 1)
        if (c == "*") {
          if (substr(glob, i + 1, 1) == "*") {
            if (substr(glob, i + 2, 1) == "/") { re = re "(.*/)?"; i += 2 } else { re = re ".*"; i++ }
          } else re = re "[^/]*"
        } else if (c == "?") re = re "[^/]"
        else if (c == ".") re = re "\\."
        else re = re c
      }
      return re "$"
    }
    BEGIN {
      n = split(G, glob, ", ")
      for (i = 1; i <= n; i++) { if (glob[i] == "*") always = 1; re[i] = to_regex(glob[i]) }
      if (always) exit 0
    }
    { for (i = 1; i <= n; i++) if ($0 ~ re[i]) { found = 1; exit } }
    END { exit (always || found) ? 0 : 1 }
  ' "$TMP/changed"
}

active_fragments() {
  : > "$TMP/active"
  grep -q '^LEGADO' "$TMP/index" && cat "$TMP/fragfiles" >> "$TMP/active"
  while IFS="$TAB" read -r file globs summary updated columns; do
    [ "$file" = LEGADO ] && continue
    globs_match "$globs" && printf 'memories/implementations/%s\n' "$file" >> "$TMP/active"
  done < "$TMP/index"
  sort -u "$TMP/active" -o "$TMP/active"
  if [ -s "$TMP/active" ]; then
    while IFS= read -r file; do printf 'FRAGMENTO ATIVO: %s\n' "$file"; done < "$TMP/active"
  else
    printf 'FRAGMENTOS ATIVOS: nenhum\n'
  fi
}

# ---------------------------------------------------------------- execução no snapshot (só arquivos visíveis ao git, sem symlinks)
make_snapshot() {
  SNAPSHOT="$TMP/snapshot"
  top=$(git rev-parse --show-toplevel 2>/dev/null) || die "git rev-parse --show-toplevel falhou"
  prefix=$(git rev-parse --show-prefix 2>/dev/null) || die "git rev-parse --show-prefix falhou"
  objects=$(cd "$(git rev-parse --git-path objects)" && pwd -P) || die "diretório de objetos do git não encontrado"
  index=$(git rev-parse --git-path index) || die "git rev-parse --git-path index falhou"
  mkdir "$SNAPSHOT" "$TMP/objects" || die "mkdir do snapshot falhou"
  [ -f "$index" ] && { cp "$index" "$TMP/index" || die "cópia do índice falhou"; }
  # índice e objetos temporários: o .git do repositório não é alterado; nomes nunca passam por shell nem tar
  (
    cd "$top" || exit 1
    export GIT_INDEX_FILE="$TMP/index" GIT_OBJECT_DIRECTORY="$TMP/objects" GIT_ALTERNATE_OBJECT_DIRECTORIES="$objects" GIT_LFS_SKIP_SMUDGE=1
    git add -A -- . && git checkout-index -a -f --prefix="$SNAPSHOT/"
  ) >/dev/null 2>"$TMP/snapshot.err" || die "montagem do snapshot falhou: $(head -c 200 "$TMP/snapshot.err")"
  find "$SNAPSHOT" -type l -exec rm -f {} + || die "remoção de symlinks do snapshot falhou"
  SNAPSHOT_SCOPE="$SNAPSHOT/$prefix"
  mkdir -p "$SNAPSHOT_SCOPE" || die "mkdir do escopo no snapshot falhou"
}

check_timeout_tool() {
  command -v timeout >/dev/null 2>&1 && { HAS_TIMEOUT=1; return; }
  HAS_TIMEOUT=0
  warn "utilitário timeout ausente — execução sem limite de tempo"
}

with_timeout() { if [ "$HAS_TIMEOUT" = 1 ]; then timeout "$TIMEOUT" "$@"; else "$@"; fi; }

# rg roda sem filtros de ignore, ocultos ou binários: no snapshot, nada visível ao git escapa da busca
executed_form() { case $1 in "rg --no-config "*) printf 'rg --no-config -uuu %s' "${1#rg --no-config }" ;; *) printf '%s' "$1" ;; esac; }

# interpreta o exit bruto da busca: 0 casou · 1 não casou · ≥ 2 erro do comando (🚨, nunca violação)
search_outcome() { # $1 forma executada · $2 exit bruto → conform | violation | error
  case $1 in
    test*) [ "$2" -eq 0 ] && echo conform || echo violation ;;
    *'; test $? -eq 1')
      case $2 in 1) echo conform ;; 0) echo violation ;; *) echo error ;; esac ;;
    *)
      case $2 in 0) echo conform ;; 1) echo violation ;; *) echo error ;; esac ;;
  esac
}

prepare_command() { # $1 linha do Verify-Cmd → COMMAND (forma executada) · exit 1 se a ferramenta não existe
  COMMAND=${1#*\`}
  COMMAND=$(executed_form "${COMMAND%\`}")
  command -v "${COMMAND%% *}" >/dev/null 2>&1
}

run_entry() { # $1 arquivo · $2 título · $3 linha do Verify-Cmd
  prepare_command "$3" || { fail "comando indisponível (${COMMAND%% *}): $1 › $2 — instale ripgrep ou use a forma grep"; return; }
  command_text=$COMMAND
  search=${command_text%'; test $? -eq 1'}
  (cd "$SNAPSHOT_SCOPE" && with_timeout sh -c "$search") </dev/null >/dev/null 2>"$TMP/cmd.err"
  raw=$?
  if [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ]; then
    outcome=timeout
  else
    outcome=$(search_outcome "$command_text" "$raw")
  fi
  case $outcome in conform) rc=0 ;; violation) rc=1 ;; *) rc=3 ;; esac
  printf '| %s › %s | `%s` | %s |\n' "$1" "$(escape_pipe "$2")" "$(escape_pipe "$command_text")" "$rc"
  case $outcome in
    violation) VIOLATIONS=1 ;;
    timeout) fail "timeout (${TIMEOUT} s): $1 › $2" ;;
    error) fail "erro do comando (exit $raw): $1 › $2 — $(head -c 300 "$TMP/cmd.err" | strip_controls)" ;;
  esac
}

is_na() { case $1 in '- **Verify-Cmd:** `N/A'*) return 0 ;; esac; return 1; }

select_entry() { # $1 título → e_* da entrada
  TITLE=$1 awk -F'\t' '$1 == "OK" && $3 == ENVIRON["TITLE"]' "$TMP/entries" > "$TMP/selected"
  [ "$(count_lines "$TMP/selected")" -eq 1 ] || die "título não encontrado ou ambíguo: $1"
  IFS="$TAB" read -r e_kind e_file e_title e_tipo e_escopo e_regra e_verify e_origem < "$TMP/selected"
}

TABLE_HEADER='| Entrada (arquivo › título) | Comando | Exit |
|---|---|---|'

# ---------------------------------------------------------------- dispatch dos modos de memória
lint
if [ "$MODE" = lint ]; then
  [ "$ERRORS" -eq 0 ] || exit 3
  if [ "$WARNINGS" -eq 0 ]; then printf '✅ memórias conformes à gramática\n'; else printf '✅ memórias conformes à gramática (%s aviso(s) ⚠️)\n' "$WARNINGS"; fi
  exit 0
fi
[ "$ERRORS" -eq 0 ] || die "lint reprovado — nada foi executado"

case $MODE in
  list)
    [ $# -eq 0 ] || usage
    awk -F'\t' -v OFS='\t' '$1 == "OK" { print $2, $3, $4, $5, $6, $7, $8 }' "$TMP/entries"
    exit 0 ;;
  fragments)
    if [ $# -gt 0 ]; then
      for path in "$@"; do path=${path%,}; printf '%s\n' "${path#./}"; done > "$TMP/changed"
    else
      compute_changes
    fi
    active_fragments
    exit 0 ;;
  diff)
    [ $# -eq 0 ] || usage
    compute_changes
    git diff -U0 --no-renames "$MERGE_BASE" -- memories > "$TMP/memdiff" || die "git diff de memories/ falhou"
    sed -n 's/^+### \(.*\[SUPERSEDED em [0-9-]*\]\)$/\1/p' "$TMP/memdiff" > "$TMP/superseded"
    while IFS= read -r title; do
      warn "entrada desativada neste diff (SUPERSEDED): $title — confirme a entrada substituta"
    done < "$TMP/superseded"
    grep -E '^-(### |- \*\*(Tipo|Escopo \(globs\)|Verify-Cmd):\*\*)' "$TMP/memdiff" > "$TMP/weakened"
    while IFS= read -r line; do
      warn "entrada removida ou alterada neste diff: ${line#-} — confirme que a regra não foi enfraquecida"
    done < "$TMP/weakened"
    active_fragments
    : > "$TMP/applicable"
    while IFS="$TAB" read -r e_kind e_file e_title e_tipo e_escopo e_regra e_verify e_origem; do
      [ "$e_kind" = OK ] || continue
      is_na "$e_verify" && continue
      case $e_file in
        memories/guidelines.md|memories/architecture.md) ;;
        *) grep -qxF -- "$e_file" "$TMP/active" || continue ;;
      esac
      globs=${e_escopo#*\`}
      globs_match "${globs%\`}" || continue
      printf '%s\t%s\t%s\n' "$e_file" "$e_title" "$e_verify" >> "$TMP/applicable"
    done < "$TMP/entries"
    printf '%s\n' "$TABLE_HEADER"
    if [ ! -s "$TMP/applicable" ]; then
      printf '| — | nenhum Verify-Cmd aplicável | — |\n'
    else
      check_timeout_tool
      make_snapshot
      while IFS="$TAB" read -r e_file e_title e_verify; do
        run_entry "$e_file" "$e_title" "$e_verify"
      done < "$TMP/applicable"
    fi ;;
  run)
    [ $# -eq 1 ] || usage
    select_entry "$1"
    if is_na "$e_verify"; then printf 'N/A: nada a executar (%s)\n' "$e_title"; exit 0; fi
    resolve_merge_base
    check_timeout_tool
    make_snapshot
    printf '%s\n' "$TABLE_HEADER"
    run_entry "$e_file" "$e_title" "$e_verify" ;;
  probe)
    [ $# -eq 2 ] || usage
    select_entry "$1"
    if is_na "$e_verify"; then printf 'N/A: contraprova não se aplica (%s)\n' "$e_title"; exit 0; fi
    resolve_merge_base
    tool_found=1
    prepare_command "$e_verify" || tool_found=0
    command_text=$COMMAND
    case $command_text in test*) printf 'forma Estrutural: contraprova N/A (%s)\n' "$e_title"; exit 0 ;; esac
    if ! matches '^[A-Za-z0-9_./][A-Za-z0-9_./-]*$' "$2" || [ ! -f "$2" ] || [ -L "$2" ]; then
      die "arquivo de contraprova inválido, ausente ou symlink: $2"
    fi
    [ "$tool_found" = 1 ] || die "comando indisponível (${command_text%% *}) — instale ripgrep ou use a forma grep"
    check_timeout_tool
    pattern_part=$(printf '%s' "$command_text" | sed "s/^\(.* -e '[^']*'\) .*/\1/")
    with_timeout sh -c "$pattern_part \"\$1\"" sh "$2" </dev/null >/dev/null 2>"$TMP/cmd.err"
    raw=$?
    [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na contraprova: $e_title"
    [ "$raw" -ge 2 ] && die "erro do comando na contraprova (exit $raw): $(head -c 300 "$TMP/cmd.err" | strip_controls)"
    # Proibição: o trecho violador contém o padrão (exit 0) · Presença: o trecho violador não o contém (exit 1)
    case $command_text in *'; test $? -eq 1') detected=0 ;; *) detected=1 ;; esac
    if [ "$raw" -eq "$detected" ]; then
      printf '✅ contraprova: a entrada detecta a violação contida em %s\n' "$2"
      exit 0
    fi
    printf '❌ contraprova: a entrada NÃO detecta a violação contida em %s\n' "$2"
    exit 1 ;;
esac

[ "$ERRORS" -ne 0 ] && exit 3
[ "$VIOLATIONS" -ne 0 ] && exit 1
exit 0

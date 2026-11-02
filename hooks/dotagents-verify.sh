#!/bin/sh
# DotAgents verify — verificação determinística das memórias e do diff (skill compound § 2 e § 5).
# Rode na raiz do escopo DotAgents (diretório com memories/) ou na raiz do repositório git.
# Uso:
#   dotagents-verify.sh lint                    valida memórias e INDEX (nada é executado)
#   dotagents-verify.sh list                    entradas ativas: arquivo, título, Tipo, Escopo, Regra, Verify-Cmd, Origem
#   dotagents-verify.sh fragments [path...]     fragmentos ativos para os paths dados (padrão: arquivos do diff)
#   dotagents-verify.sh diff [--review]         fragmentos ativos + Verify-Cmd do diff (--review: branch commitada, worktree limpo)
#   dotagents-verify.sh run "<título>"          baseline de uma entrada (N/A: nada a executar)
#   dotagents-verify.sh probe "<título>" <arq>  contraprova: a entrada detecta a violação contida em <arq> ([A-Za-z0-9_./-])?
#   dotagents-verify.sh base                    commit merge-base entre HEAD e a branch padrão
#   dotagents-verify.sh paths [-z]              arquivos regulares existentes tocados pelo diff
#   dotagents-verify.sh deps [-z]               manifestos e lockfiles tocados pelo diff (inclui deletados)
#   dotagents-verify.sh deps-revert             reverte manifestos e lockfiles do diff ao merge-base (versão local → quarentena)
# Saída: tabelas e listas no stdout; ⚠️ e 🚨 no stderr (para colar tudo num artefato, use 2>&1).
# Exit: 0 conforme · 1 violação (ou contraprova não detecta) · 2 uso inválido · 3 🚨 bloqueio (pré-condição, gramática, git, ferramenta, erro de comando, timeout).
# Ambiente: DOTAGENTS_VERIFY_TIMEOUT (segundos, padrão 60) · DOTAGENTS_BASE_BRANCH (branch padrão; substitui origin/HEAD, main e master).
set -u
TAB=$(printf '\t')
IFS=$(printf ' \t\n_')
IFS=${IFS%_}
LC_ALL=C
export LC_ALL
# GIT_ATTR_SOURCE (e a config attr.tree, neutralizada com ATTR_HERE nos comandos que leem atributos) fariam o git ler
# atributos de outra árvore que não a working tree verificada; CDPATH desviaria (e imprimiria) o cd de um caminho relativo
unset GREP_OPTIONS GREP_COLOR GREP_COLORS RIPGREP_CONFIG_PATH GIT_ATTR_SOURCE CDPATH
ATTR_HERE='-c attr.tree='

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
# timeout: Verify-Cmd, checagem de checkout e montagem do snapshot
HAS_TIMEOUT=0
command -v timeout >/dev/null 2>&1 && HAS_TIMEOUT=1
with_timeout() { if [ "$HAS_TIMEOUT" = 1 ]; then timeout "$TIMEOUT" "$@"; else "$@"; fi; }
# cmp: autoverificação do verificador (todos os modos) e checagem de byte NUL nas memórias
command -v cmp >/dev/null 2>&1 || die "comando indisponível (cmp) — necessário para a autoverificação do verificador e a validação das memórias"
# od: BOM UTF-16/32 (checagem de checkout velho e arquivos verificados) — sem ele a checagem se desligaria em silêncio
command -v od >/dev/null 2>&1 || die "comando indisponível (od) — necessário para a checagem de BOM UTF-16/32"
# caminho absoluto de um diretório; o relativo ganha ./ (cd de "./x" nunca consulta CDPATH)
abs_dir() { case $1 in /*) (cd -P -- "$1" && pwd -P) ;; *) (cd -P -- "./$1" && pwd -P) ;; esac; }
TMP=$(mktemp -d 2>/dev/null) || die "mktemp -d falhou"
# chmod antes do rm: diretório sem permissão de escrita criado no snapshot não deixa o temporário para trás
trap 'chmod -R u+rwX "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
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
  [ "$(abs_dir "$top")" = "$ROOT" ] || die "rode na raiz do escopo DotAgents (com memories/) ou na raiz do repositório"
}

resolve_merge_base() {
  require_repo_root
  # refs completos: uma tag ou ref homônimo vindo do remoto nunca sombreia a branch
  candidates="refs/heads/main refs/heads/master"
  # origin/HEAD só vale como symref (o apontamento do remoto); uma branch remota chamada HEAD vira ref comum e é ignorada
  origin_head=$(git symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null) && candidates="$origin_head $candidates"
  if [ -n "${DOTAGENTS_BASE_BRANCH:-}" ]; then
    matches '^[A-Za-z0-9][A-Za-z0-9._/-]*$' "$DOTAGENTS_BASE_BRANCH" || die "DOTAGENTS_BASE_BRANCH inválido: $DOTAGENTS_BASE_BRANCH"
    # <remoto>/HEAD por nome é um ref comum (qualquer push cria refs/heads/HEAD): o apontamento do remoto só vale como symref
    case /$DOTAGENTS_BASE_BRANCH in */HEAD) die "DOTAGENTS_BASE_BRANCH não pode terminar em HEAD ($DOTAGENTS_BASE_BRANCH) — use o nome da branch, ex.: origin/main" ;; esac
    # branch remota antes da local: origin/main resolve o mesmo ref da checagem externa (compound § 5), mesmo com uma
    # branch local chamada origin/main
    candidates="refs/remotes/$DOTAGENTS_BASE_BRANCH refs/heads/$DOTAGENTS_BASE_BRANCH"
  fi
  base_ref=""
  for ref in $candidates; do
    # show-ref --verify exige o ref completo exato: uma tag chamada "refs/heads/main" não o satisfaz
    git show-ref --verify -q "$ref" && git rev-parse --verify -q "$ref^{commit}" >/dev/null 2>&1 && { base_ref=$ref; break; }
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

# exit 0 se o verificador em execução está dentro do repositório git atual
# define VERIFIER_PATH (caminho absoluto do script) e VERIFIER_RELATIVE (relativo à raiz do repositório)
verifier_inside_repo() {
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  top=$(abs_dir "$top") || return 1
  VERIFIER_PATH="$(abs_dir "$(dirname "$0")")/${0##*/}"
  case $VERIFIER_PATH in "$top"/*) VERIFIER_RELATIVE=${VERIFIER_PATH#"$top"/}; return 0 ;; esac
  return 1
}

# o verificador em execução, quando está dentro do repositório, precisa ser idêntico (byte a byte) ao do merge-base
# (cópia fora do repositório — ex.: a versão do merge-base extraída para revisão — não se checa)
SELF_CHECKED=0
self_check() {
  [ "$SELF_CHECKED" = 1 ] && return 0
  SELF_CHECKED=1
  verifier_inside_repo || return 0
  relative=$VERIFIER_RELATIVE
  if git cat-file -e "$MERGE_BASE:$relative" 2>/dev/null; then
    git cat-file blob "$MERGE_BASE:$relative" 2>/dev/null | cmp -s - "$VERIFIER_PATH" && return 0
    die "o verificador em execução ($relative) difere do merge-base — rode a versão do merge-base: git show $MERGE_BASE:$relative > <arquivo fora do repo> && sh <arquivo> $MODE (skill compound § 5)"
  fi
  warn "verificador em execução ($relative) sem versão no merge-base (instalação da squad nesta branch) — revise o script manualmente (skill compound § 5)"
}

# working-tree-encoding transcodifica o arquivo na working tree: lint e busca veriam bytes convertidos.
# Lista NUL (-z): o git não des-cita nome iniciado por aspas. "unset" (-working-tree-encoding) é seguro.
check_encoding() { # $1 lista (um path por linha) · $2 rótulo dos temporários · $3 mensagem do 🚨
  tr '\n' '\0' < "$1" | git $ATTR_HERE check-attr -z --stdin working-tree-encoding > "$TMP/encoding-$2.z" || die "git check-attr falhou"
  tr '\0' '\n' < "$TMP/encoding-$2.z" | awk '
    NR % 3 == 1 { path = $0 }
    NR % 3 == 0 && $0 != "unspecified" && $0 != "unset" { print path ": " $0; exit }
  ' > "$TMP/encoding-$2.set" || die "awk falhou na checagem de working-tree-encoding"
  [ -s "$TMP/encoding-$2.set" ] && die "$3 ($(cat "$TMP/encoding-$2.set"))"
  return 0
}

# classe do BOM pelos 4 primeiros bytes do stdin (UTF-32LE antes de UTF-16LE: fffe0000 começa com fffe) — prefixo dos sh -c
BOM_CLASS='
    bom_class() {
      case $(od -An -tx1 -N4 | tr -d " \n") in
        0000feff*) echo utf32be ;; fffe0000*) echo utf32le ;; fffe*) echo utf16le ;; feff*) echo utf16be ;; *) echo none ;;
      esac
    }'

# arquivos da lista com os bytes FE FF ou FF FE em qualquer posição — superconjunto dos que começam com BOM UTF-16/32
# (00 00 FE FF e FF FE 00 00 contêm o par) —, num grep por lote e sob o timeout
bom_candidates() { # $1 lista (um path por linha, primeiro campo antes de TAB) · $2 saída (um path por linha)
  cut -f1 "$1" | tr '\n' '\0' > "$1.bom.z"
  with_timeout sh -c '
    list=$1; shift
    [ -s "$list" ] || exit 0
    xargs -0 sh -c '\''be=$1 le=$2; shift 2; grep -l -e "$be" -e "$le" -- "$@"; [ $? -le 1 ]'\'' sh "$@" < "$list"
  ' sh "$1.bom.z" "$(printf '\376\377')" "$(printf '\377\376')" </dev/null > "$2" 2>"$TMP/bom.err"
  raw=$?
  [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na checagem de BOM"
  [ "$raw" -eq 0 ] || die "grep falhou na checagem de BOM (exit $raw): $(head -c 300 "$TMP/bom.err" | strip_controls)"
}

# Arquivo verificado que começa com BOM UTF-16/32: a forma rg decodifica UTF-16 pelo BOM e a grep lê bytes (os resultados
# divergem), nenhuma lê UTF-32, e um BOM falso na frente de código ASCII esconderia a violação da forma rg (SEC-050).
check_bom() { # $1 lista (um path por linha) · $2 rótulo dos temporários
  [ -s "$1" ] || return 0
  bom_candidates "$1" "$TMP/bom-candidates-$2"
  [ -s "$TMP/bom-candidates-$2" ] || return 0
  with_timeout sh -c "$BOM_CLASS"'
    while IFS= read -r path; do
      class=$(bom_class < "$path")
      [ "$class" = none ] || { printf "%s (%s)\n" "$path" "$class"; exit 0; }
    done < "$1"
  ' sh "$TMP/bom-candidates-$2" </dev/null > "$TMP/bom-found-$2" 2>"$TMP/bom-found-$2.err"
  raw=$?
  [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na checagem de BOM"
  [ "$raw" -eq 0 ] || die "checagem de BOM falhou (exit $raw): $(head -c 300 "$TMP/bom-found-$2.err" | strip_controls)"
  [ -s "$TMP/bom-found-$2" ] && die "arquivo verificado começa com BOM UTF-16/32: $(head -n 1 "$TMP/bom-found-$2") — a forma rg decodifica UTF-16 e a forma grep lê bytes, e nenhuma lê UTF-32: converta o arquivo para UTF-8 ou tire-o dos paths do Verify-Cmd (regra sobre UTF-16/32 fica fora da gramática, skill compound § 2)"
  return 0
}

# Checkout velho: o git só regrava um arquivo quando o blob muda. Remover working-tree-encoding (ou um filtro) do
# .gitattributes deixa o arquivo transcodificado no disco e o check-attr passa a dizer "unspecified".
# - arquivo que o git dá como inalterado: 🚨 se o conteúdo, cru e normalizado pelos atributos atuais (fim de linha,
#   filtro), difere do blob do índice;
# - arquivo que o git lista como modificado (touch, cópia, checkout no mesmo segundo, edição): 🚨 se a working tree tem
#   BOM UTF-16/32 de outra classe que a do blob (UTF-32LE, UTF-32BE, UTF-16LE, UTF-16BE; o blob sem BOM é outra
#   classe), ou NUL quando o blob não tem NUL, ou — blob com NUL — densidade de NUL ≥ 1/4 do arquivo e maior que o dobro
#   da do blob (UTF-16 sem BOM de um blob com NUL plantado). Limite: em UTF-16 a densidade vira 1/2 + d/2 (UTF-32:
#   3/4 + d/4), que não passa do dobro de d quando o blob já tem ≥ 1/3 de NUL (UTF-32: ≥ 3/7) — esse caso, e a
#   transcodificação sem NUL nem BOM (UTF-7, latin1, EBCDIC), só o modo diff --review pega, porque exige worktree limpo.
# Pré-filtro em lote: arquivo sem NUL e sem os bytes de um BOM na working tree não lê o blob.
# Leitura de conteúdo sob o timeout (arquivo enorme não trava a verificação).
check_stale_checkout() { # $1 lista (um path por linha) · $2 rótulo dos temporários · [$3 pathspec que restringe as listas]
  GIT_LITERAL_PATHSPECS=1 git ls-files -s -z -- ${3:+"$3"} > "$TMP/stage-$2.z" || die "git ls-files -s falhou"
  GIT_LITERAL_PATHSPECS=1 git $ATTR_HERE ls-files -m -z -- ${3:+"$3"} > "$TMP/modified-$2.z" || die "git ls-files -m falhou"
  check_names "$TMP/modified-$2.z"
  # ls-files -s: "<modo> <blob> <estágio>TAB<path>" — só o campo do path passa pela checagem de nomes
  [ "$(( $(tr -cd '\n' < "$TMP/stage-$2.z" | wc -c) ))" -eq 0 ] || die "path com quebra de linha no repositório — renomeie o arquivo"
  if tr '\0' '\n' < "$TMP/stage-$2.z" | cut -f2- | grep -q '[[:cntrl:]]'; then die "path com caractere de controle no repositório — renomeie o arquivo"; fi
  tr '\0' '\n' < "$TMP/modified-$2.z" > "$TMP/modified-$2"
  # path TAB blob dos rastreados (estágio 0) da lista: inalterados → clean · modificados → dirty
  tr '\0' '\n' < "$TMP/stage-$2.z" | awk -F'\t' -v CLEAN="$TMP/clean-$2" -v DIRTY="$TMP/dirty-$2" '
    FILENAME == ARGV[1] { want[$0] = 1; next }
    FILENAME == ARGV[2] { modified[$0] = 1; next }
    { split($1, meta, " "); if (meta[3] != "0" || !($2 in want)) next
      if ($2 in modified) print $2 "\t" meta[2] > DIRTY; else print $2 "\t" meta[2] > CLEAN }
  ' "$1" "$TMP/modified-$2" - || die "awk falhou na checagem de checkout"
  stale=""
  if [ -s "$TMP/clean-$2" ]; then
    hash_paths "$TMP/clean-$2" "$TMP/raw-$2" --no-filters
    # quem diverge no cru (normalmente nenhum) é re-hasheado com os atributos atuais
    awk -F'\t' 'FILENAME == ARGV[1] { raw[FNR] = $0; next } $2 != raw[FNR] { print }' "$TMP/raw-$2" "$TMP/clean-$2" > "$TMP/diverge-$2" \
      || die "awk falhou na checagem de checkout"
    if [ -s "$TMP/diverge-$2" ]; then
      hash_paths "$TMP/diverge-$2" "$TMP/normalized-$2"
      # join por número de linha; hash faltando conta como diferença — falha fechada
      stale=$(awk -F'\t' 'FILENAME == ARGV[1] { normalized[FNR] = $0; next } $2 != normalized[FNR] { print $1; exit }' \
        "$TMP/normalized-$2" "$TMP/diverge-$2") || die "awk falhou na checagem de checkout"
    fi
  fi
  [ -n "$stale" ] && die "$stale difere do blob do índice sem mudança registrada pelo git (working-tree-encoding ou filtro removido depois do checkout; ou assume-unchanged/skip-worktree com edição local: git update-index --no-assume-unchanged --no-skip-worktree -- <arquivo>) — no review pré-commit, corrija no worktree do Developer (o trabalho não commitado só existe nele): salve uma cópia do arquivo fora do repositório, apague-o e restaure-o (rm + git checkout -- <arquivo>); na revisão de branch commitada, use um worktree novo ou um clone do remoto canônico"
  [ -s "$TMP/dirty-$2" ] || return 0
  # pré-filtro em lote: só quem tem os bytes de um BOM ou NUL na working tree lê o blob (R104)
  bom_candidates "$TMP/dirty-$2" "$TMP/dirty-bom-$2"
  awk -F'\t' 'FILENAME == ARGV[1] { bom[$0] = 1; next } { print $0 "\t" ($1 in bom ? 1 : 0) }' \
    "$TMP/dirty-bom-$2" "$TMP/dirty-$2" > "$TMP/dirty-marked-$2" || die "awk falhou na checagem de checkout"
  with_timeout sh -c "$BOM_CLASS"'
    TAB=$(printf "\t")
    nul_stats() { # $1 arquivo → NUL (quantidade de bytes NUL) e DENSITY (NUL por mil bytes)
      size=$(( $(wc -c < "$1") )); NUL=$(( $(tr -cd "\000" < "$1" | wc -c) )); DENSITY=0
      [ "$size" -gt 0 ] && DENSITY=$((NUL * 1000 / size)); return 0
    }
    while IFS="$TAB" read -r path blob bom; do
      [ -f "$path" ] || continue
      # sem bytes de BOM e sem NUL na working tree nenhuma das condições abaixo vale: não lê o blob
      if [ "$bom" = 0 ] && tr -d "\000" < "$path" | cmp -s - "./$path"; then continue; fi
      git cat-file blob "$blob" > "$1" || { printf "ERR\t%s\n" "$path"; exit 0; }
      wt_class=$(bom_class < "$path"); blob_class=$(bom_class < "$1")
      nul_stats "$1"; blob_nul=$NUL; blob_density=$DENSITY
      nul_stats "$path"; wt_nul=$NUL; wt_density=$DENSITY
      if [ "$wt_class" != none ] && [ "$wt_class" != "$blob_class" ]; then
        printf "STALE\t%s\n" "$path"; exit 0
      fi
      if [ "$wt_nul" -gt 0 ] && { [ "$blob_nul" -eq 0 ] || { [ "$wt_density" -ge 250 ] && [ "$wt_density" -gt $((2 * blob_density)) ]; }; }; then
        printf "STALE\t%s\n" "$path"; exit 0
      fi
    done < "$2"
  ' sh "$TMP/blob-$2" "$TMP/dirty-marked-$2" </dev/null > "$TMP/dirty-out-$2" 2>"$TMP/dirty-err-$2"
  raw=$?
  [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na checagem de checkout"
  [ "$raw" -eq 0 ] || die "checagem de checkout falhou (exit $raw): $(head -c 300 "$TMP/dirty-err-$2" | strip_controls)"
  IFS="$TAB" read -r kind path < "$TMP/dirty-out-$2" || return 0
  [ "$kind" = ERR ] && die "git cat-file falhou: $path"
  die "$path está na working tree com NUL ou BOM UTF-16/32 que o blob do índice não tem (transcodificação de working-tree-encoding removido, ou arquivo convertido localmente) — se a conversão é parte do trabalho em revisão (arquivo do diff no review pré-commit), converta-o de volta para UTF-8 sem BOM ou trate a regra fora da gramática, sem descartar o trabalho do Developer; se é sobra de um atributo removido, salve uma cópia do arquivo fora do repositório e restaure-o do git (rm + git checkout -- <arquivo>)"
}

# hash-object com os paths como argumentos (xargs -0; nunca --stdin-paths, que des-cita nome iniciado por aspas), sob o timeout
hash_paths() { # $1 lista "path TAB …" · $2 saída (um hash por linha) · demais: opções do hash-object
  list=$1; out=$2; shift 2
  cut -f1 "$list" | tr '\n' '\0' > "$list.z"
  with_timeout sh -c 'list=$1 attr=$2; shift 2; xargs -0 git $attr hash-object "$@" -- < "$list"' sh "$list.z" "$ATTR_HERE" "$@" </dev/null > "$out" 2>"$TMP/hash.err"
  raw=$?
  [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na checagem de checkout"
  [ "$raw" -eq 0 ] || die "git hash-object falhou: $(head -c 300 "$TMP/hash.err" | strip_controls)"
}

compute_changes() {
  resolve_merge_base
  git $ATTR_HERE diff --name-only -z --no-renames --relative "$MERGE_BASE" > "$TMP/changed.d" || die "git diff $MERGE_BASE falhou"
  git diff --name-only -z --no-renames --relative "$MERGE_BASE" HEAD > "$TMP/changed.t" || die "git diff $MERGE_BASE HEAD falhou"
  # índice: um arquivo novo adicionado e apagado da working tree (AD) só aparece aqui — e um commit sem -a o levaria
  git diff --cached --name-only -z --no-renames --relative "$MERGE_BASE" > "$TMP/changed.c" || die "git diff --cached $MERGE_BASE falhou"
  git ls-files -z --others --exclude-standard > "$TMP/changed.u" || die "git ls-files falhou"
  check_names "$TMP/changed.d" "$TMP/changed.t" "$TMP/changed.c" "$TMP/changed.u"
  cat "$TMP/changed.d" "$TMP/changed.t" "$TMP/changed.c" "$TMP/changed.u" | tr '\0' '\n' | sort -u > "$TMP/changed"
}

# exit 0 se algum diretório do caminho é symlink (ex.: diretório versionado substituído por link para fora do repo)
crosses_symlink() {
  dir=$1
  while :; do
    case $dir in */*) dir=${dir%/*} ;; *) return 1 ;; esac
    [ -L "$dir" ] && return 0
  done
}

emit() { if [ "$NUL_OUTPUT" = 1 ]; then printf '%s\0' "$1"; else printf '%s\n' "$1"; fi; }

# Lista FECHADA da skill dependency-lock § 1 (arquivo fora dela não é detectado — vai para o backlog-compound), num único
# awk para a lista inteira (sem um processo por arquivo). Sem distinção de maiúsculas (macOS e Windows não distinguem;
# tolower só dobra ASCII). Nome em qualquer diretório; nomes genéricos só na raiz do escopo; alguns pelo diretório.
dependency_files() { # $1 lista (um path por linha) → os paths que são manifesto, lockfile ou configuração do gerenciador
  awk '
    BEGIN {
      n = split("package.json package-lock.json npm-shrinkwrap.json pnpm-lock.yaml pnpm-workspace.yaml yarn.lock .npmrc " \
        ".yarnrc .yarnrc.yml .pnpmfile.cjs bun.lock bun.lockb bunfig.toml deno.json deno.jsonc deno.lock import_map.json " \
        "pyproject.toml setup.py setup.cfg pipfile pipfile.lock poetry.lock uv.lock uv.toml pdm.lock pdm.toml " \
        "constraints.txt pip.conf pip.ini .condarc " \
        "go.mod go.sum go.work go.work.sum cargo.toml cargo.lock " \
        "pom.xml build.gradle build.gradle.kts settings.gradle settings.gradle.kts gradle.lockfile libs.versions.toml " \
        "gradle.properties gradle-wrapper.properties gradle-wrapper.jar gradlew gradlew.bat " \
        "maven-wrapper.properties maven-wrapper.jar mvnw mvnw.cmd build.sbt " \
        "packages.config packages.lock.json directory.packages.props directory.build.props directory.build.targets " \
        "nuget.config dotnet-tools.json paket.dependencies paket.lock " \
        "composer.json composer.lock gemfile gemfile.lock gems.rb gems.locked mix.exs mix.lock " \
        "pubspec.yaml pubspec.lock pubspec_overrides.yaml package.swift package.resolved podfile podfile.lock " \
        "module.bazel module.bazel.lock flake.nix flake.lock vcpkg.json vcpkg-configuration.json " \
        "conanfile.txt conanfile.py conan.lock", names, " ")
      for (i = 1; i <= n; i++) anywhere[names[i]] = 1
      n = split("workspace workspace.bazel global.json environment.yml environment.yaml project.clj deps.edn", names, " ")
      for (i = 1; i <= n; i++) at_root[names[i]] = 1
    }
    { path = tolower($0); name = path; sub(/.*\//, "", name) }
    name in anywhere || path in at_root { print; next }
    name ~ /^requirements.*\.(txt|in)$/ || name ~ /\.(csproj|fsproj|vbproj|gemspec)$/ { print; next }
    path ~ /(^|\/)requirements\/.*\.(txt|in)$/ || path ~ /(^|\/)\.yarn\/(releases|plugins)\// { print; next }
    path ~ /(^|\/)\.mvn\/(extensions\.xml|maven\.config|jvm\.config)$/ { print; next }
    path ~ /(^|\/)\.cargo\/config(\.toml)?$/ || path ~ /(^|\/)\.bundle\/config$/ { print; next }
  ' "$1" || die "awk falhou na seleção de manifestos"
}

# deps-revert: a versão local de todo arquivo que o comando troca ou remove vai para a quarentena, no diretório git comum
# a todos os worktrees (sobrevive a git worktree remove); <data>-<pid> separa execuções seguidas.
# Layout PLANO: <NNNN>-<worktree|index>-<nome do arquivo>, sem subdiretórios — um symlink guardado nunca vira caminho para a
# próxima gravação (SEC-053) e dois itens nunca disputam o mesmo nome (SEC-054); MANIFEST mapeia nome → origem → path.
quarantine() { # $1 path · $2 "cp -P" (cópia, o arquivo segue no lugar), "mv" ou index (versão do índice) → QUARANTINED
  if [ -z "$QUARANTINE" ]; then
    common=$(git rev-parse --git-common-dir) || die "git rev-parse --git-common-dir falhou"
    common=$(abs_dir "$common") || die "diretório git comum inacessível: $common"
    mkdir -p -- "$common/dotagents/deps-quarantine" || die "quarentena falhou: $1"
    QUARANTINE="$common/dotagents/deps-quarantine/$(date +%Y%m%d%H%M%S)-$$"
    # mkdir sem -p: o diretório da execução é novo, nunca um que já existia
    mkdir -- "$QUARANTINE" || die "quarentena falhou: $1"
    QUARANTINE_COUNT=0
  fi
  QUARANTINE_COUNT=$((QUARANTINE_COUNT + 1))
  kind=worktree; [ "$2" = index ] && kind=index
  QUARANTINED="$QUARANTINE/$(printf '%04d' "$QUARANTINE_COUNT")-$kind-${1##*/}"
  { [ -e "$QUARANTINED" ] || [ -L "$QUARANTINED" ]; } && die "quarentena falhou: destino já existe ($QUARANTINED)"
  if [ "$2" = index ]; then
    git cat-file blob ":./$1" > "$QUARANTINED" || die "quarentena falhou: $1 (versão do índice)"
  else
    $2 -- "./$1" "$QUARANTINED" || die "quarentena falhou: $1"
  fi
  printf '%s\t%s\t%s\n' "${QUARANTINED##*/}" "$kind" "$1" >> "$QUARANTINE/MANIFEST" || die "quarentena falhou: MANIFEST"
}

NUL_OUTPUT=0
case $MODE in
  base)
    [ $# -eq 0 ] || usage
    resolve_merge_base
    printf '%s\n' "$MERGE_BASE"
    exit 0 ;;
  paths)
    case $# in 0) ;; 1) [ "$1" = -z ] || usage; NUL_OUTPUT=1 ;; *) usage ;; esac
    compute_changes
    while IFS= read -r path; do
      # arquivo regular, sem symlink nem diretório-pai que virou symlink (que levaria a leitura para fora do repo)
      [ -f "$path" ] && [ ! -L "$path" ] && ! crosses_symlink "$path" && emit "$path"
    done < "$TMP/changed"
    exit 0 ;;
  deps)
    case $# in 0) ;; 1) [ "$1" = -z ] || usage; NUL_OUTPUT=1 ;; *) usage ;; esac
    compute_changes
    dependency_files "$TMP/changed" > "$TMP/deps"
    if [ "$NUL_OUTPUT" = 1 ]; then tr '\n' '\0' < "$TMP/deps"; else cat "$TMP/deps"; fi
    exit 0 ;;
  deps-revert)
    [ $# -eq 0 ] || usage
    compute_changes
    dependency_files "$TMP/changed" > "$TMP/deps"
    QUARANTINE=""
    while IFS= read -r path; do
      crosses_symlink "$path" && die "manifesto sob diretório que virou symlink — revert manual: $path"
      # versão do índice diferente da working tree e do HEAD (git add seguido de edição ou de rm): o checkout e o rm --cached
      # abaixo a descartariam e nenhum commit a guarda — vai para a quarentena como item "index"
      staged=""
      if git cat-file -e ":./$path" 2>/dev/null \
        && ! GIT_LITERAL_PATHSPECS=1 git $ATTR_HERE diff --quiet --no-ext-diff -- "$path" 2>/dev/null \
        && ! GIT_LITERAL_PATHSPECS=1 git diff --cached --quiet --no-ext-diff HEAD -- "$path" 2>/dev/null; then
        quarantine "$path" index; staged="versão do índice → $QUARANTINED"
      fi
      if git cat-file -e "$MERGE_BASE:./$path" 2>/dev/null; then
        # versão local (falso positivo rastreado com edição não commitada) recuperável antes da troca
        saved=$staged
        if [ -e "./$path" ] || [ -L "./$path" ]; then quarantine "$path" 'cp -P'; saved="versão local → $QUARANTINED${staged:+; $staged}"; fi
        GIT_LITERAL_PATHSPECS=1 git checkout -q "$MERGE_BASE" -- "$path" || die "git checkout falhou: $path"
        printf 'revertido ao merge-base: %s%s\n' "$path" "${saved:+ ($saved)}"
      else
        GIT_LITERAL_PATHSPECS=1 git rm -q -f --cached --ignore-unmatch -- "$path" || die "git rm falhou: $path"
        if [ -e "./$path" ] || [ -L "./$path" ]; then
          quarantine "$path" mv
          printf 'movido para a quarentena (ausente no merge-base): %s → %s%s\n' "$path" "$QUARANTINED" "${staged:+ ($staged)}"
        else
          printf 'removido do índice (ausente no merge-base e da working tree): %s%s\n' "$path" "${staged:+ ($staged)}"
        fi
      fi
    done < "$TMP/deps"
    [ -s "$TMP/deps" ] || printf 'nenhum manifesto ou lockfile no diff\n'
    exit 0 ;;
esac

# ---------------------------------------------------------------- memórias: pré-condições e listagem
[ -d memories ] || die "memories/ ausente — rode na raiz do escopo DotAgents"
find memories -name "*$NL*" > "$TMP/newline" || die "find falhou em memories/"
[ -s "$TMP/newline" ] && die "nome com quebra de linha em memories/ — renomeie o arquivo"
find memories ! -type f ! -type d > "$TMP/special" || die "find falhou em memories/"
[ -s "$TMP/special" ] && die "memories/ contém symlink ou arquivo especial: $(tr '\n' ' ' < "$TMP/special")"
find memories > "$TMP/all" || die "find falhou em memories/"
grep -v '^[A-Za-z0-9_./-]*$' "$TMP/all" > "$TMP/badname"
[ -s "$TMP/badname" ] && die "nome fora de [A-Za-z0-9_./-] em memories/: $(tr '\n' ' ' < "$TMP/badname")"
find memories -type f -name '*.md' ! -path 'memories/templates/*' | sort > "$TMP/files" || die "find falhou em memories/"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  check_encoding "$TMP/files" memories "working-tree-encoding em memories/ — a memória precisa estar em UTF-8: remova o atributo do .gitattributes e refaça o checkout da memória"
  check_stale_checkout "$TMP/files" memories memories
fi
CR=$(printf '\r')
while IFS= read -r file; do
  if grep -q "$CR" "$file"; then die "fim de linha CRLF em $file — converta para LF"; fi
  # byte NUL = memória fora de UTF-8 (ex.: UTF-16 sem atributo no git): as entradas sumiriam do lint
  tr -d '\000' < "$file" | cmp -s - "$file" || die "byte NUL em $file — a memória precisa estar em UTF-8"
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
: > "$TMP/index.tsv"
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
  ' memories/implementations/INDEX.md > "$TMP/index.tsv" || die "awk falhou em memories/implementations/INDEX.md"
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
    function real_date(s,   y, m, d, days) {
      if (s !~ /^\[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\]/) return 0
      y = substr(s, 2, 4) + 0; m = substr(s, 7, 2) + 0; d = substr(s, 10, 2) + 0
      days = (m == 2) ? ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0 ? 29 : 28) : (m == 4 || m == 6 || m == 9 || m == 11 ? 30 : 31)
      return m >= 1 && m <= 12 && d >= 1 && d <= days
    }
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
      if (!ok["title", n] || !real_date($3)) err("título sem [AAAA-MM-DD][Task NNN] ou [AAAA-MM-DD][bootstrap] com data real")
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
      else if ($4 ~ /`PADRAO_SEMANTICO`/ && ok["exec", n]) err("PADRAO_SEMANTICO exige `N/A — <motivo>` (regra detectável por busca é PADRAO_VERIFICAVEL)")
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
  ' "$TMP/index.tsv" "$TMP/fragfiles" "$TMP/entries" >> "$TMP/lint" || die "awk falhou no lint do INDEX"

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
    matches "$RE_INDEX_DATE" "$updated" && awk -v D="$updated" 'BEGIN {
      y = substr(D, 2, 4) + 0; m = substr(D, 7, 2) + 0; d = substr(D, 10, 2) + 0
      days = (m == 2) ? ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0 ? 29 : 28) : (m == 4 || m == 6 || m == 9 || m == 11 ? 30 : 31)
      exit !(d <= days)
    }' || printf 'E\tINDEX com data fora do formato [AAAA-MM-DD]: %s\n' "$file" >> "$TMP/lint"
  done < "$TMP/index.tsv"

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
  grep -q '^LEGADO' "$TMP/index.tsv" && cat "$TMP/fragfiles" >> "$TMP/active"
  while IFS="$TAB" read -r file globs summary updated columns; do
    [ "$file" = LEGADO ] && continue
    globs_match "$globs" && printf 'memories/implementations/%s\n' "$file" >> "$TMP/active"
  done < "$TMP/index.tsv"
  sort -u "$TMP/active" -o "$TMP/active"
  if [ -s "$TMP/active" ]; then
    while IFS= read -r file; do printf 'FRAGMENTO ATIVO: %s\n' "$file"; done < "$TMP/active"
  else
    printf 'FRAGMENTOS ATIVOS: nenhum\n'
  fi
}

# ---------------------------------------------------------------- execução no snapshot
# Snapshot = cópia byte a byte dos arquivos visíveis ao git (rastreados e novos não ignorados) que estão sob os paths
# dos comandos a executar, com o conteúdo da working tree: a cópia não passa por filtros nem pelo índice do git.
# Antes da cópia, 🚨 para arquivo com working-tree-encoding (bytes transcodificados), com checkout velho
# (transcodificação que sobrou de um atributo removido) ou que começa com BOM UTF-16/32 (check_bom).
# Symlinks e diretórios-pai symlink ficam de fora; conteúdo de submodule não entra (gitlink não é arquivo).
command_roots() { # $1 arquivo com um comando por linha → prefixos de path ("." = escopo inteiro), um por linha
  while IFS= read -r command_text; do
    case $command_text in
      test*) paths=$(printf '%s' "$command_text" | sed "s/^test \(! \)\{0,1\}-e '\(.*\)'\$/\2/") ;;
      *) paths=$(printf '%s' "$command_text" | sed "s/^.* -e '[^']*' //; s/; test .*//") ;;
    esac
    set -f
    for token in $paths; do
      root=""
      rest=${token%/}
      while [ -n "$rest" ]; do
        segment=${rest%%/*}
        case $segment in *'*'*) break ;; esac
        root=${root:+$root/}$segment
        case $rest in */*) rest=${rest#*/} ;; *) rest="" ;; esac
      done
      printf '%s\n' "${root:-.}"
    done
    set +f
  done < "$1"
}

make_snapshot() { # $1 arquivo com os comandos que vão rodar
  SNAPSHOT="$TMP/snapshot"
  mkdir "$SNAPSHOT" || die "mkdir do snapshot falhou"
  git ls-files -z -co --exclude-standard > "$TMP/visible.z" || die "git ls-files falhou"
  check_names "$TMP/visible.z"
  command_roots "$1" | sort -u > "$TMP/roots"
  # sobe pelos diretórios do path com index/substr, sem regex sobre o nome (busybox awk entra em laço com "\" no nome)
  tr '\0' '\n' < "$TMP/visible.z" | sort -u | awk '
    function last_slash(p,   i, at) { at = 0; while ((i = index(substr(p, at + 1), "/")) > 0) at += i; return at }
    NR == FNR { root[$0] = 1; next }
    { if ("." in root) { print; next }
      path = $0
      while (1) { if (path in root) { print $0; next } cut = last_slash(path); if (cut == 0) next; path = substr(path, 1, cut - 1) } }
  ' "$TMP/roots" - > "$TMP/snaplist" || die "seleção do snapshot falhou"
  while IFS= read -r path; do
    [ -f "$path" ] && [ ! -L "$path" ] && ! crosses_symlink "$path" && printf '%s\n' "$path"
  done < "$TMP/snaplist" > "$TMP/copylist"
  [ -s "$TMP/copylist" ] || return 0
  check_encoding "$TMP/copylist" snapshot "working-tree-encoding em arquivo verificado — remova o atributo do .gitattributes e refaça o checkout do arquivo, ou trate a regra fora da gramática"
  check_stale_checkout "$TMP/copylist" snapshot
  check_bom "$TMP/copylist" snapshot
  copy_snapshot
}

# Montagem sob o mesmo timeout dos comandos: GNU cp --parents ou cpio -p (um processo para a lista inteira); sem os dois,
# um cp por arquivo.
# --no-preserve=mode: diretório de origem sem permissão de escrita (555) não bloqueia a cópia dos arquivos dele.
copy_snapshot() {
  if cp --version 2>/dev/null | grep -q GNU; then
    method=gnu
  elif mkdir "$TMP/cpio-probe" && cpio -pd "$TMP/cpio-probe" < /dev/null >/dev/null 2>&1; then
    method=cpio
  else
    method=loop
  fi
  with_timeout sh -c '
    case $1 in
      gnu) tr "\n" "\0" < "$2" | xargs -0 cp --no-preserve=mode --parents -t "$3" -- ;;
      cpio) cpio -pd "$3" < "$2" ;;
      *) while IFS= read -r path; do
           case $path in */*) mkdir -p -- "$3/${path%/*}" || exit 1 ;; esac
           cp -- "$path" "$3/$path" || exit 1
         done < "$2" ;;
    esac
  ' sh "$method" "$TMP/copylist" "$SNAPSHOT" </dev/null >/dev/null 2>"$TMP/copy.err"
  raw=$?
  [ "$raw" -eq 124 ] && [ "$HAS_TIMEOUT" = 1 ] && die "timeout (${TIMEOUT} s) na montagem do snapshot"
  [ "$raw" -eq 0 ] || die "cópia para o snapshot falhou (exit $raw, $method): $(grep -Ev '^[0-9]+ blocks?$' "$TMP/copy.err" | head -c 300 | strip_controls)"
}

check_timeout_tool() { [ "$HAS_TIMEOUT" = 1 ] || warn "utilitário timeout ausente — execução sem limite de tempo"; }

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
  (cd "$SNAPSHOT" && with_timeout sh -c "$search") </dev/null >/dev/null 2>"$TMP/cmd.err"
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
# autoverificação em todos os modos de memória: exige o merge-base só quando o verificador está dentro do repositório
if verifier_inside_repo; then
  if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    resolve_merge_base
  else
    SELF_CHECKED=1
    warn "repositório sem commits: verificador em execução ($VERIFIER_RELATIVE) sem versão de referência — revise o script manualmente (skill compound § 5)"
  fi
fi
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
    REVIEW=0
    case $# in 0) ;; 1) [ "$1" = --review ] || usage; REVIEW=1 ;; *) usage ;; esac
    compute_changes
    PRE_COMMIT_HINT="no review pré-commit da squad, rode diff sem --review no worktree do Developer (skill code-review § 2.1)"
    if [ "$(git rev-parse HEAD)" = "$MERGE_BASE" ]; then
      # normal no gate pré-commit (nada commitado ainda); numa branch commitada, sinal de base errada — ex.: clone de um
      # checkout local, em que origin/HEAD aponta para a própria branch da task
      wrong_base="num clone de checkout local, origin/HEAD aponta para a branch da task (use git worktree add, clone do remoto canônico ou DOTAGENTS_BASE_BRANCH=origin/<branch padrão>)"
      if [ "$REVIEW" = 1 ]; then
        die "--review com merge-base igual a HEAD ($base_ref): não há commits a revisar, a base está errada — $wrong_base; $PRE_COMMIT_HINT"
      fi
      warn "merge-base igual a HEAD ($base_ref): só mudanças não commitadas entram no diff (normal no review pré-commit da squad) — se havia commits a revisar, a base está errada: $wrong_base"
    fi
    if [ "$REVIEW" = 1 ]; then
      # review: o diff é só o commitado; qualquer mudança local (inclusive checkout velho que o git vê como modificado) bloqueia.
      # --untracked-files=all: status.showUntrackedFiles=no do executor não esconde arquivo novo
      git --no-optional-locks $ATTR_HERE status --porcelain -z --untracked-files=all --ignore-submodules=none > "$TMP/status.z" || die "git status falhou"
      check_names "$TMP/status.z"
      [ -s "$TMP/status.z" ] && die "--review exige worktree limpo (sem mudanças nem arquivos novos não ignorados): $(tr '\0' '\n' < "$TMP/status.z" | head -n 1) — revise a branch commitada num worktree novo (git worktree add) ou num clone do remoto canônico; $PRE_COMMIT_HINT"
    fi
    # diff vazio: nada a verificar — no gate pré-commit, sinal de que o verificador rodou fora do worktree do Developer
    [ -s "$TMP/changed" ] || warn "diff vazio: nenhum arquivo difere do merge-base, nada foi verificado — no review pré-commit da squad, rode no worktree do Developer (onde está o trabalho não commitado); com § Arquivos Alterados preenchido na task, não aprove sobre esta saída"
    git $ATTR_HERE diff -U0 --no-renames --no-ext-diff --no-textconv --text --no-color "$MERGE_BASE" -- memories > "$TMP/memdiff" || die "git diff de memories/ falhou"
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
      cut -f3 "$TMP/applicable" | while IFS= read -r line; do prepare_command "$line"; printf '%s\n' "$COMMAND"; done > "$TMP/commands"
      make_snapshot "$TMP/commands"
      while IFS="$TAB" read -r e_file e_title e_verify; do
        run_entry "$e_file" "$e_title" "$e_verify"
      done < "$TMP/applicable"
    fi ;;
  run)
    [ $# -eq 1 ] || usage
    select_entry "$1"
    if is_na "$e_verify"; then printf 'N/A: nada a executar (%s)\n' "$e_title"; exit 0; fi
    require_repo_root
    check_timeout_tool
    prepare_command "$e_verify"
    printf '%s\n' "$COMMAND" > "$TMP/commands"
    make_snapshot "$TMP/commands"
    printf '%s\n' "$TABLE_HEADER"
    run_entry "$e_file" "$e_title" "$e_verify" ;;
  probe)
    [ $# -eq 2 ] || usage
    select_entry "$1"
    if is_na "$e_verify"; then printf 'N/A: contraprova não se aplica (%s)\n' "$e_title"; exit 0; fi
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

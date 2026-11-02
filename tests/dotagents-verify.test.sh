#!/bin/sh
# Suíte de regressão do hooks/dotagents-verify.sh e dos snippets das skills que o usam.
# Rode a partir da raiz do repositório DotAgents: sh tests/dotagents-verify.test.sh
# Requer: git, awk, timeout, python3. ripgrep, cpio, mawk e busybox são opcionais (casos dependentes são pulados sem eles).
# Exit: 0 todos os casos passaram · 1 algum caso falhou.
set -u
LC_ALL=C
export LC_ALL
unset CDPATH
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
VERIFY="$HERE/hooks/dotagents-verify.sh"
VECTORS="$HERE/tests/fixtures/attack-vectors.txt"
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT
# git hermético: config global e de sistema do usuário (gpgsign, hooksPath, aliases) não afetam a suíte
HOME="$WORK/home"
XDG_CONFIG_HOME="$WORK/home/.config"
GIT_CONFIG_NOSYSTEM=1
export HOME XDG_CONFIG_HOME GIT_CONFIG_NOSYSTEM
unset GIT_CONFIG_GLOBAL GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_TEMPLATE_DIR
# variáveis do verificador herdadas do shell do usuário mudariam a base e o timeout dos casos
unset DOTAGENTS_BASE_BRANCH DOTAGENTS_VERIFY_TIMEOUT
# GIT_ATTR_SOURCE (git ≥ 2.40) faria o git ler atributos de outra árvore
unset GIT_ATTR_SOURCE
mkdir -p "$HOME"
# canários usam caminho absoluto fora do repo e do snapshot: qualquer execução indevida deixa rastro aqui
CANARY="$WORK/canary"
mkdir -p "$CANARY"
HAS_RG=0
command -v rg >/dev/null 2>&1 && HAS_RG=1
# root escreve em diretório 555/000: casos de permissão são pulados (e contados como pulados)
IS_ROOT=0
[ "$(id -u)" -eq 0 ] && IS_ROOT=1

# ---------------------------------------------------------------- helpers
# contadores em arquivo: asserts feitos dentro de subshell (pipelines, $(…)) também contam
ok() { printf 'ok\n' >> "$WORK/tally"; }
ko() { printf 'ko\n' >> "$WORK/tally"; printf '❌ %s\n' "$1"; sed 's/^/   │ /' "$WORK/out" | head -n 20; }
skip() { i=0; while [ "$i" -lt "$3" ]; do printf 'skip\n' >> "$WORK/tally"; i=$((i + 1)); done; printf '⏭️  %s (%s): %s asserts\n' "$1" "$2" "$3"; }

# expect <descrição> <exit esperado> <comando...> — roda no diretório atual, guarda stdout+stderr em $WORK/out
expect() {
  desc=$1; want=$2; shift 2
  "$@" > "$WORK/out" 2>&1 </dev/null
  got=$?
  if [ "$got" -eq "$want" ]; then ok; else printf 'exit %s, esperado %s\n' "$got" "$want" >> "$WORK/out"; ko "$desc"; fi
}
# saída do último expect contém (has) / não contém (lacks) o texto fixo
has() { if grep -qF -- "$2" "$WORK/out"; then ok; else ko "$1 — faltou: $2"; fi; }
lacks() { if grep -qF -- "$2" "$WORK/out"; then ko "$1 — sobrou: $2"; else ok; fi; }
no_canary() { if [ -n "$(ls "$CANARY")" ]; then printf 'canários: %s\n' "$(ls "$CANARY")" > "$WORK/out"; ko "$1 — arquivo canário criado"; rm -f "$CANARY"/*; else ok; fi; }
canary_line() { printf '%s\n' "$1" | sed "s#PWN#$CANARY/PWN#g"; }

verify() { sh "$VERIFY" "$@"; }

entry() { # título tipo escopo regra verify [origem]
  printf '### %s\n- **Tipo:** `%s`\n- **Escopo (globs):** `%s`\n- **Regra:** %s\n- **Verify-Cmd:** %s\n- **Origem:** `%s`\n\n' \
    "$1" "$2" "$3" "$4" "$5" "${6:-docs/done/001-x/}"
}

# repositório novo em $WORK/<nome> com memórias válidas, commit em main e branch feat
new_repo() {
  REPO="$WORK/$1"
  rm -rf "$REPO" && mkdir -p "$REPO/memories/implementations" "$REPO/memories/templates" "$REPO/src/checkout" "$REPO/lib" && cd "$REPO" || exit 1
  git init -q && git symbolic-ref HEAD refs/heads/main && git config user.email t@t && git config user.name t
  printf 'ok\n' > src/a.ts
  printf 'x\n' > lib/b.ts
  {
    printf '# Guidelines\n\n## Regras\n\n'
    entry '[2026-01-01][Task 001] sem console.log [SUPERSEDED em 2026-02-01]' PADRAO_VERIFICAVEL 'src/**' 'NUNCA console.log' "\`rg --no-config -q -e 'console' src/; test \$? -eq 1\`"
    if [ "$HAS_RG" = 1 ]; then search="rg --no-config -q -e 'console\\.' src/"; else search="grep -rqE -e 'console\\.' src/"; fi
    entry '[2026-02-01][Task 002] sem console' PADRAO_VERIFICAVEL 'src/**' 'NUNCA console.* em src' "\`$search; test \$? -eq 1\`" docs/done/002-x/
    entry '[2026-02-02][Task 002] sem TODO em lib' PADRAO_VERIFICAVEL 'lib/**' 'NUNCA TODO em lib' "\`grep -rqE -e 'TODO|FIXME' lib; test \$? -eq 1\`" docs/done/002-x/
    entry '[2026-02-03][Task 002] nomes de domínio' PADRAO_SEMANTICO '*' 'SEMPRE nomes de domínio' '`N/A — não é detectável por regex`' docs/done/002-x/
  } > memories/guidelines.md
  entry '[2026-03-01][Task 003] checkout sem float' PADRAO_VERIFICAVEL 'src/checkout/**' 'NUNCA parseFloat em checkout' "\`grep -rqF -e 'parseFloat' src/checkout; test \$? -eq 1\`" docs/done/003-x/ > memories/implementations/checkout-padrao-verificavel.md
  printf '# Índice\n\n| Arquivo | Globs | Resumo | Atualizado |\n|---|---|---|---|\n| checkout-padrao-verificavel.md | src/checkout/** | checkout | [2026-03-01] |\n' > memories/implementations/INDEX.md
  printf -- '- **Verify-Cmd:** `touch %s/PWN_TEMPLATE`\n' "$CANARY" > memories/templates/x.md
  printf '# Negócio\n' > memories/business.md
  printf '# Arquitetura\n' > memories/architecture.md
  git add -A && git commit -qm base && git checkout -qb feat
  cp memories/guidelines.md "$WORK/guidelines.base"
}
# itens da quarentena plana do deps-revert, pelo MANIFEST (nome TAB origem TAB path) de todas as execuções
qfiles() { # origem (worktree|index) · path → caminhos dos itens, um por linha
  for m in .git/dotagents/deps-quarantine/*/MANIFEST; do
    [ -f "$m" ] && awk -F'\t' -v K="$1" -v P="$2" -v D="${m%/MANIFEST}" '$2 == K && $3 == P { print D "/" $1 }' "$m"
  done
}
qfile() { qfiles "$1" "$2" | tail -n 1; }
reset_guidelines() { cp "$WORK/guidelines.base" memories/guidelines.md; }
append() { cat >> memories/guidelines.md; }

# ---------------------------------------------------------------- controle positivo do detector de canário
: > "$CANARY/PWN_CONTROLE"
if [ -n "$(ls "$CANARY")" ]; then ok; else printf 'detector não viu o canário de controle\n' > "$WORK/out"; ko 'controle positivo do canário'; fi
rm -f "$CANARY"/*

# ---------------------------------------------------------------- lint e gramática
new_repo lint
expect 'lint de memórias válidas' 0 verify lint
has 'lint de memórias válidas' '✅ memórias conformes'
expect 'uso inválido sem modo' 2 verify
expect 'modo inexistente' 2 verify all

total=0; leaked=0
while IFS='|' read -r label line; do
  case $label in '#'*|'') continue ;; esac
  total=$((total + 1))
  reset_guidelines
  printf '### [2026-05-05][Task 009] vetor\n- **Tipo:** `PADRAO_VERIFICAVEL`\n- **Escopo (globs):** `src/**`\n- **Regra:** NUNCA vetor\n%s\n- **Origem:** `docs/done/009-x/`\n' "$(canary_line "$line")" | append
  printf 'console.log(1)\n' > src/vetor.ts
  verify diff > "$WORK/out" 2>&1
  rc=$?
  # barrado no lint (antes de qualquer execução), não por erro de um comando que chegou a rodar
  if [ "$rc" -ne 3 ] || ! grep -qF 'lint reprovado — nada foi executado' "$WORK/out"; then
    leaked=$((leaked + 1)); printf '   vetor não barrado no lint: %s (exit %s)\n' "$label" "$rc"
  fi
done < "$VECTORS"
rm -f src/vetor.ts
if [ "$leaked" -eq 0 ] && [ "$total" -gt 60 ]; then ok; else printf '%s de %s vetores passaram\n' "$leaked" "$total" > "$WORK/out"; ko 'vetores de ataque barrados no lint'; fi
no_canary 'vetores de ataque'

lint_case() { # descrição · exit · texto esperado · entrada (stdin)
  reset_guidelines; append
  expect "$1" "$2" verify lint
  [ -n "$3" ] && has "$1" "$3"
}
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO './src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'Escopo com ./ (R31)' 3 'Escopo (globs) inválido' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO '/src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'Escopo absoluto (R31)' 3 'Escopo (globs) inválido' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/../x' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'Escopo com .. (R31)' 3 'Escopo (globs) inválido' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'lib/**,src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'Escopo sem espaço após vírgula' 3 'Escopo (globs) inválido' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/**, lib/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'Escopo fora de ordem' 3 'ordem lexicográfica' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO '9, 10' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'globs numéricos comparados como texto: 9, 10 (R61)' 3 'ordem lexicográfica' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO '10, 9' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'globs numéricos comparados como texto: 10, 9 (R61)' 0 '' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO "src/**'; touch $CANARY/PWN_GLOB; echo '" 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'glob com injeção (SEC-001)' 3 'Escopo (globs) inválido' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/**' 'usar nomes bons' '`N/A — m`' > "$WORK/entry"; lint_case 'Regra fora do formato' 3 'Regra ausente ou fora do formato' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A`' > "$WORK/entry"; lint_case 'N/A sem motivo em PADRAO_SEMANTICO (R44)' 3 'N/A sem motivo' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_VERIFICAVEL 'src/**' 'NUNCA x' '`N/A — m`' > "$WORK/entry"; lint_case 'PADRAO_VERIFICAVEL com N/A' 3 'exige Verify-Cmd executável' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' DOMINIO '*' 'SE a ENTÃO b' '`N/A`' > "$WORK/entry"; lint_case 'DOMINIO em guidelines.md (Tipo × arquivo)' 3 'Tipo incompatível' < "$WORK/entry"
entry 'sem data' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'título sem data e task' 3 'título sem' < "$WORK/entry"
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' 'docs/x' > "$WORK/entry"; lint_case 'Origem fora do formato (D9)' 3 'Origem ausente' < "$WORK/entry"
printf '### [2026-05-05][Task 009] só origem\n- **Origem:** `docs/done/009-x/`\n' > "$WORK/entry"; lint_case 'entrada só com Origem (R58)' 3 'Tipo inválido' < "$WORK/entry"
{ entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`'; printf -- '- **Regra:** SEMPRE y\n'; } > "$WORK/entry"; lint_case 'campo repetido (R25)' 3 'campo repetido' < "$WORK/entry"
{ entry '[2026-05-05][Task 009] a' PADRAO_SEMANTICO 'src/**' 'SEMPRE Nomes  claros' '`N/A — m`'; entry '[2026-05-05][Task 010] b' PADRAO_SEMANTICO 'src/**' 'SEMPRE nomes claros' '`N/A — m`'; } > "$WORK/entry"; lint_case 'entrada duplicada (dedup)' 3 'entrada duplicada' < "$WORK/entry"
printf '### [2026-01-09][Task 010] legado\ntexto livre\n' > "$WORK/entry"; lint_case 'entrada legada vira aviso (R24)' 0 'entrada legada' < "$WORK/entry"
has 'lint com aviso informa a contagem' 'aviso(s)'
for reason in 'x; touch PWN' '$(touch PWN)' 'x | sh'; do
  entry '[2026-05-05][Task 009] motivo' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' "\`N/A — $(canary_line "$reason")\`" > "$WORK/entry"; lint_case "motivo de N/A com metacaractere em PADRAO_SEMANTICO: $reason (E11)" 3 'fora da gramática' < "$WORK/entry"
done
entry '[2026-99-99][Task 009] e' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; lint_case 'data impossível no título (E7)' 3 'título sem' < "$WORK/entry"
entry '[2026-05-05][bootstrap] stack' PADRAO_SEMANTICO '*' 'SEMPRE seguir a stack detectada' '`N/A — convenção de design`' bootstrap > "$WORK/entry"; lint_case 'entrada do bootstrap (R34)' 0 '' < "$WORK/entry"
printf '### [2026-05-05][Task 009] e\n- **Tipo:** `PADRAO_SEMANTICO`\n- **Escopo (globs):** `src/**`\n- **Regra:** SEMPRE \033]0;x\007ok\n- **Verify-Cmd:** `N/A — m`\n- **Origem:** `docs/done/009-x/`\n' > "$WORK/entry"; lint_case 'caractere de controle sanitizado (SEC-009d)' 0 '' < "$WORK/entry"
if grep -q "$(printf '\033')" "$WORK/out"; then ko 'ESC chegou à saída'; else ok; fi
reset_guidelines

cp memories/implementations/INDEX.md "$WORK/index.base"
printf '| checkout-padrao-verificavel.md | src/**%s; touch %s/PWN_IDX; echo %s | x | [d] |\n' "'" "$CANARY" "'" >> memories/implementations/INDEX.md
expect 'Globs do INDEX com injeção (SEC-001)' 3 verify lint
has 'Globs do INDEX com injeção (SEC-001)' 'INDEX com Globs fora da gramática'
cp "$WORK/index.base" memories/implementations/INDEX.md
printf '| checkout-padrao-verificavel.md | src/checkout/** | x | ontem |\n' > "$WORK/row"
sed '$d' "$WORK/index.base" > memories/implementations/INDEX.md && cat "$WORK/row" >> memories/implementations/INDEX.md
expect 'data do INDEX fora do formato (E7)' 3 verify lint
has 'data do INDEX fora do formato (E7)' 'data fora do formato'
sed '$d' "$WORK/index.base" > memories/implementations/INDEX.md && printf '| checkout-padrao-verificavel.md | src/checkout/** | x |\n' >> memories/implementations/INDEX.md
expect 'INDEX com coluna a menos (E7)' 3 verify lint
has 'INDEX com coluna a menos (E7)' 'fora do formato | arquivo'
cp "$WORK/index.base" memories/implementations/INDEX.md && tail -n 1 "$WORK/index.base" >> memories/implementations/INDEX.md
expect 'fragmento em duas linhas do INDEX (E7)' 3 verify lint
has 'fragmento em duas linhas do INDEX (E7)' 'mais de uma linha do INDEX'
cp "$WORK/index.base" memories/implementations/INDEX.md
entry '[2026-03-03][Task 003] semântico' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > memories/implementations/ui-padrao-semantico.md
printf '| ui-padrao-semantico.md | src/** | ui | [2026-03-03] |\n' >> memories/implementations/INDEX.md
expect 'fragmento -padrao-semantico com Tipo certo (E5)' 0 verify lint
entry '[2026-03-03][Task 003] semântico' PADRAO_VERIFICAVEL 'src/**' 'NUNCA x' "\`grep -rqF -e 'x' src; test \$? -eq 1\`" > memories/implementations/ui-padrao-semantico.md
expect 'fragmento -padrao-semantico com Tipo errado (E5)' 3 verify lint
has 'fragmento -padrao-semantico com Tipo errado (E5)' 'Tipo incompatível'
rm memories/implementations/ui-padrao-semantico.md && cp "$WORK/index.base" memories/implementations/INDEX.md
printf '# G\r\n' > memories/crlf.md
expect 'memória com CRLF (E6)' 3 verify lint
has 'memória com CRLF (E6)' 'CRLF'
rm memories/crlf.md
entry '[2026-03-02][Task 003] lib no fragmento' PADRAO_VERIFICAVEL 'lib/**' 'NUNCA x em lib' "\`grep -rqF -e 'x' lib; test \$? -eq 1\`" >> memories/implementations/checkout-padrao-verificavel.md
expect 'Escopo do fragmento fora dos Globs do INDEX (R31)' 3 verify lint
has 'Escopo do fragmento fora dos Globs do INDEX (R31)' 'fora dos Globs do INDEX'
git checkout -q -- memories/implementations/checkout-padrao-verificavel.md
entry '[2026-03-03][Task 003] órfão' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > memories/implementations/orfao-padrao-semantico.md
expect 'fragmento sem linha no INDEX' 3 verify lint
has 'fragmento sem linha no INDEX' 'fragmento sem linha no INDEX'
rm memories/implementations/orfao-padrao-semantico.md
printf '# Índice\n- `checkout-padrao-verificavel.md` — antigo — [2026-01-01]\n' > memories/implementations/INDEX.md
expect 'INDEX legado vira aviso' 0 verify fragments docs/x.md
has 'INDEX legado vira aviso' 'INDEX legado'
has 'INDEX legado ativa todos os fragmentos' 'FRAGMENTO ATIVO: memories/implementations/checkout-padrao-verificavel.md'
cp "$WORK/index.base" memories/implementations/INDEX.md
ln -s ../../src/a.ts memories/implementations/evil.md
expect 'symlink em memories/ (SEC-002)' 3 verify lint
rm memories/implementations/evil.md
: > 'memories/a:b.md'
expect 'nome com : em memories/' 3 verify lint
rm 'memories/a:b.md'
expect 'DOTAGENTS_VERIFY_TIMEOUT=0' 3 env DOTAGENTS_VERIFY_TIMEOUT=0 sh "$VERIFY" lint
expect 'DOTAGENTS_VERIFY_TIMEOUT=00 (R43)' 3 env DOTAGENTS_VERIFY_TIMEOUT=00 sh "$VERIFY" lint
expect 'DOTAGENTS_VERIFY_TIMEOUT=abc' 3 env DOTAGENTS_VERIFY_TIMEOUT=abc sh "$VERIFY" lint
expect 'IFS herdado do ambiente (SEC-014)' 0 env IFS=x sh "$VERIFY" lint
expect 'GREP_OPTIONS=-v neutralizado' 0 env GREP_OPTIONS=-v sh "$VERIFY" lint
no_canary 'lint'

# ---------------------------------------------------------------- semântica de glob (E5)
new_repo globs
glob_case() { # glob · path · esperado (ativo | nenhum)
  printf '# Índice\n\n| Arquivo | Globs | Resumo | Atualizado |\n|---|---|---|---|\n| checkout-padrao-verificavel.md | %s | x | [2026-03-01] |\n' "$1" > memories/implementations/INDEX.md
  entry '[2026-03-01][Task 003] checkout sem float' PADRAO_VERIFICAVEL "$1" 'NUNCA parseFloat em checkout' "\`grep -rqF -e 'parseFloat' src/checkout; test \$? -eq 1\`" docs/done/003-x/ > memories/implementations/checkout-padrao-verificavel.md
  verify fragments "$2" > "$WORK/out" 2>&1
  case $3 in ativo) want='FRAGMENTO ATIVO' ;; *) want='FRAGMENTOS ATIVOS: nenhum' ;; esac
  if grep -qF "$want" "$WORK/out"; then ok; else ko "glob $1 × $2 → $3"; fi
}
glob_case '*' 'qualquer/coisa.ts' ativo
glob_case '*.md' 'README.md' ativo
glob_case '*.md' 'docs/README.md' nenhum
glob_case '**/*.md' 'README.md' ativo
glob_case '**/*.md' 'a/b/c.md' ativo
glob_case 'src/**' 'src/a/b.ts' ativo
glob_case 'src/**' 'srcx/a.ts' nenhum
glob_case 'src/*.ts' 'src/a/b.ts' nenhum
glob_case 'src/?.ts' 'src/a.ts' ativo
glob_case 'src/?.ts' 'src/ab.ts' nenhum
glob_case 'a.b' 'axb' nenhum

# ---------------------------------------------------------------- diff, ativação e execução no snapshot
new_repo exec
expect 'diff sem mudanças' 0 verify diff
has 'diff sem mudanças' 'FRAGMENTOS ATIVOS: nenhum'
printf 'parseFloat(1)\n' > src/checkout/n.ts
printf 'TODO\n' >> lib/b.ts
expect 'diff com violação em untracked e em modificado' 1 verify diff
has 'fragmento ativado por arquivo untracked' 'FRAGMENTO ATIVO: memories/implementations/checkout-padrao-verificavel.md'
has 'violação no fragmento' 'checkout sem float'
lacks 'entrada SUPERSEDED não roda' 'sem console.log'
lacks 'template não é memória' 'PWN_TEMPLATE'
rm src/checkout/n.ts && git checkout -q -- lib/b.ts
expect 'fragments com paths planejados (normaliza ./ e vírgula)' 0 verify fragments ./src/checkout/x.ts, docs/a.md
has 'fragments com paths planejados (normaliza ./ e vírgula)' 'FRAGMENTO ATIVO'
expect 'fragments sem match' 0 verify fragments docs/a.md
has 'fragments sem match' 'FRAGMENTOS ATIVOS: nenhum'

if [ "$HAS_RG" = 1 ]; then
  printf 'console.log(1)\n' > src/v.ts && printf 'src/\n' > .gitignore && git add -f src/v.ts .gitignore && git commit -qm v
  expect '.gitignore não esconde arquivo rastreado (R32)' 1 verify diff
  git reset -q --hard HEAD~1
  printf 'console.log(1)\n' > src/.hidden.ts
  expect 'arquivo oculto é buscado (R32)' 1 verify diff
  rm src/.hidden.ts
  printf 'console.log(1)\n' > src/v.ts && printf '*\n' > src/.ignore
  expect '.ignore do diff não esconde violação (SEC-006a)' 1 verify diff
  rm src/v.ts src/.ignore
else
  skip 'formas rg no snapshot' 'ripgrep ausente' 3
fi

printf 'SECRET=A\n' > .env && printf '.env\n' > .gitignore && git add .gitignore && git commit -qm ignore
for guess in A Z; do
  reset_guidelines
  entry "[2026-05-05][Task 009] oráculo $guess" PADRAO_VERIFICAVEL '*' 'NUNCA segredo' "\`grep -rqF -e 'SECRET=$guess' .env; test \$? -eq 1\`" | append
  expect "arquivo ignorado não é visível ao Verify-Cmd (SEC-003, palpite $guess)" 3 verify run "[2026-05-05][Task 009] oráculo $guess"
  has "arquivo ignorado não é visível ao Verify-Cmd (SEC-003, palpite $guess)" 'erro do comando'
done
mkdir -p "$WORK/outside" && printf 'SECRET=A\n' > "$WORK/outside/key"
ln -s "$WORK/outside/key" cfg && ln -s .git lnk && git add cfg lnk && git commit -qm links
for target in cfg lnk/config; do
  reset_guidelines
  entry '[2026-05-05][Task 009] symlink' PADRAO_VERIFICAVEL '*' 'NUNCA segredo' "\`grep -rqF -e 'SECRET=A' $target; test \$? -eq 1\`" | append
  expect "symlink versionado fora do snapshot ($target, SEC-003/R33)" 3 verify run '[2026-05-05][Task 009] symlink'
  # o link não chega ao snapshot (o grep não acha o path), e não é barrado por outra checagem
  has "symlink versionado fora do snapshot ($target, SEC-003/R33)" 'erro do comando'
done
reset_guidelines

entry '[2026-05-05][Task 009] regex inválido' PADRAO_VERIFICAVEL '*' 'NUNCA x' "\`grep -rqE -e '(' src; test \$? -eq 1\`" | append
expect 'erro do comando vira 🚨, não violação (D5)' 3 verify run '[2026-05-05][Task 009] regex inválido'
has 'erro do comando vira 🚨, não violação (D5)' 'erro do comando'
printf 'x\n' > "$WORK/qualquer.txt"
expect 'erro do comando na contraprova vira 🚨 (E5)' 3 verify probe '[2026-05-05][Task 009] regex inválido' "$WORK/qualquer.txt"
reset_guidelines
entry '[2026-05-05][Task 009] usar \d+ em ids' PADRAO_VERIFICAVEL 'src/**' 'NUNCA \d+ cru' "\`grep -rqE -e 'zzz' src; test \$? -eq 1\`" | append
expect 'título com barra invertida no run (D6/I-5)' 0 verify run '[2026-05-05][Task 009] usar \d+ em ids'
reset_guidelines
entry '[2026-05-05][Task 009] presença' PADRAO_VERIFICAVEL 'src/**' 'SEMPRE ok em src' "\`grep -rqF -e 'ok' src\`" | append
expect 'forma Presença conforme' 0 verify run '[2026-05-05][Task 009] presença'
printf 'zzz\n' > "$WORK/violador.txt"
expect 'contraprova da Presença detecta' 0 verify probe '[2026-05-05][Task 009] presença' "$WORK/violador.txt"
printf 'console.log(1)\n' > "$WORK/trecho.txt"
expect 'contraprova da Proibição detecta' 0 verify probe '[2026-02-01][Task 002] sem console' "$WORK/trecho.txt"
expect 'contraprova da Proibição não detecta trecho limpo' 1 verify probe '[2026-02-01][Task 002] sem console' "$WORK/violador.txt"
expect 'arquivo de contraprova iniciado por - (SEC-009)' 3 verify probe '[2026-02-02][Task 002] sem TODO em lib' -n
expect 'run de entrada N/A (R57)' 0 verify run '[2026-02-03][Task 002] nomes de domínio'
has 'run de entrada N/A (R57)' 'N/A: nada a executar'
expect 'probe de entrada N/A' 0 verify probe '[2026-02-03][Task 002] nomes de domínio' "$WORK/trecho.txt"
reset_guidelines

entry '[2026-05-05][Task 009] lento' PADRAO_VERIFICAVEL 'src/**' 'NUNCA lento' "\`rg --no-config -q -e 'lento' src/; test \$? -eq 1\`" | append
mkdir -p "$WORK/fakebin" && printf '#!/bin/sh\nsleep 5\n' > "$WORK/fakebin/rg" && chmod +x "$WORK/fakebin/rg"
expect 'timeout vira 🚨 no run' 3 env PATH="$WORK/fakebin:$PATH" DOTAGENTS_VERIFY_TIMEOUT=1 sh "$VERIFY" run '[2026-05-05][Task 009] lento'
has 'timeout vira 🚨 no run' 'timeout (1 s)'
expect 'timeout vira 🚨 no probe (R42)' 3 env PATH="$WORK/fakebin:$PATH" DOTAGENTS_VERIFY_TIMEOUT=1 sh "$VERIFY" probe '[2026-05-05][Task 009] lento' "$WORK/trecho.txt"
has 'timeout vira 🚨 no probe (R42)' 'timeout (1 s) na contraprova'
mkdir -p "$WORK/minibin"
for tool in sh git awk sed grep sort cut find tr wc mktemp cat cp cmp od xargs dirname head timeout rm mkdir; do
  ln -sf "$(command -v "$tool")" "$WORK/minibin/$tool"
done
expect 'rg ausente vira 🚨' 3 env PATH="$WORK/minibin" "$WORK/minibin/sh" "$VERIFY" run '[2026-05-05][Task 009] lento'
has 'rg ausente vira 🚨' 'comando indisponível (rg'
reset_guidelines
cp -R "$WORK/minibin" "$WORK/notimeout" && rm "$WORK/notimeout/timeout"
expect 'timeout ausente avisa (E5)' 0 env PATH="$WORK/notimeout" "$WORK/notimeout/sh" "$VERIFY" run '[2026-02-02][Task 002] sem TODO em lib'
has 'timeout ausente avisa (E5)' 'timeout ausente'
printf 'x\n' > "src/que
bra.ts"
expect 'path com quebra de linha no diff (check_names, E5)' 3 verify diff
has 'path com quebra de linha no diff (check_names, E5)' 'quebra de linha'
rm "src/que
bra.ts"

printf '### [2026-02-02][Task 002] sem TODO em lib [SUPERSEDED em 2026-05-05]\n' > "$WORK/sup"
sed 's/^### \[2026-02-02\]\[Task 002\] sem TODO em lib$/### [2026-02-02][Task 002] sem TODO em lib [SUPERSEDED em 2026-05-05]/' "$WORK/guidelines.base" > memories/guidelines.md
expect 'SUPERSEDED adicionado no diff avisa (SEC-009c)' 0 verify diff
has 'SUPERSEDED adicionado no diff avisa (SEC-009c)' 'entrada desativada neste diff'
reset_guidelines
no_canary 'execução'

new_repo snapshot
printf 'ok\n' > 'src/barra\invertida.ts' && git add -A && git commit -qm barra
printf 'console.log(1)\n' > src/v.ts
expect 'nome com barra invertida no snapshot (R62)' 1 verify diff
has 'nome com barra invertida no snapshot (R62)' 'sem console'
rm src/v.ts
mkdir -p "$WORK/cpfake"
for tool in cp cpio; do printf '#!/bin/sh\necho "%s chamado" >&2\nexit 99\n' "$tool" > "$WORK/cpfake/$tool" && chmod +x "$WORK/cpfake/$tool"; done
new_repo lazy
printf 'x\n' > docs.md
expect 'sem entrada aplicável o snapshot não é montado (R63)' 0 env PATH="$WORK/cpfake:$PATH" sh "$VERIFY" diff
has 'sem entrada aplicável o snapshot não é montado (R63)' 'nenhum Verify-Cmd aplicável'
printf 'x\n' >> src/a.ts
expect 'com entrada aplicável o snapshot é montado' 3 env PATH="$WORK/cpfake:$PATH" sh "$VERIFY" diff
has 'com entrada aplicável o snapshot é montado' 'cópia para o snapshot falhou'

new_repo sem-indice
rm -f .git/index
printf 'TODO\n' >> lib/b.ts
expect 'repositório sem .git/index monta o snapshot (R71)' 1 verify diff
has 'repositório sem .git/index monta o snapshot (R71)' 'sem TODO em lib'

# cp não-GNU (BSD/macOS): rejeita de fato as opções GNU, como o cp real faria
REALCP=$(command -v cp)
mkdir -p "$WORK/bsdcp" "$WORK/nocpio" "$WORK/cpiofail"
cat > "$WORK/bsdcp/cp" <<EOF
#!/bin/sh
for arg; do case \$arg in --) ;; --*|-t) echo "cp: illegal option -- \$arg" >&2; echo 'usage: cp [-R] source target' >&2; exit 64 ;; esac; done
exec $REALCP "\$@"
EOF
chmod +x "$WORK/bsdcp/cp"
# cpio sem modo pass-through (-p), como o do busybox: a sonda falha e a montagem cai no laço
printf '#!/bin/sh\necho "cpio: invalid option -- p" >&2\nexit 1\n' > "$WORK/nocpio/cpio" && chmod +x "$WORK/nocpio/cpio"
# cpio que passa na sonda (lista vazia) e falha na cópia
printf '#!/bin/sh\nread -r first || exit 0\necho "cpio: falha injetada" >&2\necho "1 block" >&2\nexit 2\n' > "$WORK/cpiofail/cpio" && chmod +x "$WORK/cpiofail/cpio"
new_repo copia-portavel
mkdir -p 'src/sub dir' && printf 'console.log(1)\n' > 'src/sub dir/f.ts'
if command -v cpio >/dev/null 2>&1; then
  expect 'snapshot sem GNU cp, com cpio (cópia única) detecta violação (SEC-038/F16)' 1 env PATH="$WORK/bsdcp:$PATH" sh "$VERIFY" diff
  has 'snapshot sem GNU cp, com cpio (cópia única) detecta violação (SEC-038/F16)' 'sem console'
else
  skip 'snapshot com cpio' 'cpio ausente' 2
fi
expect 'snapshot sem GNU cp e sem cpio -p (laço com cp) detecta violação (F16)' 1 env PATH="$WORK/bsdcp:$WORK/nocpio:$PATH" sh "$VERIFY" diff
has 'snapshot sem GNU cp e sem cpio -p (laço com cp) detecta violação (F16)' 'sem console'
expect 'falha do cpio na montagem vira 🚨' 3 env PATH="$WORK/bsdcp:$WORK/cpiofail:$PATH" sh "$VERIFY" diff
has 'falha do cpio na montagem vira 🚨' 'cópia para o snapshot falhou'
lacks 'falha do cpio na montagem: 🚨 sem a linha "1 block" (F27)' '1 block'
# GNU cp que falha na cópia (D12): a falha do xargs não pode passar em silêncio
mkdir -p "$WORK/gnufail"
printf '#!/bin/sh\ncase "$1" in --version) echo "cp (GNU coreutils) 9.9"; exit 0 ;; esac\necho "cp: falha injetada" >&2\nexit 1\n' > "$WORK/gnufail/cp" && chmod +x "$WORK/gnufail/cp"
expect 'falha do GNU cp na montagem vira 🚨 (D12)' 3 env PATH="$WORK/gnufail:$PATH" sh "$VERIFY" diff
has 'falha do GNU cp na montagem vira 🚨 (D12)' 'cópia para o snapshot falhou'
# montagem lenta fica sob o DOTAGENTS_VERIFY_TIMEOUT (SEC-038)
mkdir -p "$WORK/slowcp"
printf '#!/bin/sh\ncase "$1" in --version) echo "cp (GNU coreutils) 9.9"; exit 0 ;; esac\nsleep 5\n' > "$WORK/slowcp/cp" && chmod +x "$WORK/slowcp/cp"
expect 'montagem do snapshot sob timeout (SEC-038)' 3 env PATH="$WORK/slowcp:$PATH" DOTAGENTS_VERIFY_TIMEOUT=1 sh "$VERIFY" diff
has 'montagem do snapshot sob timeout (SEC-038)' 'timeout (1 s) na montagem do snapshot'
# cp que deixa um diretório 555 no snapshot e falha: o trap remove o temporário mesmo assim (F11)
mkdir -p "$WORK/rocp" "$WORK/tmp-ro"
cat > "$WORK/rocp/cp" <<'EOF'
#!/bin/sh
case "$1" in --version) echo "cp (GNU coreutils) 9.9"; exit 0 ;; esac
while [ $# -gt 0 ]; do [ "$1" = -t ] && { mkdir -p "$2/preso/dentro" && chmod 555 "$2/preso"; break; }; shift; done
exit 1
EOF
chmod +x "$WORK/rocp/cp"
if [ "$IS_ROOT" = 1 ]; then
  skip 'temporário com diretório 555' 'executando como root' 2
else
  expect 'cp que falha deixando diretório 555' 3 env PATH="$WORK/rocp:$PATH" TMPDIR="$WORK/tmp-ro" sh "$VERIFY" diff
  if [ -z "$(ls -A "$WORK/tmp-ro")" ]; then ok; else chmod -R u+rwX "$WORK/tmp-ro"; ko 'temporário com diretório 555 removido pelo trap (F11)'; fi
fi
rm -rf 'src/sub dir'
# diretório de origem 555 com vários arquivos: cp --parents copiaria o modo e falharia no segundo arquivo (F11)
if [ "$IS_ROOT" = 1 ]; then
  skip 'diretório de origem 555' 'executando como root' 3
else
  mkdir -p src/ro && printf 'console.log(1)\n' > src/ro/v.ts && printf 'x\n' > src/ro/w.ts && git add -A && git commit -qm ro && chmod 555 src/ro
  expect 'diretório de origem 555 no snapshot (F11)' 1 env TMPDIR="$WORK/tmp-ro" sh "$VERIFY" diff
  has 'diretório de origem 555 no snapshot (F11)' 'sem console'
  chmod 755 src/ro
  if [ -z "$(ls -A "$WORK/tmp-ro")" ]; then ok; else chmod -R u+rwX "$WORK/tmp-ro"; ko 'temporário removido após snapshot de diretório 555 (F11)'; fi
fi

new_repo literal
printf 'console.log(1)\n' > 'src/ev\151l.ts' && printf 'SECRET=A\n' > .env && printf '.env\n' > .gitignore && printf 'outro\n' > '.en\166'
git add -A && git commit -qm literal
expect 'nome com escape literal é buscado como está (SEC-018)' 1 verify diff
has 'nome com escape literal é buscado como está (SEC-018)' 'sem console'
reset_guidelines
entry '[2026-05-05][Task 009] oráculo literal' PADRAO_VERIFICAVEL '*' 'NUNCA segredo' "\`grep -rqF -e 'SECRET=A' .env; test \$? -eq 1\`" | append
expect 'nome .en\\166 não traz o .env ignorado (SEC-018)' 3 verify run '[2026-05-05][Task 009] oráculo literal'
reset_guidelines


# ---------------------------------------------------------------- base, paths, deps
new_repo git
expect 'base resolve o merge-base' 0 verify base
has 'base resolve o merge-base' "$(git merge-base HEAD main)"
expect 'DOTAGENTS_BASE_BRANCH inválido' 3 env DOTAGENTS_BASE_BRANCH='-x' sh "$VERIFY" base
git checkout -q -b develop main && printf 'd\n' > d.txt && git add d.txt && git commit -qm develop && git checkout -q feat && git merge -q --no-edit develop
expect 'DOTAGENTS_BASE_BRANCH=develop (D24)' 0 env DOTAGENTS_BASE_BRANCH=develop sh "$VERIFY" base
has 'DOTAGENTS_BASE_BRANCH=develop usa o merge-base com develop (E5)' "$(git merge-base HEAD refs/heads/develop)"
lacks 'DOTAGENTS_BASE_BRANCH=develop não usa main (E5)' "$(git merge-base HEAD refs/heads/main)"
printf 'y\n' > ' lead.ts' && printf 'z\n' > src/novo.ts && ln -s "$WORK/outside/key" src/link.ts && git rm -q lib/b.ts
expect 'paths' 0 verify paths
has 'paths inclui untracked' 'src/novo.ts'
has 'paths preserva espaço inicial (R39/SEC-016)' ' lead.ts'
lacks 'paths exclui symlink (SEC-010)' 'src/link.ts'
lacks 'paths exclui deletado' 'lib/b.ts'
sh "$VERIFY" paths -z | tr '\0' '\n' > "$WORK/out"
has 'paths -z' 'src/novo.ts'
mkdir -p sub && cd sub
expect 'subdiretório sem memories/ e fora da raiz (R40/D2)' 3 verify paths
cd "$REPO"
rm -f ' lead.ts' src/novo.ts src/link.ts && git checkout -q -- lib/b.ts 2>/dev/null; git reset -q --hard

new_repo nested
mkdir -p scope/memories scope/src && printf '# G\n' > scope/memories/guidelines.md && git add -A && git commit -qm scope
printf 'n\n' > scope/src/n.ts && printf 'r\n' > src/root.ts
cd scope
expect 'escopo aninhado: paths relativos ao escopo' 0 verify paths
has 'escopo aninhado: paths relativos ao escopo' 'src/n.ts'
lacks 'escopo aninhado: arquivo fora do escopo' 'root.ts'
cd "$REPO"

new_repo deps
git checkout -q main
printf '{"v":1}\n' > package.json && printf 'lock1\n' > yarn.lock && printf 'go\n' > go.sum && git add -A && git commit -qm deps
git checkout -q -B feat main
git checkout -q main && printf '{"v":"main-tip"}\n' > package.json && git add -A && git commit -qm main-tip && git checkout -q feat
printf '{"v":2}\n' > package.json && git rm -q yarn.lock && git commit -qm 'remove lockfile'
git rm -q go.sum
printf 'novo\n' > Cargo.toml
mkdir -p ':' '*' 'p$(touch PWN_SHELL)' && printf 'a\n' > ':/package.json' && printf 'b\n' > '*/package.json' && printf 'c\n' > 'p$(touch PWN_SHELL)/package.json'
expect 'deps inclui deleção commitada (SEC-012/R35)' 0 verify deps
has 'deps inclui deleção commitada (SEC-012/R35)' 'yarn.lock'
has 'deps inclui deleção não commitada' 'go.sum'
has 'deps inclui manifesto novo' 'Cargo.toml'
expect 'deps-revert' 0 verify deps-revert
if [ "$(cat package.json)" = '{"v":1}' ]; then ok; else ko 'deps-revert usa o merge-base, não a ponta da main (SEC-017/R36)'; fi
if [ -f yarn.lock ] && [ -f go.sum ]; then ok; else ko 'deps-revert restaura lockfiles deletados'; fi
if [ ! -e Cargo.toml ] && [ ! -e ':/package.json' ] && [ ! -e '*/package.json' ]; then ok; else ko 'deps-revert remove manifestos ausentes no merge-base'; fi
if [ -e PWN_SHELL ] || [ -e 'p$(touch PWN_SHELL)/PWN_SHELL' ]; then ko 'deps-revert com nomes maliciosos (SEC-011) — canário criado'; else ok; fi

new_repo shadow
printf 'mudou\n' >> src/a.ts && git commit -qam feat
git tag main HEAD && git tag origin/HEAD HEAD
expect 'tag homônima não sombreia a branch base (SEC-019)' 0 verify base
has 'tag homônima não sombreia a branch base (SEC-019)' "$(git merge-base HEAD refs/heads/main)"
expect 'diff com tag main sombreando continua vendo o diff (SEC-019)' 0 verify paths
has 'diff com tag main sombreando continua vendo o diff (SEC-019)' 'src/a.ts'
expect 'DOTAGENTS_BASE_BRANCH multilinha (SEC-019)' 3 env DOTAGENTS_BASE_BRANCH="$(printf 'main\n;x')" sh "$VERIFY" base

new_repo parent-link
git checkout -q main && mkdir -p sub && printf 'x = 1\n' > sub/creds.py && git add -A && git commit -qm creds && git checkout -q -B feat main
mkdir -p "$WORK/other" && printf 'TOKEN = (\n' > "$WORK/other/creds.py"
rm -rf sub && ln -s "$WORK/other" sub
git diff --name-only "$(git merge-base HEAD main)" | grep -qx 'sub/creds.py' && [ -f sub/creds.py ] && ok || { printf 'montagem: sub/creds.py deveria estar no diff e acessível pelo symlink\n' > "$WORK/out"; ko 'montagem do caso SEC-020'; }
expect 'paths não segue diretório-pai que virou symlink (SEC-020)' 0 verify paths
lacks 'paths não segue diretório-pai que virou symlink (SEC-020)' 'sub/creds.py'

new_repo weaken
sed '/^### \[2026-02-02\]\[Task 002\] sem TODO em lib$/,/^- \*\*Origem/d' "$WORK/guidelines.base" > memories/guidelines.md
expect 'entrada removida no diff avisa (SEC-023)' 0 verify diff
has 'entrada removida no diff avisa (SEC-023)' 'entrada removida ou alterada neste diff'

new_repo ctrl
printf '| check\033]0;x\007out-padrao-verificavel.md | src/** | x | [d] |\n' >> memories/implementations/INDEX.md
expect 'ESC no INDEX não chega à saída (SEC-009d)' 3 verify lint
if grep -q "$(printf '\033')" "$WORK/out"; then ko 'ESC no INDEX chegou à saída (SEC-009d)'; else ok; fi

new_repo deps-mv
git checkout -q main && printf 'l\n' > yarn.lock && printf 'g\n' > go.mod && git add -A && git commit -qm deps && git checkout -q -B feat main
git mv yarn.lock yarn.lock.old && git mv go.mod sub_go.mod
expect 'git mv de manifesto aparece como deleção (E2)' 0 verify deps
has 'git mv de manifesto aparece como deleção (E2)' 'yarn.lock'
has 'git mv de manifesto aparece como deleção (E2) — go.mod' 'go.mod'
# renomeação só na working tree (git add -N): nem o índice nem os não rastreados a mostram — só o diff da working tree com --no-renames
git reset -q --hard && mv yarn.lock yarn.lock.old && git add -N yarn.lock.old
expect 'renomeação só na working tree (git add -N) aparece como deleção (E2/F43)' 0 verify deps
if grep -qx 'yarn.lock' "$WORK/out"; then ok; else ko 'renomeação só na working tree (git add -N) lista o manifesto deletado (E2/F43)'; fi

new_repo deps-link
git checkout -q main && mkdir -p sub && printf 'base\n' > sub/package.json && git add -A && git commit -qm sub && git checkout -q -B feat main
mkdir -p "$WORK/alvo" && printf 'fora do repo\n' > "$WORK/alvo/package.json"
rm -rf sub && ln -s "$WORK/alvo" sub
expect 'deps lista o manifesto sob diretório que virou symlink' 0 verify deps
has 'deps lista o manifesto sob diretório que virou symlink' 'sub/package.json'
expect 'deps-revert recusa escrever através de diretório-pai symlink' 3 verify deps-revert
has 'deps-revert recusa escrever através de diretório-pai symlink' 'diretório que virou symlink'
if [ "$(cat "$WORK/alvo/package.json")" = 'fora do repo' ]; then ok; else ko 'arquivo fora do repo alterado pelo deps-revert'; fi

new_repo deps-literal
git checkout -q main && printf 'raiz\n' > package.json && git add -A && git commit -qm raiz && git checkout -q -B feat main
mkdir -p ':' && printf 'novo\n' > ':/package.json'
expect 'deps-revert com pathspec literal' 0 verify deps-revert
if [ "$(cat package.json 2>/dev/null)" = raiz ] && [ ! -e ':/package.json' ]; then ok; else ko 'deps-revert remove só :/package.json e preserva o da raiz (GIT_LITERAL_PATHSPECS, E5)'; fi

# ---------------------------------------------------------------- autoverificação do verificador
new_repo self
mkdir -p .claude/hooks && cp "$VERIFY" .claude/hooks/dotagents-verify.sh
expect 'verificador novo (instalação) avisa e segue (D8)' 0 sh .claude/hooks/dotagents-verify.sh paths
has 'verificador novo (instalação) avisa e segue (D8)' 'sem versão no merge-base'
git checkout -q main && git add -A && git commit -qm install && git checkout -q -B feat main
printf '# alterado\n' >> .claude/hooks/dotagents-verify.sh
expect 'verificador alterado bloqueia (SEC-007/SEC-013)' 3 sh .claude/hooks/dotagents-verify.sh paths
has 'verificador alterado bloqueia (SEC-007/SEC-013)' 'difere do merge-base'
expect 'verificador alterado bloqueia também o run (SEC-013)' 3 sh .claude/hooks/dotagents-verify.sh run '[2026-02-02][Task 002] sem TODO em lib'
expect 'verificador alterado bloqueia também o lint (SEC-013)' 3 sh .claude/hooks/dotagents-verify.sh lint
expect 'verificador alterado bloqueia também o fragments (R75)' 3 sh .claude/hooks/dotagents-verify.sh fragments src/a.ts
expect 'verificador alterado bloqueia o run de entrada N/A (R75)' 3 sh .claude/hooks/dotagents-verify.sh run '[2026-02-03][Task 002] nomes de domínio'
expect 'verificador alterado bloqueia o probe de entrada N/A (R75)' 3 sh .claude/hooks/dotagents-verify.sh probe '[2026-02-03][Task 002] nomes de domínio' "$WORK/trecho.txt"
mkdir -p scope/memories && printf '# G\n' > scope/memories/guidelines.md
cd scope
expect 'verificador da raiz alterado bloqueia em escopo aninhado (SEC-013)' 3 sh ../.claude/hooks/dotagents-verify.sh paths
cd "$REPO"
git show "$(git merge-base HEAD main)":./.claude/hooks/dotagents-verify.sh > "$WORK/verify-base.sh"
git stash -q
mkdir -p "$WORK/nocmp"
for tool in sh git awk sed grep sort cut find tr wc mktemp cat cp xargs dirname head timeout rm mkdir; do
  ln -sf "$(command -v "$tool")" "$WORK/nocmp/$tool"
done
expect 'cmp ausente vira 🚨 de ferramenta, não falso "difere" (R74)' 3 env PATH="$WORK/nocmp" "$WORK/nocmp/sh" .claude/hooks/dotagents-verify.sh lint
has 'cmp ausente vira 🚨 de ferramenta, não falso "difere" (R74)' 'comando indisponível (cmp)'
lacks 'cmp ausente vira 🚨 de ferramenta, não falso "difere" (R74)' 'difere do merge-base'
git stash pop -q
git checkout -q -- .claude/hooks/dotagents-verify.sh
sed '10s/$/\r/' .claude/hooks/dotagents-verify.sh > "$WORK/cr.sh" && cat "$WORK/cr.sh" > .claude/hooks/dotagents-verify.sh && printf '*.sh text eol=lf\n' > .gitattributes
expect 'CR + eol=lf não disfarça verificador alterado (SEC-027)' 3 sh .claude/hooks/dotagents-verify.sh paths
git checkout -q -- .claude/hooks/dotagents-verify.sh && rm .gitattributes
expect 'versão do merge-base, fora do repo, roda' 0 sh "$WORK/verify-base.sh" paths

new_repo sem-base
git branch -q -m main develop
expect 'lint com verificador fora do repo não exige branch padrão (R75)' 0 verify lint
cd "$WORK" && rm -rf vazio && mkdir -p vazio/memories vazio/.claude/hooks && cd vazio && git init -q && cp "$VERIFY" .claude/hooks/dotagents-verify.sh
printf '# G\n' > memories/guidelines.md
expect 'repositório sem commits: lint avisa e segue (R75)' 0 sh .claude/hooks/dotagents-verify.sh lint
has 'repositório sem commits: lint avisa e segue (R75)' 'sem commits'

# ---------------------------------------------------------------- snippets das skills (copiados literalmente)
snippet() { # skill · marcador inicial (regex sed) · marcador final (regex sed)
  sed -n "/$2/,/$3/p" "$HERE/skills/$1/SKILL.md" | sed "s#{{AGENTS_ROOT}}/hooks/dotagents-verify.sh#$VERIFY#g"
}
AST=$(snippet ast-validator '^python3 - "{{AGENTS_ROOT}}\/hooks\/dotagents-verify.sh" <<.PY.$' '^PY$')
PYC=$(snippet state-checkpoint '^python3 - "{{AGENTS_ROOT}}\/hooks\/dotagents-verify.sh" <<.PY.$' '^PY$')
DEPS=$(grep -F 'dotagents-verify.sh deps-revert' "$HERE/skills/dependency-lock/SKILL.md")
if [ -z "$AST" ] || [ -z "$PYC" ] || [ -z "$DEPS" ]; then
  printf 'snippet não encontrado: ast=%s pyc=%s deps=%s\n' "${#AST}" "${#PYC}" "${#DEPS}" > "$WORK/out"; ko 'snippets das skills extraídos'
else
  new_repo py
  printf 'x = 1\n' > ok.py && git add ok.py && git commit -qm py
  expect 'ast-validator sem .py no diff' 0 sh -c "$AST"
  printf 'x = (\n' > 'quebrado arq.py' && printf 'y = 2\n' > novo.py && git rm -q ok.py
  expect 'ast-validator acusa arquivo quebrado com espaço no nome' 1 sh -c "$AST"
  has 'ast-validator acusa arquivo quebrado com espaço no nome' 'quebrado arq.py:1'
  expect 'state-checkpoint acusa arquivo quebrado' 1 sh -c "$PYC"
  has 'state-checkpoint aponta arquivo:linha' 'quebrado arq.py:1'
  if find . -name '__pycache__' | grep -q .; then ko 'state-checkpoint não grava __pycache__ (SEC-010)'; else ok; fi
  rm 'quebrado arq.py'
  expect 'ast-validator com arquivos válidos' 0 sh -c "$AST"
  expect 'state-checkpoint com arquivos válidos' 0 sh -c "$PYC"
  cd "$WORK" && rm -rf nobase && mkdir nobase && cd nobase && git init -q && git symbolic-ref HEAD refs/heads/dev && mkdir memories
  expect 'ast-validator sem base propaga 🚨' 3 sh -c "$AST"
  has 'ast-validator sem base propaga 🚨' 'branch padrão não resolvida'
  expect 'state-checkpoint sem base propaga 🚨' 3 sh -c "$PYC"
fi

# ---------------------------------------------------------------- rollback do state-checkpoint e executor por extensão
ROLLBACK=$(sed -n '/^# 0. O reset --hard/,/^git status$/p' "$HERE/skills/state-checkpoint/SKILL.md")
EXECUTOR=$(sed -n '/^python3 - "{{AGENTS_ROOT}}\/hooks\/dotagents-verify.sh" \.js/,/^PY$/p' "$HERE/skills/ast-validator/SKILL.md" | sed "s#{{AGENTS_ROOT}}/hooks/dotagents-verify.sh#$VERIFY#g")
if [ -z "$ROLLBACK" ] || [ -z "$EXECUTOR" ]; then
  printf 'snippet não encontrado: rollback=%s executor=%s\n' "${#ROLLBACK}" "${#EXECUTOR}" > "$WORK/out"; ko 'snippets de rollback e executor extraídos'
else
  new_repo rollback
  git tag dotagents/checkpoint-20260101-000000
  git checkout -q -b outra main && printf 'x\n' > fora.txt && git add fora.txt && git commit -qm fora && git tag dotagents/checkpoint-99991231-235959 && git checkout -q feat
  git rev-parse -q --verify refs/tags/dotagents/checkpoint-99991231-235959 >/dev/null && ok || { printf 'tag fora do histórico não criada\n' > "$WORK/out"; ko 'montagem do caso SEC-022'; }
  mkdir -p docs/todo && printf 'log\n' > docs/todo/task.md && git add -A && git commit -qm docs
  printf 'quebrou\n' >> src/a.ts && printf 'novo\n' > src/novo.ts && printf 'log 2\n' >> docs/todo/task.md
  expect 'rollback sem CHECKPOINT definido aborta' 3 sh -c "$ROLLBACK"
  expect 'rollback com checkpoint inexistente aborta' 3 env CHECKPOINT=dotagents/checkpoint-nao-existe sh -c "$ROLLBACK"
  expect 'checkpoint fora do histórico da branch aborta (SEC-022)' 3 env CHECKPOINT=dotagents/checkpoint-99991231-235959 sh -c "$ROLLBACK"
  has 'checkpoint fora do histórico da branch aborta (SEC-022)' 'fora do histórico da branch'
  if grep -q quebrou src/a.ts && [ -f src/novo.ts ]; then ok; else ko 'rollback abortado preserva o trabalho'; fi
  expect 'rollback restaura o checkpoint' 0 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  if [ "$(cat src/a.ts)" = ok ] && [ ! -e src/novo.ts ]; then ok; else ko 'rollback descarta código e órfãos'; fi
  if grep -q 'log 2' docs/todo/task.md; then ok; else ko 'rollback preserva docs/ (R59)'; fi
  first=$(git for-each-ref --format='%(refname)' refs/dotagents/ | grep -F 'refs/dotagents/backup-checkpoint-20260101-000000-')
  if [ -n "$first" ] && git cat-file -e "$first:src/novo.ts" 2>/dev/null; then ok; else ko 'backup do rollback inclui arquivo novo'; fi
  sleep 1
  printf 'segunda\n' > src/outro.ts
  expect 'segundo rollback para o mesmo checkpoint' 0 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  if [ "$(git for-each-ref --format='%(refname)' refs/dotagents/ | grep -cF 'refs/dotagents/backup-checkpoint-20260101-000000-')" -eq 2 ]; then ok; else ko 'segundo rollback não sobrescreve o primeiro backup (SEC-030)'; fi
  new_repo rollback-apagado
  mkdir -p docs && printf 'a\n' > docs/a.md && printf 'b\n' > docs/b.md && git add -A && git commit -qm docs && git tag dotagents/checkpoint-20260101-000000
  rm docs/b.md && printf 'quebrou\n' >> src/a.ts
  expect 'rollback com arquivo apagado em docs/' 0 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  if [ ! -e docs/b.md ] && [ -f docs/a.md ] && [ "$(cat src/a.ts)" = ok ]; then ok; else ko 'arquivo apagado durante a task não reaparece no rollback (SEC-039)'; fi
  new_repo rollback-quebra
  git tag dotagents/checkpoint-20260101-000000
  mkdir -p "docs/x
y" && printf 'z\n' > "docs/x
y/f.md" && printf 'quebrou\n' >> src/a.ts
  expect 'diretório com quebra de linha aborta o rollback antes do reset (SEC-040)' 3 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  if grep -q quebrou src/a.ts; then ok; else ko 'rollback abortado antes do reset preserva o código (SEC-040)'; fi
  new_repo rollback-escopo
  git tag dotagents/checkpoint-20260101-000000
  mkdir -p docs/todo scope/docs && printf 'raiz\n' > docs/todo/task.md && printf 'escopo\n' > scope/docs/x.md && git add -A && git commit -qm docs
  printf 'raiz 2\n' >> docs/todo/task.md && printf 'escopo 2\n' >> scope/docs/x.md && printf 'quebrou\n' >> src/a.ts
  printf '%s\n' "$ROLLBACK" > "$WORK/rollback.sh"
  (cd scope && env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh "$WORK/rollback.sh") > "$WORK/out" 2>&1
  if grep -q 'raiz 2' docs/todo/task.md && grep -q 'escopo 2' scope/docs/x.md && [ "$(cat src/a.ts)" = ok ]; then ok; else ko 'rollback em escopo aninhado preserva docs/ de todos os escopos (SEC-031)'; fi
  new_repo rollback-falha
  git tag dotagents/checkpoint-20260101-000000
  mkdir -p .git/refs/dotagents && : > .git/refs/dotagents/backup-checkpoint-20260101-000000.lock
  printf 'trabalho\n' > src/novo.ts && printf 'mudou\n' >> src/a.ts
  if [ "$IS_ROOT" = 1 ]; then
    skip 'backup que falha (chmod 000)' 'executando como root' 3
  else
    chmod 000 .git/refs/dotagents
    expect 'backup que falha aborta o rollback (R59)' 3 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
    chmod 755 .git/refs/dotagents
    has 'backup que falha aborta o rollback (R59)' 'backup falhou'
    if [ -f src/novo.ts ] && grep -q mudou src/a.ts; then ok; else ko 'rollback abortado não descarta trabalho (R59)'; fi
  fi

  new_repo executor
  mkdir -p "$WORK/npxbin" && printf '#!/bin/sh\nprintf "npx %%s\\n" "$*"\n' > "$WORK/npxbin/npx" && chmod +x "$WORK/npxbin/npx"
  expect 'executor por extensão sem arquivos .js' 0 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
  has 'executor por extensão sem arquivos .js' 'nenhum arquivo .js no diff'
  printf 'x\n' > 'src/com espaco.js'
  expect 'executor por extensão chama a ferramenta com os arquivos' 0 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
  has 'executor por extensão chama a ferramenta com os arquivos' 'src/com espaco.js'
  printf 'x\n' > 'src/-h.js'
  expect 'executor entrega opções ao eslint e prefixa arquivos com ./ (SEC-037)' 0 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
  has 'executor entrega opções ao eslint e prefixa arquivos com ./ (SEC-037)' 'npx --no -- eslint'
  has 'executor prefixa arquivo iniciado por - (SEC-037)' './src/-h.js'
  cd "$WORK/nobase"
  expect 'executor por extensão propaga 🚨 sem base (R60)' 3 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
fi

# ---------------------------------------------------------------- controles adicionais (mutantes sobreviventes do QA, F1)
new_repo f1
lint_file() { # descrição · exit · texto · arquivo · conteúdo (stdin)
  cat > "$4"; expect "$1" "$2" verify lint; [ -n "$3" ] && has "$1" "$3"
}
entry '[2026-05-05][Task 009] d' DOMINIO '*' 'SE a ENTÃO b' "\`grep -rqF -e 'x' src; test \$? -eq 1\`" | lint_file 'DOMINIO com comando executável' 3 'DOMINIO exige' memories/business.md
entry '[2026-05-05][Task 009] d' DOMINIO '*' 'SE a ENTÃO b' '`N/A`' | lint_file 'DOMINIO em business.md' 0 '' memories/business.md
entry '[2026-05-05][Task 009] p' PADRAO_SEMANTICO '*' 'SEMPRE x' '`N/A — m`' | lint_file 'PADRAO em business.md' 3 'Tipo incompatível' memories/business.md
entry '[2026-05-05][Task 009] a' ARQUITETURA '*' 'SEMPRE x' '`N/A`' | lint_file 'ARQUITETURA com N/A sem motivo' 3 'N/A sem motivo' memories/architecture.md
entry '[2026-05-05][Task 009] a' DOMINIO '*' 'SE a ENTÃO b' '`N/A`' | lint_file 'DOMINIO em architecture.md' 3 'Tipo incompatível' memories/architecture.md
printf '# Negócio\n' > memories/business.md && printf '# Arquitetura\n' > memories/architecture.md
for case in 'dominio DOMINIO 0' 'arquitetura ARQUITETURA 0' 'dominio ARQUITETURA 3' 'arquitetura DOMINIO 3'; do
  set -- $case
  if [ "$2" = DOMINIO ]; then cmd='`N/A`'; rule='SE a ENTÃO b'; else cmd='`N/A — m`'; rule='SEMPRE x'; fi
  entry '[2026-05-05][Task 009] f' "$2" 'src/**' "$rule" "$cmd" > "memories/implementations/x-$1.md"
  cp "$WORK/index.base" memories/implementations/INDEX.md 2>/dev/null || true
  printf '| x-%s.md | src/** | x | [2026-05-05] |\n' "$1" >> memories/implementations/INDEX.md
  expect "fragmento -$1 com Tipo $2" "$3" verify lint
  rm "memories/implementations/x-$1.md"; git checkout -q -- memories/implementations/INDEX.md
done
entry '[2026-05-05][Task 009] f' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > memories/implementations/semnome.md
printf '| semnome.md | src/** | x | [2026-05-05] |\n' >> memories/implementations/INDEX.md
expect 'fragmento fora da nomeação' 3 verify lint
has 'fragmento fora da nomeação' 'fora da nomeação'
rm memories/implementations/semnome.md; git checkout -q -- memories/implementations/INDEX.md
{ entry '[2026-05-05][Task 009] a' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`'; entry '[2026-05-05][Task 010] b' PADRAO_SEMANTICO 'lib/**' 'SEMPRE x' '`N/A — m`'; } > "$WORK/entry"
reset_guidelines; append < "$WORK/entry"
expect 'mesma Regra com Escopo diferente não é duplicata' 0 verify lint
{ entry '[2026-05-05][Task 009] a' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`'; entry '[2026-05-05][Task 010] b' PADRAO_VERIFICAVEL 'src/**' 'SEMPRE x' "\`grep -rqF -e 'x' src; test \$? -eq 1\`"; } > "$WORK/entry"
reset_guidelines; append < "$WORK/entry"
expect 'mesma Regra com Tipo diferente não é duplicata' 0 verify lint
reset_guidelines
printf -- '- **Verify-Cmd:** `N/A`\n' > memories/orfa.md
expect 'Verify-Cmd fora de uma entrada' 3 verify lint
has 'Verify-Cmd fora de uma entrada' 'fora de uma entrada'
rm memories/orfa.md
printf '<!--\n| fantasma.md | src/** | x | [2026-05-05] |\n-->\n' >> memories/implementations/INDEX.md
expect 'linha de tabela dentro de comentário do INDEX é ignorada' 0 verify lint
git checkout -q -- memories/implementations/INDEX.md
printf '| checkout-padrao-verificavel.md | src/checkout/** |  | [2026-03-01] |\n' > "$WORK/row"
sed '$d' memories/implementations/INDEX.md > "$WORK/idx" && cat "$WORK/idx" "$WORK/row" > memories/implementations/INDEX.md
expect 'INDEX sem resumo' 3 verify lint
has 'INDEX sem resumo' 'INDEX sem resumo'
git checkout -q -- memories/implementations/INDEX.md
printf '| inexistente-padrao-semantico.md | src/** | x | [2026-03-01] |\n' >> memories/implementations/INDEX.md
expect 'INDEX aponta fragmento inexistente' 3 verify lint
has 'INDEX aponta fragmento inexistente' 'fragmento inexistente'
git checkout -q -- memories/implementations/INDEX.md
entry '[2026-02-31][Task 009] e' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
expect 'data 31 de fevereiro no título (F5)' 3 verify lint
entry '[2028-02-29][Task 009] e' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
expect 'data 29 de fevereiro em ano bissexto' 0 verify lint
reset_guidelines
sed '$d' memories/implementations/INDEX.md > "$WORK/idx" && { cat "$WORK/idx"; printf '| checkout-padrao-verificavel.md | src/checkout/** | x | [2026-02-30] |\n'; } > memories/implementations/INDEX.md
expect 'data 30 de fevereiro no INDEX (F5)' 3 verify lint
git checkout -q -- memories/implementations/INDEX.md
: > "memories/que
bra.md"
expect 'nome com quebra de linha em memories/ (F6)' 3 verify lint
has 'nome com quebra de linha em memories/ (F6)' 'quebra de linha em memories'
rm "memories/que
bra.md"
for form in "rg --no-config -q -i -w -U -g '*.ts' -t ts -e 'x' src" "grep -rqE -i -w -e 'x' src; test \$? -eq 1" "grep -rqF -e 'x' src" "test ! -e 'src/nao'" "test -e 'src/a.ts'"; do
  entry '[2026-05-05][Task 009] forma' PADRAO_VERIFICAVEL 'src/**' 'NUNCA x' "\`$form\`" > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
  expect "forma aceita pela gramática: $form" 0 verify lint
done
reset_guidelines
for case in "test -e 'src/a.ts'|0" "test -e 'src/nao.ts'|1" "test ! -e 'src/a.ts'|1" "test ! -e 'src/nao.ts'|0"; do
  form=${case%|*}; want=${case##*|}
  entry '[2026-05-05][Task 009] estrutural' PADRAO_VERIFICAVEL 'src/**' 'SEMPRE estrutura' "\`$form\`" > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
  expect "forma Estrutural: $form" "$want" verify run '[2026-05-05][Task 009] estrutural'
done
expect 'probe da forma Estrutural não se aplica' 0 verify probe '[2026-05-05][Task 009] estrutural' "$WORK/trecho.txt"
has 'probe da forma Estrutural não se aplica' 'forma Estrutural'
reset_guidelines
{ entry '[2026-05-05][Task 009] igual' PADRAO_SEMANTICO 'src/**' 'SEMPRE a' '`N/A — m`'; entry '[2026-05-05][Task 009] igual' PADRAO_SEMANTICO 'lib/**' 'SEMPRE b' '`N/A — m`'; } > "$WORK/entry"; append < "$WORK/entry"
expect 'run com título ambíguo' 3 verify run '[2026-05-05][Task 009] igual'
has 'run com título ambíguo' 'ambíguo'
reset_guidelines
entry '[2026-05-05][Task 009] pipe | no título' PADRAO_VERIFICAVEL 'src/**' 'NUNCA zzz' "\`grep -rqF -e 'zzz' src; test \$? -eq 1\`" > "$WORK/entry"; append < "$WORK/entry"
expect 'pipe no título escapado na tabela' 0 verify run '[2026-05-05][Task 009] pipe | no título'
has 'pipe no título escapado na tabela' 'pipe \| no título'
ln -s "$WORK/trecho.txt" "$WORK/trecho-link.txt"
expect 'arquivo de contraprova symlink' 3 verify probe '[2026-05-05][Task 009] pipe | no título' "$WORK/trecho-link.txt"
reset_guidelines
entry '[2026-05-05][Task 009] arq' ARQUITETURA 'lib/**' 'NUNCA zzz em lib' "\`grep -rqF -e 'zzz' lib; test \$? -eq 1\`" > memories/architecture.md
printf 'zzz\n' >> lib/b.ts
expect 'entrada de architecture.md roda no diff' 1 verify diff
has 'entrada de architecture.md roda no diff' 'arq'
git checkout -q -- lib/b.ts memories/architecture.md
sed 's/NUNCA TODO em lib/NUNCA TODO nem FIXME em lib/; s/TODO|FIXME/XXXX/' "$WORK/guidelines.base" > memories/guidelines.md
expect 'Verify-Cmd alterado no diff avisa (SEC-023)' 0 verify diff
has 'Verify-Cmd alterado no diff avisa (SEC-023)' 'entrada removida ou alterada neste diff'
printf 'memories/** -diff\n' > .gitattributes
expect 'aviso de regra alterada resiste a -diff no .gitattributes (SEC-029)' 0 verify diff
has 'aviso de regra alterada resiste a -diff no .gitattributes (SEC-029)' 'entrada removida ou alterada neste diff'
rm .gitattributes; reset_guidelines
printf 'x\n' > "src/ctrl$(printf '\033')x.ts"
expect 'caractere de controle em nome do diff' 3 verify paths
has 'caractere de controle em nome do diff' 'caractere de controle'
rm "src/ctrl$(printf '\033')x.ts"
printf 'segredo\n' > ignorado.txt && printf 'ignorado.txt\n' > .gitignore
expect 'paths respeita --exclude-standard' 0 verify paths
lacks 'paths respeita --exclude-standard' 'ignorado.txt'
rm ignorado.txt .gitignore
printf 'a\n' > poetry.lock && printf 'b\n' > Pipfile.lock
expect 'deps inclui poetry.lock e Pipfile.lock' 0 verify deps
has 'deps inclui poetry.lock' 'poetry.lock'
has 'deps inclui Pipfile.lock' 'Pipfile.lock'
rm poetry.lock Pipfile.lock
if [ "$HAS_RG" = 1 ]; then
  printf 'a\000\nconsole.log(1)\n' > src/bin.ts
  expect 'binário com violação após NUL é buscado (-uuu)' 1 verify diff
  rm src/bin.ts
else
  skip 'binário com violação (-uuu)' 'ripgrep ausente' 1
fi
printf 'console.log(1)\n' > src/f.ts && printf 'src/*.ts filter=esconde\n' > .gitattributes && git config filter.esconde.clean 'sed s/console/xxxxxxx/'
expect 'filtro de .gitattributes não esconde violação do snapshot (SEC-028)' 1 verify diff
has 'filtro de .gitattributes não esconde violação do snapshot (SEC-028)' 'sem console'
rm src/f.ts .gitattributes; git config --unset filter.esconde.clean

new_repo shadow-full
git tag refs/remotes/origin/HEAD HEAD 2>/dev/null; git tag refs/heads/master HEAD 2>/dev/null
printf 'mudou\n' >> src/a.ts && git commit -qam feat && git tag -f refs/remotes/origin/HEAD HEAD >/dev/null
expect 'tag com nome de ref completo não sombreia a base (SEC-026)' 0 verify base
has 'tag com nome de ref completo não sombreia a base (SEC-026)' "$(git merge-base HEAD refs/heads/main)"

new_repo origin-head
printf 'atacante\n' >> src/a.ts && git commit -qam atacante
git update-ref refs/remotes/origin/HEAD HEAD
expect 'origin/HEAD como ref comum é ignorado (SEC-034)' 0 verify base
has 'origin/HEAD como ref comum é ignorado (SEC-034)' "$(git merge-base HEAD refs/heads/main)"
git update-ref -d refs/remotes/origin/HEAD && git update-ref refs/remotes/origin/main refs/heads/main && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
expect 'origin/HEAD como symref é aceito' 0 verify base
has 'origin/HEAD como symref é aceito' "$(git merge-base HEAD refs/remotes/origin/main)"

new_repo encoding
printf 'memories/*.md working-tree-encoding=UTF-16LE\n' > .gitattributes
expect 'working-tree-encoding em memories/ (SEC-035)' 3 verify lint
has 'working-tree-encoding em memories/ (SEC-035)' 'working-tree-encoding em memories'
printf 'src/*.ts working-tree-encoding=UTF-16LE\n' > .gitattributes
printf 'console.log(1)\n' >> src/a.ts
expect 'working-tree-encoding em arquivo verificado (SEC-035)' 3 verify diff
has 'working-tree-encoding em arquivo verificado (SEC-035)' 'working-tree-encoding em arquivo verificado'
expect 'GIT_ATTR_SOURCE do ambiente não esconde o atributo da working tree (F22)' 3 env GIT_ATTR_SOURCE=HEAD sh "$VERIFY" diff
has 'GIT_ATTR_SOURCE do ambiente não esconde o atributo da working tree (F22)' 'working-tree-encoding em arquivo verificado'
rm .gitattributes && git checkout -q -- src/a.ts
printf '# G\000\n' > memories/nul.md
expect 'byte NUL em memória (SEC-035)' 3 verify lint
has 'byte NUL em memória (SEC-035)' 'byte NUL'
rm memories/nul.md

new_repo eol-only
git checkout -q main && mkdir -p scripts && printf 'set -e\nOUT=dist/app.js\n' > scripts/build.sh && git add -A && git commit -qm build && git checkout -q -B feat main
{ printf 'set -e\r\nOUT=dist/app.js\r\n' > scripts/build.sh && git add scripts/build.sh && git commit -qm crlf
  printf '*.sh text eol=lf\n' > .gitattributes && git add .gitattributes && git commit -qm eol; } 2> "$WORK/git-noise"
# índice "stat-dirty": o git relê o arquivo, normaliza CRLF→LF e o diff da working tree deixa de listá-lo
sleep 1 && touch scripts/build.sh
git diff --name-only "$(git merge-base HEAD main)" 2> "$WORK/git-noise" | grep -qx 'scripts/build.sh' && { printf 'montagem: o diff da working tree já lista o arquivo — o caso não isola o diff árvore a árvore\n' > "$WORK/out"; ko 'montagem do caso SEC-036'; } || ok
verify paths > "$WORK/out" 2>/dev/null
# só o stdout, linha exata: o aviso de CRLF do git (stderr) também cita o arquivo
if grep -qx 'scripts/build.sh' "$WORK/out"; then ok; else ko 'commit que só troca fins de linha continua no diff (SEC-036)'; fi
# índice de volta à versão do merge-base: só o diff árvore a árvore (merge-base × HEAD) ainda lista o arquivo
git reset -q "$(git merge-base HEAD main)" -- scripts/build.sh 2> "$WORK/git-noise"
verify paths > "$WORK/out" 2>/dev/null
if grep -qx 'scripts/build.sh' "$WORK/out"; then ok; else ko 'commit que só troca fins de linha, com o índice revertido, continua no diff (SEC-036)'; fi

new_repo master-tag
git branch -q -m main master
printf 'atacante\n' >> src/a.ts && git commit -qam atacante && git tag refs/heads/main HEAD
expect 'tag chamada refs/heads/main não sombreia master (SEC-026)' 0 verify base
has 'tag chamada refs/heads/main não sombreia master (SEC-026)' "$(git merge-base HEAD refs/heads/master)"

new_repo lit-index
git checkout -q main && printf 'raiz\n' > package.json && git add -A && git commit -qm raiz && git checkout -q -B feat main
mkdir -p ':' && printf 'novo\n' > ':/package.json'
expect 'deps-revert com : no nome' 0 verify deps-revert
if git ls-files --error-unmatch package.json >/dev/null 2>&1 && [ -z "$(git status --porcelain -- package.json)" ]; then ok; else ko 'deps-revert preserva package.json da raiz no índice (GIT_LITERAL_PATHSPECS no git rm)'; fi

# ---------------------------------------------------------------- controles adicionais, rodada 2 (mutantes sobreviventes do QA)
REALGIT=$(command -v git)
mkdir -p "$WORK/gitfail"
cat > "$WORK/gitfail/git" <<EOF
#!/bin/sh
case " \$* " in *"\$GIT_FAIL_MATCH"*)
  n=\$(cat "\$GIT_FAIL_COUNT" 2>/dev/null || echo 0); n=\$((n + 1)); echo "\$n" > "\$GIT_FAIL_COUNT"
  [ "\$n" -gt "\${GIT_FAIL_SKIP:-0}" ] && { echo "falha injetada: \$*" >&2; exit 97; } ;;
esac
exec $REALGIT "\$@"
EOF
chmod +x "$WORK/gitfail/git"
gitfail() { # trecho dos argumentos do git · modo · [chamadas que casam e passam antes da falha]
  rm -f "$WORK/gitfail.count"
  env PATH="$WORK/gitfail:$PATH" GIT_FAIL_MATCH="$1" GIT_FAIL_SKIP="${3:-0}" GIT_FAIL_COUNT="$WORK/gitfail.count" sh "$VERIFY" "$2"
}
new_repo falhas
printf 'TODO\n' >> lib/b.ts
expect 'falha de git diff vira 🚨' 3 gitfail 'diff --name-only -z --no-renames --relative' diff
expect 'falha de git ls-files --others vira 🚨' 3 gitfail 'ls-files -z --others' diff
expect 'falha de git ls-files do snapshot vira 🚨' 3 gitfail 'ls-files -z -co' diff
expect 'falha do diff de memories/ vira 🚨' 3 gitfail '-- memories' diff
mkdir -p "$WORK/awkfail" && printf '#!/bin/sh\nexit 97\n' > "$WORK/awkfail/awk" && chmod +x "$WORK/awkfail/awk"
expect 'falha de awk vira 🚨' 3 env PATH="$WORK/awkfail:$PATH" sh "$VERIFY" lint
has 'falha de awk vira 🚨' 'awk falhou'
mkdir -p "$WORK/mktempfail" && printf '#!/bin/sh\nexit 1\n' > "$WORK/mktempfail/mktemp" && chmod +x "$WORK/mktempfail/mktemp"
expect 'falha de mktemp vira 🚨' 3 env PATH="$WORK/mktempfail:$PATH" sh "$VERIFY" lint
has 'falha de mktemp vira 🚨' 'mktemp -d falhou'
mkdir -p "$WORK/tmpclean"
env TMPDIR="$WORK/tmpclean" sh "$VERIFY" diff > "$WORK/out" 2>&1
if [ -z "$(ls -A "$WORK/tmpclean")" ]; then ok; else ko 'temporário removido ao sair (trap EXIT)'; fi
git checkout -q -- lib/b.ts
git checkout -q --orphan solta && git commit -qm solta
expect 'histórias sem ancestral comum: sem merge-base vira 🚨' 3 verify paths
has 'histórias sem ancestral comum: sem merge-base vira 🚨' 'sem merge-base'

new_repo checkout-literal
git checkout -q main && mkdir -p ':' && printf '{"v":"base"}\n' > ':/package.json' && printf '{"v":"raiz"}\n' > package.json && git add -A && git commit -qm deps && git checkout -q -B feat main
printf '{"v":"alterado"}\n' > ':/package.json'
expect 'deps-revert de :/package.json alterado' 0 verify deps-revert
if [ "$(cat ':/package.json')" = '{"v":"base"}' ] && [ "$(cat package.json)" = '{"v":"raiz"}' ]; then ok; else ko 'git checkout com pathspec literal reverte o arquivo certo (GIT_LITERAL_PATHSPECS)'; fi

new_repo snapshot-nome
git checkout -q main && printf 'console.log(1)\n' > "src/a
b.ts" && git add -A && git commit -qm nome && git checkout -q -B feat main
printf 'x\n' >> src/a.ts
expect 'arquivo versionado com quebra de linha no nome bloqueia o snapshot' 3 verify diff
has 'arquivo versionado com quebra de linha no nome bloqueia o snapshot' 'quebra de linha'
git checkout -q -- . 2>/dev/null
# modo run (sem compute_changes): arquivo novo, não rastreado, com controle no nome só é barrado na lista do snapshot
new_repo snapshot-nome-novo
printf 'x\n' > "lib/ctrl$(printf '\033')x.ts"
expect 'arquivo novo com controle no nome bloqueia o snapshot do run' 3 verify run '[2026-02-02][Task 002] sem TODO em lib'
has 'arquivo novo com controle no nome bloqueia o snapshot do run' 'caractere de controle'

new_repo raizes
printf 'console.log(1)\n' > src/v.ts
for case in "src/*.ts" "sr*"; do
  entry '[2026-05-05][Task 009] raiz' PADRAO_VERIFICAVEL 'src/**' 'NUNCA console em src' "\`grep -rqF -e 'console' $case; test \$? -eq 1\`" > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
  expect "raiz do snapshot com curinga: $case" 1 verify run '[2026-05-05][Task 009] raiz'
done
rm src/v.ts
reset_guidelines
entry '[2026-05-05][Task 009] presença com erro' PADRAO_VERIFICAVEL 'src/**' 'SEMPRE ok' "\`grep -rqF -e 'ok' nao-existe\`" > "$WORK/entry"; append < "$WORK/entry"
expect 'Presença com erro do comando vira 🚨' 3 verify run '[2026-05-05][Task 009] presença com erro'
has 'Presença com erro do comando vira 🚨' 'erro do comando'
has 'coluna Exit mostra 3 no erro' '| 3 |'
reset_guidelines
printf '### [2026-05-05][Task 009] título \033[31mcolorido\n- **Tipo:** `PADRAO_VERIFICAVEL`\n- **Escopo (globs):** `src/**`\n- **Regra:** NUNCA zzz\n- **Verify-Cmd:** `grep -rqF -e %szzz%s src; test $? -eq 1`\n- **Origem:** `docs/done/009-x/`\n' "'" "'" | append
expect 'título com ESC' 0 verify run '[2026-05-05][Task 009] título ?[31mcolorido'
if grep -q "$(printf '\033')" "$WORK/out"; then ko 'ESC do título chega cru à tabela'; else ok; fi
reset_guidelines
mkdir -p "$WORK/umdir"
expect 'probe recusa diretório' 3 verify probe '[2026-02-02][Task 002] sem TODO em lib' "$WORK/umdir"
printf '#!/bin/sh\nexit 0\n' > "$WORK/fakediff" && chmod +x "$WORK/fakediff" && git config diff.external "$WORK/fakediff"
sed 's/^- \*\*Escopo (globs):\*\* `lib\/\*\*`$/- **Escopo (globs):** `lib\/x\/**`/' "$WORK/guidelines.base" > memories/guidelines.md
expect 'Escopo alterado avisa, mesmo com diff.external' 0 verify diff
has 'Escopo alterado avisa, mesmo com diff.external' 'entrada removida ou alterada neste diff'
git config --unset diff.external
reset_guidelines
sed '/^### \[2026-02-02\]\[Task 002\] sem TODO em lib$/{n;s/PADRAO_VERIFICAVEL/PADRAO_SEMANTICO/;}' "$WORK/guidelines.base" > memories/guidelines.md
expect 'PADRAO_SEMANTICO com Verify-Cmd executável reprova no lint (R83)' 3 verify lint
has 'PADRAO_SEMANTICO com Verify-Cmd executável reprova no lint (R83)' 'PADRAO_SEMANTICO exige'
sed '/^### \[2026-02-02\]\[Task 002\] sem TODO em lib$/,/^- \*\*Origem/{s/PADRAO_VERIFICAVEL/PADRAO_SEMANTICO/;s/^- \*\*Verify-Cmd:\*\* .*$/- **Verify-Cmd:** `N\/A — revisão humana`/;}' "$WORK/guidelines.base" > memories/guidelines.md
expect 'Tipo e Verify-Cmd rebaixados para PADRAO_SEMANTICO avisam a linha do Tipo (M10b)' 0 verify diff
has 'Tipo e Verify-Cmd rebaixados para PADRAO_SEMANTICO avisam a linha do Tipo (M10b)' 'entrada removida ou alterada neste diff: - **Tipo:** `PADRAO_VERIFICAVEL`'
reset_guidelines
mkdir -p docs && printf '### titulo\n' > docs/x.md && git add docs && git commit -qm docx && : > docs/x.md
expect 'remoção de ### fora de memories/ não avisa' 0 verify diff
lacks 'remoção de ### fora de memories/ não avisa' 'entrada removida ou alterada'
git checkout -q -- docs/x.md

new_repo glob-ancora
printf '# Índice\n\n| Arquivo | Globs | Resumo | Atualizado |\n|---|---|---|---|\n| checkout-padrao-verificavel.md | *.md | x | [2026-03-01] |\n' > memories/implementations/INDEX.md
entry '[2026-03-01][Task 003] checkout sem float' PADRAO_VERIFICAVEL '*.md' 'NUNCA parseFloat em checkout' "\`grep -rqF -e 'parseFloat' src/checkout; test \$? -eq 1\`" docs/done/003-x/ > memories/implementations/checkout-padrao-verificavel.md
verify fragments README.mdx > "$WORK/out" 2>&1
has 'glob *.md não casa README.mdx (âncora $)' 'FRAGMENTOS ATIVOS: nenhum'
printf '| ../business.md | src/** | x | [2026-03-01] |\n' >> memories/implementations/INDEX.md
expect 'INDEX com ../ no arquivo' 3 verify lint
has 'INDEX com ../ no arquivo' 'inexistente ou inválido'

new_repo datas
for case in '2026-04-31|3' '1900-02-29|3' '2000-02-29|0' '2026-06-30|0'; do
  date=${case%|*}; want=${case##*|}
  entry "[$date][Task 009] data" PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
  expect "data no título: $date" "$want" verify lint
done
reset_guidelines
for case in '2024-02-29|0' '2025-02-29|3' '2026-11-31|3'; do
  date=${case%|*}; want=${case##*|}
  sed '$d' memories/implementations/INDEX.md > "$WORK/idx" && { cat "$WORK/idx"; printf '| checkout-padrao-verificavel.md | src/checkout/** | x | [%s] |\n' "$date"; } > memories/implementations/INDEX.md
  expect "data no INDEX: $date" "$want" verify lint
  git checkout -q -- memories/implementations/INDEX.md
done
entry '[2026-05-05][Task 009] forma' PADRAO_VERIFICAVEL 'src/**' 'NUNCA x' "\`rg --no-config -q -F -e 'x' src\`" > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
expect "forma aceita: rg -F" 0 verify lint
entry '[2026-05-05][Task 009] e' PADRAO_SEMANTICO 'src/**, src/**' 'SEMPRE x' '`N/A — m`' > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
expect 'glob repetido no Escopo' 3 verify lint
for reason in "x'y" 'x"y' 'x`y'; do
  printf '### [2026-05-05][Task 009] motivo\n- **Tipo:** `PADRAO_SEMANTICO`\n- **Escopo (globs):** `src/**`\n- **Regra:** SEMPRE x\n- **Verify-Cmd:** `N/A — %s`\n- **Origem:** `docs/done/009-x/`\n' "$reason" > "$WORK/entry"; reset_guidelines; append < "$WORK/entry"
  expect "motivo de N/A com aspa ou crase: $reason" 3 verify lint
done
reset_guidelines
entry '[2026-03-03][Task 003] dois' PADRAO_SEMANTICO 'src/**' 'SEMPRE x' '`N/A — m`' > memories/implementations/ui-padrao-semantico-2.md
printf '| ui-padrao-semantico-2.md | src/** | ui | [2026-03-03] |\n' >> memories/implementations/INDEX.md
expect 'fragmento com sufixo -N' 0 verify lint
rm memories/implementations/ui-padrao-semantico-2.md; git checkout -q -- memories/implementations/INDEX.md
printf '### [2026-01-09][Task 010] legado só título\ntexto\n' | append
expect 'run não seleciona entrada legada' 3 verify run '[2026-01-09][Task 010] legado só título'
verify list > "$WORK/out" 2>/dev/null
lacks 'list mostra só entradas OK' 'legado só título'
reset_guidelines

new_repo base-remota
git update-ref refs/remotes/origin/develop refs/heads/main && git branch -q -m main trunk
expect 'DOTAGENTS_BASE_BRANCH=origin/develop via refs/remotes' 0 env DOTAGENTS_BASE_BRANCH=origin/develop sh "$VERIFY" base
has 'DOTAGENTS_BASE_BRANCH=origin/develop via refs/remotes' "$(git merge-base HEAD refs/remotes/origin/develop)"
expect 'base com argumento extra' 2 verify base x
expect 'paths com opção inválida' 2 verify paths -x

new_repo deps-escopo
git checkout -q main && mkdir -p scope/memories && printf '# G\n' > scope/memories/guidelines.md && printf '{"v":1}\n' > scope/package.json && git add -A && git commit -qm escopo && git checkout -q -B feat main
printf '{"v":2}\n' > scope/package.json
(cd scope && sh "$VERIFY" deps-revert) > "$WORK/out" 2>&1
if [ "$(cat scope/package.json)" = '{"v":1}' ]; then ok; else ko 'deps-revert em escopo aninhado usa o caminho relativo (:./)'; fi
for manifest in Gemfile.lock Cargo.lock pom.xml requirements.in pyproject.toml pnpm-lock.yaml package-lock.json; do printf 'x\n' > "$manifest"; done
verify deps > "$WORK/out" 2>&1
for manifest in Gemfile.lock Cargo.lock pom.xml requirements.in pyproject.toml pnpm-lock.yaml package-lock.json; do has "deps lista $manifest" "$manifest"; rm -f "$manifest"; done
git checkout -q -- scope/package.json
expect 'deps-revert sem manifesto no diff' 0 verify deps-revert
has 'deps-revert sem manifesto no diff' 'nenhum manifesto ou lockfile no diff'
if [ "$IS_ROOT" = 1 ]; then
  skip 'falha de rm no deps-revert (chmod 555)' 'executando como root' 1
else
  mkdir -p ro && printf 'x\n' > ro/package.json && chmod 555 ro
  expect 'falha de rm no deps-revert vira 🚨' 3 verify deps-revert
  chmod 755 ro && rm -rf ro
fi
printf 'x\n' >> src/a.ts && git add src/a.ts && git commit -qm muda && printf 'y\n' >> src/a.ts
verify paths > "$WORK/out" 2>&1
if [ "$(grep -c '^src/a.ts$' "$WORK/out")" -eq 1 ]; then ok; else ko 'paths sem duplicata (sort -u)'; fi

# ---------------------------------------------------------------- iteração 10 (F12/F13, SEC-041/042/043/039, R78, M73, D05/D06)
new_repo aspas
entry '[2026-05-05][Task 009] raiz' PADRAO_VERIFICAVEL '*' 'NUNCA zzpwn' "\`grep -rqF -e 'zzpwn' s*; test \$? -eq 1\`" | append
printf 'x\n' > '"a.ts' && git add -A && git commit -qm aspas
expect 'arquivo versionado iniciado por aspas na raiz não derruba o snapshot (F13)' 0 verify diff
lacks 'arquivo versionado iniciado por aspas na raiz não derruba o snapshot (F13)' 'badly quoted'
printf 'zzpwn\n' > '"x"' && git add -A && git commit -qm x
printf '?x? working-tree-encoding=UTF-16LE\n' > .gitattributes && git add .gitattributes && git commit -qm attr
rm '"x"' && git checkout -- '"x"'
if grep -q zzpwn '"x"'; then printf 'montagem: "x" deveria estar transcodificado em UTF-16LE\n' > "$WORK/out"; ko 'montagem do caso F12'; else ok; fi
expect 'working-tree-encoding em nome iniciado por aspas não escapa (F12)' 3 verify diff
has 'working-tree-encoding em nome iniciado por aspas não escapa (F12)' 'working-tree-encoding em arquivo verificado'
has '🚨 de encoding mostra o arquivo e o encoding (F20)' '("x": UTF-16LE)'
printf '?x? -working-tree-encoding\n' > .gitattributes && rm '"x"' && git checkout -- '"x"'
expect '-working-tree-encoding (unset) é aceito (R78)' 0 verify diff
lacks '-working-tree-encoding (unset) é aceito (R78)' 'working-tree-encoding em arquivo verificado'
printf 'memories/*.md -working-tree-encoding\n' > .gitattributes
expect '-working-tree-encoding em memories/ é aceito (R78)' 0 verify lint
rm .gitattributes

# checkout velho: o atributo sai do .gitattributes, mas o arquivo transcodificado fica no disco (o blob não mudou)
stale_checkout() { # arquivo · encoding — transcodifica no checkout e remove o atributo num commit seguinte
  { printf '%s working-tree-encoding=%s\n' "$1" "$2" > .gitattributes && git add .gitattributes && git commit -qm attr
    rm -- "$1" && git checkout -- "$1"
    # índice regravado 1 s depois do checkout: as entradas deixam de ser "racily clean" e o git confia no stat
    sleep 1 && git update-index -q --refresh
    git rm -q .gitattributes && git commit -qm 'remove o atributo'
  } 2> "$WORK/git-noise"
}
new_repo stale
printf 'console.log(1)\n' > src/v.ts && git add src/v.ts && git commit -qm v
stale_checkout src/v.ts UTF-16LE
if [ -z "$(git status --porcelain)" ] && ! grep -q console src/v.ts; then ok; else printf 'montagem: status=%s\n' "$(git status --porcelain)" > "$WORK/out"; ko 'montagem do caso SEC-041 (arquivo verificado)'; fi
expect 'checkout velho de arquivo verificado vira 🚨 (SEC-041)' 3 verify diff
has 'checkout velho de arquivo verificado vira 🚨 (SEC-041)' 'src/v.ts difere do blob do índice'
expect 'checkout velho detectado só com as ferramentas mínimas no PATH' 3 env PATH="$WORK/minibin" "$WORK/minibin/sh" "$VERIFY" diff
has 'checkout velho detectado só com as ferramentas mínimas no PATH' 'src/v.ts difere do blob do índice'
expect 'falha de git ls-files -s vira 🚨' 3 gitfail 'ls-files -s -z' diff 1
has 'falha de git ls-files -s vira 🚨' 'git ls-files -s falhou'
expect 'falha de git ls-files -m vira 🚨' 3 gitfail 'ls-files -m -z' diff 1
has 'falha de git ls-files -m vira 🚨' 'git ls-files -m falhou'
expect 'falha de git hash-object (cru) vira 🚨' 3 gitfail 'hash-object --no-filters' diff 1
has 'falha de git hash-object (cru) vira 🚨' 'git hash-object falhou'
expect 'falha de git hash-object (normalizado) vira 🚨' 3 gitfail 'hash-object -- ' diff
has 'falha de git hash-object (normalizado) vira 🚨' 'git hash-object falhou'
rm src/v.ts && git checkout -- src/v.ts
expect 'arquivo restaurado depois do checkout velho volta a ser verificado' 1 verify diff
has 'arquivo restaurado depois do checkout velho volta a ser verificado' 'sem console'

new_repo stale-mem
git checkout -q main
if printf 'a\n' | iconv -f UTF-8 -t UTF-7 >/dev/null 2>&1; then ENC=UTF-7; else ENC=UTF-16LE; fi
stale_checkout memories/guidelines.md "$ENC"
git checkout -q -B feat main
expect "checkout velho de memória ($ENC) vira 🚨 (SEC-041)" 3 verify lint
has "checkout velho de memória ($ENC) vira 🚨 (SEC-041)" 'memories/guidelines.md difere do blob do índice'
lacks "checkout velho de memória ($ENC) não é confundido com byte NUL" 'byte NUL'

# controles: transformações legítimas da checkout não são checkout velho
new_repo stale-controle
printf 'console.log(1)\n' > src/crlf.ts && git add src/crlf.ts && git commit -qm crlf
printf 'src/crlf.ts text eol=crlf\n' > .gitattributes && git add .gitattributes && git commit -qm eol && rm src/crlf.ts && git checkout -- src/crlf.ts
sleep 1 && git update-index -q --refresh
if grep -q "$(printf '\r')" src/crlf.ts; then ok; else printf 'montagem: src/crlf.ts deveria ter CRLF\n' > "$WORK/out"; ko 'montagem do controle eol=crlf'; fi
expect 'eol=crlf (normalizado = blob) não é checkout velho' 1 verify diff
has 'eol=crlf (normalizado = blob) não é checkout velho' 'sem console'
lacks 'eol=crlf (normalizado = blob) não é checkout velho' 'difere do blob do índice'
git config filter.maiusc.clean 'tr a-z A-Z' && git config filter.maiusc.smudge 'tr A-Z a-z'
printf 'src/f.ts filter=maiusc\n' >> .gitattributes && printf 'ok\n' > src/f.ts && git add -A && git commit -qm filtro
sleep 1 && git update-index -q --refresh
if [ "$(git cat-file blob HEAD:src/f.ts)" = OK ] && [ "$(cat src/f.ts)" = ok ]; then ok; else ko 'montagem do controle de filtro'; fi
expect 'filtro ativo (normalizado = blob) não é checkout velho' 1 verify diff
lacks 'filtro ativo (normalizado = blob) não é checkout velho' 'difere do blob do índice'
printf 'console.log(2)\n' >> src/crlf.ts
expect 'arquivo modificado pelo usuário não é checkout velho' 1 verify diff
lacks 'arquivo modificado pelo usuário não é checkout velho' 'difere do blob do índice'

# falhas de check-attr nos dois pontos: memórias (1ª chamada) e snapshot (2ª chamada) (D05/D06)
new_repo check-attr
printf 'TODO\n' >> lib/b.ts
expect 'falha de check-attr nas memórias vira 🚨 (D05)' 3 gitfail 'check-attr -z --stdin' lint
has 'falha de check-attr nas memórias vira 🚨 (D05)' 'git check-attr falhou'
expect 'falha de check-attr no snapshot vira 🚨 (D06)' 3 gitfail 'check-attr -z --stdin' diff 1
has 'falha de check-attr no snapshot vira 🚨 (D06)' 'git check-attr falhou'
lacks 'falha de check-attr no snapshot vira 🚨 (D06)' '| 1 |'

# deps-revert: falha do git checkout não passa em silêncio (M73)
new_repo deps-checkout
git checkout -q main && printf '{"v":1}\n' > package.json && git add -A && git commit -qm deps && git checkout -q -B feat main
printf '{"v":2}\n' > package.json
expect 'falha de git checkout no deps-revert vira 🚨 (M73)' 3 gitfail 'checkout -q' deps-revert
has 'falha de git checkout no deps-revert vira 🚨 (M73)' 'git checkout falhou: package.json'

# manifestos casados por nome, sem distinção de maiúsculas (SEC-042/F20, lista fechada D2) — um caso por nome da lista
new_repo deps-padrao
MANIFESTS='package.json package-lock.json npm-shrinkwrap.json pnpm-lock.yaml pnpm-workspace.yaml yarn.lock .npmrc .yarnrc .yarnrc.yml .pnpmfile.cjs
bun.lock bun.lockb bunfig.toml deno.json deno.jsonc deno.lock import_map.json
pyproject.toml setup.py setup.cfg Pipfile Pipfile.lock poetry.lock uv.lock pdm.lock requirements.txt requirements-dev.txt requirements.in requirements-test.in constraints.txt
pip.conf pip.ini environment.yml environment.yaml .condarc
go.mod go.sum go.work go.work.sum Cargo.toml Cargo.lock
pom.xml build.gradle build.gradle.kts settings.gradle settings.gradle.kts gradle.lockfile gradle/libs.versions.toml
gradle/wrapper/gradle-wrapper.properties .mvn/wrapper/maven-wrapper.properties build.sbt deps.edn project.clj
app/App.csproj app/App.fsproj app/App.vbproj packages.config packages.lock.json Directory.Packages.props Directory.Build.props Directory.Build.targets nuget.config global.json
composer.json composer.lock Gemfile Gemfile.lock app.gemspec mix.exs mix.lock pubspec.yaml pubspec.lock Package.swift Package.resolved ios/Podfile Podfile.lock
MODULE.bazel WORKSPACE WORKSPACE.bazel flake.nix flake.lock vcpkg.json conanfile.txt conanfile.py
requirements/base.txt requirements/dev.in sub/requirements/prod.txt sub/requirements/prod.in .yarn/releases/yarn-4.0.0.cjs .yarn/plugins/p.cjs sub/.yarn/releases/y.cjs
Requirements.txt sub/Package.JSON NuGet.Config
uv.toml pdm.toml gradle.properties gradle/wrapper/gradle-wrapper.jar gradlew gradlew.bat mvnw mvnw.cmd .mvn/wrapper/maven-wrapper.jar
.mvn/extensions.xml .mvn/maven.config sub/.mvn/jvm.config .cargo/config sub/.cargo/config.toml gems.rb gems.locked .bundle/config
.config/dotnet-tools.json paket.dependencies paket.lock pubspec_overrides.yaml vcpkg-configuration.json MODULE.bazel.lock conan.lock
Requirements/BASE.TXT .YARN/plugins/x.cjs sub/.yarn/plugins/p.cjs'
for manifest in $MANIFESTS; do mkdir -p "$(dirname "$manifest")" && printf 'x\n' > "$manifest"; done
printf 'x\n' > requirements-notas.md && printf 'x\n' > src/setup.py.bak && printf 'x\n' > constraints-negocio.txt && printf 'x\n' > src/yarn.lock.md
# nomes genéricos só na raiz do escopo; config só sob .cargo/ e .bundle/ (F36)
NOT_MANIFESTS='bin/workspace i18n/global.json docs/Environment.YML docs/environment.yaml docs/Project.CLJ sub/deps.edn sub/WORKSPACE.bazel src/config sub/.mvn/outro.xml'
for other in $NOT_MANIFESTS; do mkdir -p "$(dirname "$other")" && printf 'x\n' > "$other"; done
verify deps > "$WORK/out" 2>&1
for manifest in $MANIFESTS; do if grep -qxF -- "$manifest" "$WORK/out"; then ok; else ko "deps lista $manifest (SEC-042/F20)"; fi; done
for other in requirements-notas.md src/setup.py.bak constraints-negocio.txt src/yarn.lock.md; do lacks "deps não lista $other (F19)" "$other"; done
for other in $NOT_MANIFESTS; do if grep -qxF -- "$other" "$WORK/out"; then ko "deps não lista nome genérico fora da raiz: $other (F36)"; else ok; fi; done
expect 'deps-revert move manifesto novo para a quarentena (SEC-045)' 0 verify deps-revert
has 'deps-revert move manifesto novo para a quarentena (SEC-045)' 'movido para a quarentena (ausente no merge-base): requirements/base.txt'
if [ ! -e requirements/base.txt ] && [ ! -e app/App.csproj ] && [ -e requirements-notas.md ] && [ -e constraints-negocio.txt ]; then ok; else ko 'deps-revert tira da working tree só os manifestos (SEC-042)'; fi
quarantined=$(qfile worktree requirements/base.txt)
if [ -n "$quarantined" ] && [ "$(cat "$quarantined")" = x ]; then ok; else ko 'manifesto removido fica recuperável na quarentena (SEC-045)'; fi
mkdir -p scope/memories && printf '# G\n' > scope/memories/guidelines.md && git add scope && git commit -qm scope
printf 'x\n' > scope/requirements-dev.txt
(cd scope && sh "$VERIFY" deps-revert) > "$WORK/out" 2>&1
if [ ! -e scope/requirements-dev.txt ] && [ -f "$(qfile worktree requirements-dev.txt)" ]; then ok; else ko 'quarentena do deps-revert em escopo aninhado fica no .git do repositório (SEC-045)'; fi

# DOTAGENTS_BASE_BRANCH terminado em HEAD é ref comum (SEC-043)
new_repo base-head
git update-ref refs/remotes/origin/HEAD HEAD
for name in origin/HEAD HEAD; do
  expect "DOTAGENTS_BASE_BRANCH=$name recusado (SEC-043)" 3 env DOTAGENTS_BASE_BRANCH="$name" sh "$VERIFY" base
  has "DOTAGENTS_BASE_BRANCH=$name recusado (SEC-043)" 'não pode terminar em HEAD'
done
expect 'DOTAGENTS_BASE_BRANCH=HEADS (nome que só começa com HEAD) segue a resolução normal' 3 env DOTAGENTS_BASE_BRANCH=HEADS sh "$VERIFY" base
has 'DOTAGENTS_BASE_BRANCH=HEADS (nome que só começa com HEAD) segue a resolução normal' 'branch padrão não resolvida'

# rollback: docs/ aninhado apagado inteiro durante a task não ressuscita (SEC-039)
if [ -n "$ROLLBACK" ]; then
  new_repo rollback-docs-aninhado
  mkdir -p pkgs/x/docs pkgs/y/memories pkgs/z/docs docs/todo && printf 'x\n' > pkgs/x/docs/t.md && printf 'y\n' > pkgs/y/memories/m.md && printf 'z\n' > pkgs/z/docs/z.md && printf 'log\n' > docs/todo/task.md
  git add -A && git commit -qm docs && git tag dotagents/checkpoint-20260101-000000
  git rm -rq pkgs/x/docs pkgs/y/memories && git commit -qm 'apaga docs aninhados'
  rm -rf pkgs/z/docs && printf 'log 2\n' >> docs/todo/task.md && printf 'quebrou\n' >> src/a.ts
  expect 'rollback com docs/ aninhado apagado (SEC-039)' 0 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  if [ ! -e pkgs/x/docs ] && [ ! -e pkgs/y/memories ] && [ ! -e pkgs/z/docs ]; then ok; else ko 'docs/ e memories/ aninhados apagados pela task não reaparecem no rollback (SEC-039)'; fi
  if grep -q 'log 2' docs/todo/task.md && [ "$(cat src/a.ts)" = ok ]; then ok; else ko 'rollback preserva docs/ e restaura o código (SEC-039)'; fi
else
  skip 'rollback com docs/ aninhado' 'snippet ausente' 3
fi

# ---------------------------------------------------------------- iteração 11 (SEC-041 residual/F17, F18, R87, SEC-044/F25, F20, SEC-046)
new_repo stale-touch
printf 'console.log(1)\n' > src/v.ts && git add src/v.ts && git commit -qm v
stale_checkout src/v.ts UTF-16LE
touch src/v.ts
expect 'checkout velho em arquivo que o git vê como modificado (touch) vira 🚨 (F17)' 3 verify diff
has 'checkout velho em arquivo que o git vê como modificado (touch) vira 🚨 (F17)' 'src/v.ts está na working tree com NUL ou BOM'
rm src/v.ts && git checkout -- src/v.ts
printf 'x\n' > src/bom.ts && git add src/bom.ts && git commit -qm bom
printf '\377\376\101\116' > src/bom.ts
expect 'arquivo modificado com BOM UTF-16 sem NUL vira 🚨 (F17)' 3 verify diff
has 'arquivo modificado com BOM UTF-16 sem NUL vira 🚨 (F17)' 'src/bom.ts está na working tree com NUL ou BOM'
printf 'a\000b\n' > src/bom.ts
expect 'arquivo modificado com NUL que o blob não tem vira 🚨 (F17)' 3 verify diff
has 'arquivo modificado com NUL que o blob não tem vira 🚨 (F17)' 'src/bom.ts está na working tree com NUL ou BOM'
git checkout -q -- src/bom.ts
printf 'a\000b\n' > src/bin.dat && git add src/bin.dat && git commit -qm bin && printf 'c\000d\n' > src/bin.dat
expect 'binário com NUL modificado para outro binário não é checkout velho' 1 verify diff
lacks 'binário com NUL modificado para outro binário não é checkout velho' 'NUL ou BOM'
git checkout -q -- src/bin.dat
printf 'y\000\n' >> src/a.ts
expect 'falha de git cat-file no ramo dos modificados vira 🚨' 3 gitfail 'cat-file blob' diff
has 'falha de git cat-file no ramo dos modificados vira 🚨' 'git cat-file falhou: src/a.ts'
git checkout -q -- src/a.ts
# conflito binário: entradas de estágio 1/2/3 não são comparadas com a working tree (guarda de estágio 0, F20)
git checkout -q main && printf 'texto\n' > src/conf.dat && git add src/conf.dat && git commit -qm base-conf
git checkout -q -b lado && printf 'a\000lado\n' > src/conf.dat && git commit -qam lado
git checkout -q feat && git merge -q --no-edit main >/dev/null 2>&1 && printf 'a\000feat\n' > src/conf.dat && git commit -qam feat-bin
git merge -q --no-edit lado >/dev/null 2>&1
if git ls-files -u | grep -q conf.dat; then ok; else ko 'montagem do conflito binário'; fi
expect 'arquivo em conflito não é comparado pelos estágios 1/2/3 (F20)' 1 verify diff
lacks 'arquivo em conflito não é comparado pelos estágios 1/2/3 (F20)' 'NUL ou BOM'
git merge --abort 2>/dev/null

new_repo review
expect 'diff --review com merge-base = HEAD vira 🚨 (R87)' 3 verify diff --review
has 'diff --review com merge-base = HEAD vira 🚨 (R87)' 'merge-base igual a HEAD'
lacks 'o 🚨 do --review com merge-base = HEAD não diz que é normal (F46)' 'normal no review pré-commit'
has 'o 🚨 do --review com merge-base = HEAD orienta o review pré-commit (R108)' 'no review pré-commit da squad, rode diff sem --review no worktree do Developer'
expect 'diff com merge-base = HEAD avisa (R87)' 0 verify diff
has 'diff com merge-base = HEAD avisa (R87)' 'merge-base igual a HEAD'
has 'o ⚠️ de merge-base = HEAD explica o caso normal do pré-commit (F46)' 'normal no review pré-commit da squad'
has 'diff vazio avisa que nada foi verificado (SEC-052)' 'diff vazio: nenhum arquivo difere do merge-base, nada foi verificado'
printf 'TODO\n' >> lib/b.ts && git commit -qam todo
expect 'diff --review em worktree limpo roda os Verify-Cmd' 1 verify diff --review
has 'diff --review em worktree limpo roda os Verify-Cmd' 'sem TODO em lib'
lacks 'diff --review em worktree limpo não avisa merge-base' 'merge-base igual a HEAD'
printf 'novo\n' > novo.txt
expect 'diff --review com arquivo novo vira 🚨 (SEC-041)' 3 verify diff --review
has 'diff --review com arquivo novo vira 🚨 (SEC-041)' 'exige worktree limpo'
has 'o 🚨 de worktree sujo orienta o review pré-commit e o remoto canônico (R108/SEC-052)' 'num clone do remoto canônico; no review pré-commit da squad, rode diff sem --review no worktree do Developer'
git config status.showUntrackedFiles no
expect 'diff --review com status.showUntrackedFiles=no ainda vê o arquivo novo (F31/SEC-047/R94)' 3 verify diff --review
has 'diff --review com status.showUntrackedFiles=no ainda vê o arquivo novo (F31/SEC-047/R94)' '?? novo.txt'
git config --unset status.showUntrackedFiles
rm novo.txt && touch lib/b.ts && printf 'z\n' >> src/a.ts
expect 'diff --review com arquivo modificado vira 🚨 (SEC-041)' 3 verify diff --review
has 'diff --review com arquivo modificado vira 🚨 (SEC-041)' 'M src/a.ts'
git checkout -q -- src/a.ts
expect 'diff com opção inválida' 2 verify diff --x
rm -f "$WORK/gitfail.count"
expect 'falha de git status no --review vira 🚨' 3 env PATH="$WORK/gitfail:$PATH" GIT_FAIL_MATCH='status --porcelain' GIT_FAIL_COUNT="$WORK/gitfail.count" sh "$VERIFY" diff --review
has 'falha de git status no --review vira 🚨' 'git status falhou'
new_repo stale-mem-touch
git checkout -q main
if printf 'a\n' | iconv -f UTF-8 -t UTF-7 >/dev/null 2>&1; then ENC=UTF-7; else ENC=UTF-16LE; fi
stale_checkout memories/guidelines.md "$ENC"
git checkout -q -B feat main && printf 'v\n' >> src/a.ts && git commit -qam v && touch memories/guidelines.md
expect "memória com checkout velho vista como modificada: diff --review vira 🚨 (SEC-041)" 3 verify diff --review
has "memória com checkout velho vista como modificada: diff --review vira 🚨 (SEC-041)" 'exige worktree limpo'

# hash e leitura de conteúdo da checagem de checkout sob o timeout (F18)
new_repo checkout-timeout
mkdir -p "$WORK/gitslow"
cat > "$WORK/gitslow/git" <<EOF
#!/bin/sh
case " \$* " in *"\$GIT_SLOW_MATCH"*) sleep 5 ;; esac
exec $REALGIT "\$@"
EOF
chmod +x "$WORK/gitslow/git"
printf 'TODO\n' >> lib/b.ts
expect 'hash-object lento sob o timeout (F18)' 3 env PATH="$WORK/gitslow:$PATH" GIT_SLOW_MATCH='hash-object' DOTAGENTS_VERIFY_TIMEOUT=1 sh "$VERIFY" diff
has 'hash-object lento sob o timeout (F18)' 'timeout (1 s) na checagem de checkout'
# só arquivo com NUL ou bytes de BOM lê o blob (pré-filtro, R104)
printf 'x\000\n' >> lib/b.ts
expect 'leitura dos modificados sob o timeout (F18)' 3 env PATH="$WORK/gitslow:$PATH" GIT_SLOW_MATCH='cat-file blob' DOTAGENTS_VERIFY_TIMEOUT=1 sh "$VERIFY" diff
has 'leitura dos modificados sob o timeout (F18)' 'timeout (1 s) na checagem de checkout'

# memórias: as listas do git ficam restritas a memories/ (SEC-046)
new_repo lint-escopo
printf 'x\n' > "src/ctrl$(printf '\033')x.ts" && git add -A && git commit -qm ctrl
expect 'lint não lê nomes fora de memories/ (SEC-046)' 0 verify lint

# checagem externa do verificador, copiada literalmente da skill compound § 5 (SEC-044/F25)
EXTERNAL=$(sed -n '/^ *# checagem externa do verificador$/{n;p;}' "$HERE/skills/compound/SKILL.md" | sed 's/^ *//; s#<branch padrão>#main#g; s#<verificador>#.claude/hooks/dotagents-verify.sh#g')
if [ -z "$EXTERNAL" ]; then
  printf 'snippet da checagem externa não encontrado\n' > "$WORK/out"; ko 'snippet da checagem externa extraído'
else
  new_repo externa
  git checkout -q main && mkdir -p .claude/hooks && cp "$VERIFY" .claude/hooks/dotagents-verify.sh && git add -A && git commit -qm install && git checkout -q -B feat main
  git update-ref refs/remotes/origin/main refs/heads/main
  expect 'checagem externa: verificador igual ao merge-base' 0 sh -c "$EXTERNAL"
  has 'checagem externa: verificador igual ao merge-base' 'verificador conforme ao merge-base'
  mkdir -p sub && (cd sub && sh -c "$EXTERNAL") > "$WORK/out" 2>&1
  if grep -qF 'verificador conforme ao merge-base' "$WORK/out"; then ok; else ko 'checagem externa a partir de subdiretório (F25)'; fi
  printf '# alterado\n' >> .claude/hooks/dotagents-verify.sh && git commit -qam altera
  expect 'checagem externa: verificador alterado não é conforme' 1 sh -c "$EXTERNAL"
  lacks 'checagem externa: verificador alterado não é conforme' 'verificador conforme'
  git update-ref -d refs/remotes/origin/main
  expect 'checagem externa sem a branch remota falha fechada (SEC-044)' 128 sh -c "$EXTERNAL"
  lacks 'checagem externa sem a branch remota falha fechada (SEC-044)' 'verificador conforme'
  git tag origin/main HEAD && git tag main2 HEAD
  expect 'checagem externa: tag origin/main não sombreia a branch (SEC-044)' 128 sh -c "$EXTERNAL"
  lacks 'checagem externa: tag origin/main não sombreia a branch (SEC-044)' 'verificador conforme'
  # clone --single-branch: sem refs/remotes/origin/main, a tag refs/tags/refs/remotes/origin/main não vira âncora (SEC-044 residual)
  git tag refs/remotes/origin/main HEAD 2>/dev/null
  if git rev-parse -q --verify refs/tags/refs/remotes/origin/main >/dev/null; then ok; else printf 'tag refs/remotes/origin/main não criada\n' > "$WORK/out"; ko 'montagem do caso SEC-044 residual'; fi
  sh -c "$EXTERNAL" > "$WORK/out" 2>&1
  lacks 'checagem externa: tag refs/remotes/origin/main não substitui a branch remota ausente (SEC-044)' 'verificador conforme'
  # variante sem remoto (R106): refs/heads/<branch padrão> e DOTAGENTS_BASE_BRANCH=<branch padrão>
  EXTERNAL_LOCAL=$(sed -n '/^ *# checagem externa do verificador, sem remoto$/{n;p;}' "$HERE/skills/compound/SKILL.md" | sed 's/^ *//; s#<branch padrão>#main#g; s#<verificador>#.claude/hooks/dotagents-verify.sh#g')
  new_repo externa-local
  git checkout -q main && mkdir -p .claude/hooks && cp "$VERIFY" .claude/hooks/dotagents-verify.sh && git add -A && git commit -qm install && git checkout -q -B feat main
  expect 'checagem externa sem remoto: verificador igual ao merge-base (R106)' 0 sh -c "$EXTERNAL_LOCAL"
  has 'checagem externa sem remoto: verificador igual ao merge-base (R106)' 'verificador conforme ao merge-base'
  expect 'verificador com DOTAGENTS_BASE_BRANCH=main sem remoto usa o mesmo merge-base (R106)' 0 env DOTAGENTS_BASE_BRANCH=main sh .claude/hooks/dotagents-verify.sh base
  has 'verificador com DOTAGENTS_BASE_BRANCH=main sem remoto usa o mesmo merge-base (R106)' "$(git merge-base HEAD refs/heads/main)"
  printf '# alterado\n' >> .claude/hooks/dotagents-verify.sh && git commit -qam altera
  expect 'checagem externa sem remoto: verificador alterado não é conforme (R106)' 1 sh -c "$EXTERNAL_LOCAL"
  lacks 'checagem externa sem remoto: verificador alterado não é conforme (R106)' 'verificador conforme'
  # verificador sem versão no merge-base, vazio: cat-file -e falha antes do cmp (F32)
  new_repo externa-vazio
  mkdir -p .claude/hooks && : > .claude/hooks/dotagents-verify.sh && git add -A && git commit -qm vazio
  git update-ref refs/remotes/origin/main refs/heads/main
  sh -c "$EXTERNAL" > "$WORK/out" 2>&1
  lacks 'checagem externa: verificador vazio sem versão no merge-base não é conforme (F32)' 'verificador conforme'
fi

# rollback: quebra de linha em diretório que só existe no checkpoint também aborta (F20)
if [ -n "$ROLLBACK" ]; then
  new_repo rollback-quebra-checkpoint
  mkdir -p "docs/a
b" && printf 'z\n' > "docs/a
b/f.md" && git add -A && git commit -qm quebra && git tag dotagents/checkpoint-20260101-000000
  git rm -rq "docs/a
b" && git commit -qm remove && printf 'quebrou\n' >> src/a.ts
  expect 'diretório com quebra de linha só no checkpoint aborta o rollback (F20)' 3 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  if grep -q quebrou src/a.ts; then ok; else ko 'rollback abortado preserva o código (F20)'; fi
else
  skip 'rollback com quebra de linha no checkpoint' 'snippet ausente' 2
fi

# ---------------------------------------------------------------- iteração 12 (R93, SEC-041/045/047/048/049, F29–F39, R97, R102)
# BOM por classe nos dois lados (R93, F37) e densidade de NUL quando o blob já tem NUL (SEC-041)
new_repo bom-classe
printf '\377\376A\000B\000' > src/u16.ts && printf 'x\n' > src/be.ts && printf '\000\000\000\000x' > src/z32.dat && printf 'ok \000 ok\n' > src/nul.ts
git add -A && git commit -qm bom
printf '\377\376C\000B\000' > src/u16.ts
expect 'arquivo UTF-16 com BOM no blob, editado, não é checkout velho (R93) — mas é BOM (SEC-050)' 3 verify diff
lacks 'arquivo UTF-16 com BOM no blob, editado, não é checkout velho (R93)' 'NUL ou BOM'
has 'arquivo UTF-16 com BOM no blob, editado: 🚨 de BOM (SEC-050)' 'arquivo verificado começa com BOM UTF-16/32: src/u16.ts (utf16le)'
printf '\377\376\000\000A\000\000\000' > src/u16.ts
expect 'BOM UTF-32LE sobre blob UTF-16LE vira 🚨 (R93)' 3 verify diff
has 'BOM UTF-32LE sobre blob UTF-16LE vira 🚨 (R93)' 'src/u16.ts está na working tree com NUL ou BOM'
git checkout -q -- src/u16.ts
printf '\376\377\116\055' > src/be.ts
expect 'BOM UTF-16BE sem NUL vira 🚨 (F37)' 3 verify diff
has 'BOM UTF-16BE sem NUL vira 🚨 (F37)' 'src/be.ts está na working tree com NUL ou BOM'
git checkout -q -- src/be.ts
printf '\000\000\376\377\000\000\000A' > src/z32.dat
expect 'BOM UTF-32BE sobre blob com NUL vira 🚨 (F37)' 3 verify diff
has 'BOM UTF-32BE sobre blob com NUL vira 🚨 (F37)' 'src/z32.dat está na working tree com NUL ou BOM'
git checkout -q -- src/z32.dat
printf 'o\000k\000 \000o\000k\000\n\000' > src/nul.ts
expect 'UTF-16LE sem BOM sobre blob com NUL plantado vira 🚨 (SEC-041)' 3 verify diff
has 'UTF-16LE sem BOM sobre blob com NUL plantado vira 🚨 (SEC-041)' 'src/nul.ts está na working tree com NUL ou BOM'
git checkout -q -- src/nul.ts
printf 'console.log(1)\n' >> src/a.ts
mkdir -p "$WORK/timeoutfail"
printf '#!/bin/sh\ncase "$*" in *nul_stats*) exit 7 ;; esac\nexec %s "$@"\n' "$(command -v timeout)" > "$WORK/timeoutfail/timeout" && chmod +x "$WORK/timeoutfail/timeout"
expect 'falha da checagem dos modificados vira 🚨 (F37)' 3 env PATH="$WORK/timeoutfail:$PATH" sh "$VERIFY" diff
has 'falha da checagem dos modificados vira 🚨 (F37)' 'checagem de checkout falhou (exit 7)'
git checkout -q -- src/a.ts
# arquivo com BOM UTF-16 commitado (limpo) sob um Verify-Cmd: as formas rg e grep divergem → 🚨 (F40/SEC-050)
printf '\377\376c\000o\000n\000s\000o\000l\000e\000.\000l\000o\000g\000\n\000' > src/u16.ts && git commit -qam u16
expect 'arquivo UTF-16 com BOM commitado sob um Verify-Cmd vira 🚨 (F40/SEC-050)' 3 verify diff
has 'arquivo UTF-16 com BOM commitado sob um Verify-Cmd vira 🚨 (F40/SEC-050)' 'arquivo verificado começa com BOM UTF-16/32: src/u16.ts (utf16le)'
lacks 'arquivo UTF-16 com BOM commitado: nenhum Verify-Cmd roda (F40/SEC-050)' '| 0 |'

# attr.tree do executor não troca a árvore de atributos (SEC-048; git ≥ 2.42)
new_repo attr-tree
printf 'src/e.ts working-tree-encoding=UTF-16\n' > .gitattributes && printf '\377\376o\000k\000\n\000' > src/e.ts && git add -A && git commit -qm enc
if [ "$(git -c attr.tree=main check-attr working-tree-encoding -- src/e.ts | sed 's/.*: //')" = unspecified ]; then
  git config attr.tree main
  expect 'attr.tree na config não esconde working-tree-encoding (SEC-048)' 3 verify diff
  has 'attr.tree na config não esconde working-tree-encoding (SEC-048)' 'working-tree-encoding em arquivo verificado'
  git config --unset attr.tree
else
  skip 'attr.tree na config (SEC-048)' "git sem attr.tree" 2
fi

# deps-revert: versão local de rastreado modificado vai para a quarentena (F30/SEC-045)
new_repo deps-backup
git checkout -q main && mkdir -p docs/requirements && printf 'RF-01 login\n' > docs/requirements/login.txt && git add -A && git commit -qm rf && git checkout -q -B feat main
printf 'RF-02 logout (trabalho local)\n' >> docs/requirements/login.txt
expect 'deps-revert com falso positivo rastreado e modificado (F30)' 0 verify deps-revert
has 'deps-revert com falso positivo rastreado e modificado (F30)' 'revertido ao merge-base: docs/requirements/login.txt (versão local → '
lacks 'versão do índice igual ao HEAD não vai para a quarentena (F44)' 'versão do índice'
saved=$(qfile worktree docs/requirements/login.txt)
if [ "$(cat docs/requirements/login.txt)" = 'RF-01 login' ] && [ -n "$saved" ] && grep -q 'RF-02 logout' "$saved"; then ok; else ko 'edição local do rastreado recuperável na quarentena (F30)'; fi
# manifesto commitado na branch e apagado da working tree: nada a mover (F33/R95)
printf '{}\n' > package.json && git add package.json && git commit -qm pkg && rm package.json
expect 'deps-revert com manifesto ausente da working tree (F33)' 0 verify deps-revert
has 'deps-revert com manifesto ausente da working tree (F33)' 'removido do índice (ausente no merge-base e da working tree): package.json'
lacks 'deps-revert com manifesto ausente da working tree (F33)' 'movido para a quarentena'
lacks 'manifesto commitado e apagado: versão do índice = HEAD, sem item index (F44)' 'versão do índice'
git reset -q --hard
# duas execuções seguidas não se sobrescrevem (F37)
printf 'primeira\n' > Cargo.toml && sh "$VERIFY" deps-revert > /dev/null 2>&1
printf 'segunda\n' > Cargo.toml && sh "$VERIFY" deps-revert > /dev/null 2>&1
if [ "$(qfiles worktree Cargo.toml | wc -l)" -eq 2 ]; then ok; else ko 'quarentenas de execuções seguidas são distintas (F37)'; fi
# symlink quebrado novo também vai para a quarentena (F37)
ln -s nao-existe package.json
expect 'deps-revert com symlink quebrado novo' 0 verify deps-revert
if [ ! -L package.json ] && [ -L "$(qfile worktree package.json)" ]; then ok; else ko 'symlink quebrado novo vai para a quarentena (F37)'; fi
# worktree vinculado: quarentena no diretório git comum, sobrevive a git worktree remove (F34/SEC-045)
git worktree add -q "$WORK/wt-deps" -b wt-deps feat 2>/dev/null
printf 'do worktree\n' > "$WORK/wt-deps/go.mod"
(cd "$WORK/wt-deps" && sh "$VERIFY" deps-revert) > "$WORK/out" 2>&1
git worktree remove --force "$WORK/wt-deps"
saved=$(qfile worktree go.mod)
if [ -n "$saved" ] && [ "$(cat "$saved")" = 'do worktree' ]; then ok; else ko 'quarentena de worktree vinculado sobrevive ao git worktree remove (F34)'; fi

# deps em lote: milhares de arquivos no diff sem um processo por arquivo (F29/SEC-049)
new_repo deps-volume
mkdir gen && i=0
# um processo por arquivo leva ~17 s aqui (0,85 ms/arquivo); o awk em lote, ~0,05 s
while [ "$i" -lt 20000 ]; do : > "gen/f$i.txt"; i=$((i + 1)); done
printf 'x\n' > gen/package.json
expect 'deps com 20000 arquivos no diff em menos de 5 s (F29/SEC-049)' 0 timeout 5 sh "$VERIFY" deps
has 'deps com 20000 arquivos no diff em menos de 5 s (F29/SEC-049)' 'gen/package.json'

# DOTAGENTS_BASE_BRANCH=origin/main resolve a branch remota antes de uma local homônima (R102)
new_repo base-remota-antes
git update-ref refs/remotes/origin/main refs/heads/main
printf 'f\n' >> src/a.ts && git commit -qam f && git update-ref refs/heads/origin/main HEAD
expect 'DOTAGENTS_BASE_BRANCH=origin/main usa refs/remotes/origin/main (R102)' 0 env DOTAGENTS_BASE_BRANCH=origin/main sh "$VERIFY" base
has 'DOTAGENTS_BASE_BRANCH=origin/main usa refs/remotes/origin/main (R102)' "$(git rev-parse refs/heads/main)"

# ---------------------------------------------------------------- iteração 13 (SEC-050/051/052, R104–R110, F41–F47)
# BOM UTF-16/32 no início de arquivo verificado → 🚨 nas duas formas (SEC-050)
new_repo bom-snapshot
printf '\377\376console.log(1)\n' > src/p.ts && git add src/p.ts && git commit -qm p
expect 'FF FE na frente de código ASCII sob um Verify-Cmd vira 🚨 (SEC-050)' 3 verify diff
has 'FF FE na frente de código ASCII sob um Verify-Cmd vira 🚨 (SEC-050)' 'arquivo verificado começa com BOM UTF-16/32: src/p.ts (utf16le)'
lacks 'FF FE na frente de código ASCII: nenhum Verify-Cmd roda como conforme (SEC-050)' '| 0 |'
git rm -q src/p.ts && git commit -qm sem-p
printf '\376\377\000x' > src/be.ts
expect 'BOM UTF-16BE em arquivo novo vira 🚨 (SEC-050)' 3 verify diff
has 'BOM UTF-16BE em arquivo novo vira 🚨 (SEC-050)' 'src/be.ts (utf16be)'
rm src/be.ts && printf '\377\376\000\000x\000\000\000' > src/le32.ts
expect 'BOM UTF-32LE em arquivo novo vira 🚨 (SEC-050)' 3 verify diff
has 'BOM UTF-32LE em arquivo novo vira 🚨 (SEC-050)' 'src/le32.ts (utf32le)'
rm src/le32.ts && printf '\000\000\376\377\000\000\000x' > src/be32.ts
expect 'BOM UTF-32BE em arquivo novo vira 🚨 (SEC-050)' 3 verify diff
has 'BOM UTF-32BE em arquivo novo vira 🚨 (SEC-050)' 'src/be32.ts (utf32be)'
rm src/be32.ts && printf 'ab\376\377cd\377\376\n' > src/meio.ts
expect 'bytes de BOM fora do início não são BOM (SEC-050)' 0 verify diff
lacks 'bytes de BOM fora do início não são BOM (SEC-050)' 'começa com BOM'
mkdir -p "$WORK/grepfail"
printf '#!/bin/sh\ncase "$1" in -l) echo "falha injetada" >&2; exit 2 ;; esac\nexec %s "$@"\n' "$(command -v grep)" > "$WORK/grepfail/grep" && chmod +x "$WORK/grepfail/grep"
expect 'falha do grep da checagem de BOM vira 🚨 (SEC-050)' 3 env PATH="$WORK/grepfail:$PATH" sh "$VERIFY" diff
has 'falha do grep da checagem de BOM vira 🚨 (SEC-050)' 'grep falhou na checagem de BOM'
mkdir -p "$WORK/bomloopfail"
printf '#!/bin/sh\ncase "$*" in *"class=\\$(bom_class"*) exit 7 ;; esac\nexec %s "$@"\n' "$(command -v timeout)" > "$WORK/bomloopfail/timeout" && chmod +x "$WORK/bomloopfail/timeout"
expect 'falha da leitura dos BOM vira 🚨 (SEC-050)' 3 env PATH="$WORK/bomloopfail:$PATH" sh "$VERIFY" diff
has 'falha da leitura dos BOM vira 🚨 (SEC-050)' 'checagem de BOM falhou (exit 7)'
rm src/meio.ts

# ramo dos modificados: pré-filtro em lote — arquivo de texto editado não lê o blob (R104)
new_repo prefiltro
printf 'y\n' >> src/a.ts
expect 'arquivo de texto editado não lê o blob (pré-filtro, R104)' 0 gitfail 'cat-file blob' diff
lacks 'arquivo de texto editado não lê o blob (pré-filtro, R104)' 'git cat-file falhou'
git checkout -q main && mkdir -p src/vol && i=0
while [ "$i" -lt 2000 ]; do printf 'a\n' > "src/vol/f$i.ts"; i=$((i + 1)); done
git add -A && git commit -qm vol && git checkout -q -B feat main
i=0; while [ "$i" -lt 2000 ]; do printf 'b\n' >> "src/vol/f$i.ts"; i=$((i + 1)); done
expect '2000 arquivos de texto editados sob um Verify-Cmd, timeout padrão (R104)' 0 verify diff
lacks '2000 arquivos de texto editados sob um Verify-Cmd, timeout padrão (R104)' 'timeout'

# od obrigatório: sem ele a checagem de BOM não se desliga em silêncio (R105)
new_repo sem-od
mkdir -p "$WORK/nood"
for tool in sh git awk sed grep sort cut find tr wc mktemp cat cp cmp xargs dirname head timeout rm mkdir; do
  ln -sf "$(command -v "$tool")" "$WORK/nood/$tool"
done
printf '\376\377\116\055' > src/a.ts
expect 'od ausente vira 🚨 de ferramenta (R105)' 3 env PATH="$WORK/nood" "$WORK/nood/sh" "$VERIFY" diff
has 'od ausente vira 🚨 de ferramenta (R105)' 'comando indisponível (od)'

# CDPATH herdado não desvia os cd do verificador (F41/SEC-051)
new_repo cdpath
printf 'x\n' > constraints.txt
expect 'deps-revert com CDPATH=. herdado (F41/SEC-051)' 0 env CDPATH=.:/nao-existe sh "$VERIFY" deps-revert
has 'deps-revert com CDPATH=. herdado: quarentena no .git (F41/SEC-051)' "constraints.txt → $REPO/.git/dotagents/deps-quarantine/"
if [ -f "$(qfile worktree constraints.txt)" ] && [ -z "$(find . -maxdepth 1 -name '.git?*')" ]; then ok; else ko 'CDPATH=. não cria diretório .git<LF> na working tree (F41/SEC-051)'; fi
git checkout -q main && mkdir -p .claude/hooks && cp "$VERIFY" .claude/hooks/dotagents-verify.sh && git add -A && git commit -qm install && git checkout -q -B feat main
printf '# alterado\n' >> .claude/hooks/dotagents-verify.sh
expect 'verificador alterado com CDPATH=. e $0 relativo bloqueia (F41/SEC-051)' 3 env CDPATH=. sh .claude/hooks/dotagents-verify.sh lint
has 'verificador alterado com CDPATH=. e $0 relativo bloqueia (F41/SEC-051)' 'difere do merge-base'

# índice: manifesto adicionado e apagado da working tree (AD) entra no diff; deps-revert guarda a versão do índice (F43/F44)
new_repo deps-indice
printf '{"dependencies":{"evil":"1"}}\n' > package.json && git add package.json && rm package.json
expect 'deps vê manifesto adicionado ao índice e apagado da working tree (F43)' 0 verify deps
has 'deps vê manifesto adicionado ao índice e apagado da working tree (F43)' 'package.json'
expect 'deps-revert com manifesto AD (F43/F44)' 0 verify deps-revert
has 'deps-revert com manifesto AD guarda a versão do índice (F44)' 'removido do índice (ausente no merge-base e da working tree): package.json (versão do índice → '
saved=$(qfile index package.json)
if [ -n "$saved" ] && grep -q evil "$saved" && ! git ls-files --error-unmatch package.json >/dev/null 2>&1; then ok; else ko 'manifesto AD fora do índice e recuperável como item index da quarentena (F43/F44)'; fi
git checkout -q main && mkdir -p docs/requirements && printf 'v0\n' > docs/requirements/a.txt && git add -A && git commit -qm a && git checkout -q -B feat main
printf 'v1 staged\n' > docs/requirements/a.txt && git add docs/requirements/a.txt && printf 'v2 wt\n' > docs/requirements/a.txt
expect 'deps-revert com versão do índice diferente da working tree e do HEAD (F44)' 0 verify deps-revert
has 'deps-revert com versão do índice diferente da working tree e do HEAD (F44)' 'revertido ao merge-base: docs/requirements/a.txt (versão local → '
has 'deps-revert cita a versão do índice (F44)' '; versão do índice → '
idx=$(qfile index docs/requirements/a.txt)
wt=$(qfile worktree docs/requirements/a.txt)
if [ "$(cat docs/requirements/a.txt)" = v0 ] && [ -n "$idx" ] && [ "$(cat "$idx")" = 'v1 staged' ] && [ -n "$wt" ] && [ "$(cat "$wt")" = 'v2 wt' ]; then ok; else ko 'versões do índice e da working tree recuperáveis na quarentena (F44)'; fi

# checagem do deps-revert: backup do rastreado trocado por symlink (cp -P) e por symlink pendente (F47)
new_repo deps-symlink
git checkout -q main && printf '{}\n' > package.json && printf 'z\n' > go.mod && git add -A && git commit -qm deps && git checkout -q -B feat main
printf 'fora\n' > "$WORK/fora.txt" && rm package.json && ln -s "$WORK/fora.txt" package.json
rm go.mod && ln -s nao-existe go.mod
expect 'deps-revert com rastreados trocados por symlink e symlink pendente (F47)' 0 verify deps-revert
if [ -L "$(qfile worktree package.json)" ] && [ "$(cat package.json)" = '{}' ] && [ ! -L package.json ]; then ok; else ko 'symlink local de rastreado vai para a quarentena como symlink (cp -P, F47)'; fi
if [ -L "$(qfile worktree go.mod)" ] && [ "$(cat go.mod)" = z ]; then ok; else ko 'symlink pendente local de rastreado vai para a quarentena (F47)'; fi

# deps -z: lista NUL (F47)
new_repo deps-z
mkdir -p 'a b' && printf '{}\n' > 'a b/package.json'
verify deps -z > "$WORK/deps.z" 2> "$WORK/out"
if printf 'a b/package.json\000' | cmp -s - "$WORK/deps.z"; then ok; else od -c "$WORK/deps.z" > "$WORK/out"; ko 'deps -z separa por NUL (F47)'; fi
# falha do awk da seleção de manifestos → 🚨, nunca lista vazia (F47)
mkdir -p "$WORK/awkfail"
printf '#!/bin/sh\ncase "$*" in *at_root*) exit 2 ;; esac\nexec %s "$@"\n' "$(command -v awk)" > "$WORK/awkfail/awk" && chmod +x "$WORK/awkfail/awk"
expect 'falha do awk da seleção de manifestos vira 🚨 (F47)' 3 env PATH="$WORK/awkfail:$PATH" sh "$VERIFY" deps
has 'falha do awk da seleção de manifestos vira 🚨 (F47)' 'awk falhou na seleção de manifestos'

# ramo dos modificados: limiar de densidade, classe none e blob vazio (F47)
new_repo densidade
zeros() { head -c "$1" /dev/zero | tr '\000' "$2"; }
{ zeros 99 a; printf '\000'; } > src/d.dat
: > src/vazio.dat
git add -A && git commit -qm densidade
{ zeros 90 a; zeros 10 '\000'; } > src/d.dat
expect 'binário de 10‰ para 100‰ de NUL não é checkout velho (limiar ≥ 250‰, F47)' 0 verify diff
lacks 'binário de 10‰ para 100‰ de NUL não é checkout velho (limiar ≥ 250‰, F47)' 'NUL ou BOM'
git checkout -q -- src/d.dat
printf 'a\000b\n' > src/vazio.dat
expect 'blob vazio com NUL na working tree: 🚨 de checkout velho, sem erro de divisão (F47)' 3 verify diff
has 'blob vazio com NUL na working tree: 🚨 de checkout velho, sem erro de divisão (F47)' 'src/vazio.dat está na working tree com NUL ou BOM'
has 'mensagem do ramo dos modificados pede cópia antes de restaurar (F47)' 'salve uma cópia do arquivo fora do repositório e restaure-o do git'
git checkout -q -- src/vazio.dat
# limite documentado (F45/SEC-041 residual 3): blob com ≥ 1/3 de NUL — sem --review passa; o --review pega
{ zeros 600 a; zeros 400 '\000'; } > src/d.dat && git commit -qam denso
printf 'c\000o\000n\000s\000o\000l\000e\000.\000\n\000' > src/d.dat
expect 'blob com 40 % de NUL e UTF-16 sem BOM: sem --review passa (limite documentado, F45)' 0 verify diff
lacks 'blob com 40 % de NUL e UTF-16 sem BOM: sem --review passa (limite documentado, F45)' 'NUL ou BOM'
expect 'blob com 40 % de NUL e UTF-16 sem BOM: o --review pega (F45)' 3 verify diff --review
has 'blob com 40 % de NUL e UTF-16 sem BOM: o --review pega (F45)' 'exige worktree limpo'
git checkout -q -- src/d.dat
# blob UTF-16 com BOM regravado em UTF-8 (sem BOM) com um NUL esparso: classe none não é "outra classe" (F47)
new_repo classe-none
printf '\377\376a\000b\000' > src/c.ts && git add src/c.ts && git commit -qm c
{ zeros 49 a; printf '\000'; } > src/c.ts
expect 'blob UTF-16 com BOM regravado em UTF-8 com um NUL esparso não é checkout velho (classe none, F47)' 0 verify diff
lacks 'blob UTF-16 com BOM regravado em UTF-8 com um NUL esparso não é checkout velho (classe none, F47)' 'NUL ou BOM'
lacks_diff_empty() { verify diff > "$WORK/out" 2>&1; lacks "$1" 'diff vazio'; }
printf 'y\n' >> src/a.ts && lacks_diff_empty 'diff com mudanças não avisa diff vazio (SEC-052)'
git checkout -q -- src/a.ts

# mensagem do checkout velho (ramo dos inalterados): remédio por modo (SEC-052) e cópia antes de restaurar (F47)
new_repo stale-mensagem
printf 'console.log(1)\n' > src/v.ts && git add src/v.ts && git commit -qm v
stale_checkout src/v.ts UTF-16LE
expect 'checkout velho: mensagem com o remédio de cada modo (SEC-052/F47)' 3 verify diff
has 'checkout velho: remédio do pré-commit no worktree do Developer (SEC-052)' 'no review pré-commit, corrija no worktree do Developer'
has 'checkout velho: cópia antes de restaurar (F47)' 'salve uma cópia do arquivo fora do repositório, apague-o e restaure-o'
has 'checkout velho: worktree novo só na revisão de branch commitada (SEC-052)' 'na revisão de branch commitada, use um worktree novo ou um clone do remoto canônico'

# --review: submódulo sujo com diff.ignoreSubmodules=all (F47/R109)
new_repo submodulo
mkdir -p "$WORK/subsrc" && (cd "$WORK/subsrc" && git init -q && git config user.email t@t && git config user.name t && printf 's\n' > s && git add s && git commit -qm s)
git -c protocol.file.allow=always submodule add -q "$WORK/subsrc" libsub > /dev/null 2>&1 && git commit -qm sub
printf 'sujo\n' >> libsub/s && git config diff.ignoreSubmodules all
expect '--review com submódulo sujo e diff.ignoreSubmodules=all vira 🚨 (F47)' 3 verify diff --review
has '--review com submódulo sujo e diff.ignoreSubmodules=all vira 🚨 (F47)' 'M libsub'

# attr.tree do executor em cada consulta que lê atributos (R109/F47; git ≥ 2.42)
attr_tree() { b=$(printf '%s\n' "$1" | git hash-object -w --stdin) && printf '100644 blob %s\t.gitattributes\n' "$b" | git mktree; }
new_repo attr-probe
probe_tree=$(attr_tree 'x foo=bar')
if [ "$(git -c attr.tree="$probe_tree" check-attr foo -- x | sed 's/.*: //')" = bar ]; then
  # diff da working tree: CRLF sobre blob LF com attr.tree '* text' (o diff com atributos esconderia o arquivo)
  new_repo attr-diff
  git checkout -q main && printf 'console.log(1)\n' > src/x.ts && git add -A && git commit -qm x && git checkout -q -B feat main
  printf 'console.log(1)\r\n' > src/x.ts && git config attr.tree "$(attr_tree '* text')"
  expect 'attr.tree não esconde arquivo do diff da working tree (R109)' 1 verify diff
  has 'attr.tree não esconde arquivo do diff da working tree (R109)' 'sem console'
  # ls-files -m e status: filtro clean que troca x por c (mesmo tamanho) só no attr.tree
  new_repo attr-filtro
  git checkout -q main && printf 'console.log(1)\n' > src/x.ts && git add -A && git commit -qm x && git checkout -q -B feat main
  printf 'y\n' > src/y.ts && git add -A && git commit -qm y
  git config filter.swap.clean 'tr x c' && git config attr.tree "$(attr_tree 'src/* filter=swap')"
  sleep 1 && printf 'xonsole.log(1)\n' > src/x.ts
  expect 'attr.tree não mascara arquivo modificado no ls-files -m (R109)' 0 verify diff
  lacks 'attr.tree não mascara arquivo modificado no ls-files -m (R109)' 'difere do blob do índice'
  expect 'attr.tree não limpa o status do --review (R109)' 3 verify diff --review
  has 'attr.tree não limpa o status do --review (R109)' 'M src/x.ts'
  # hash-object: checkout velho CRLF (eol=crlf removido) não vira "normalizado igual" pelo attr.tree '* text'
  new_repo attr-hash
  printf 'console.log(1)\n' > src/x.ts && git add src/x.ts && git commit -qm x
  { printf 'src/x.ts text eol=crlf\n' > .gitattributes && git add .gitattributes && git commit -qm attr
    rm src/x.ts && git checkout -- src/x.ts && sleep 1 && git update-index -q --refresh
    git rm -q .gitattributes && git commit -qm 'remove o atributo'; } 2> "$WORK/git-noise"
  git config attr.tree "$(attr_tree '* text')"
  expect 'attr.tree não normaliza o checkout velho no hash-object (R109)' 3 verify diff
  has 'attr.tree não normaliza o checkout velho no hash-object (R109)' 'src/x.ts difere do blob do índice'
  # diff de memories/: filtro só no attr.tree não inventa entradas alteradas
  new_repo attr-memorias
  git config filter.swap.clean 'tr a b' && git config attr.tree "$(attr_tree 'memories/*.md filter=swap')"
  printf 'y\n' > src/y.ts && sleep 1 && touch memories/guidelines.md
  expect 'attr.tree não altera o diff de memories/ (R109)' 0 verify diff
  lacks 'attr.tree não altera o diff de memories/ (R109)' 'entrada removida ou alterada'
else
  skip 'attr.tree em ls-files -m, hash-object, diff, status e diff de memories/ (R109)' 'git sem attr.tree' 10
fi

# ---------------------------------------------------------------- iteração 14 (SEC-053/SEC-054/R112, F48, R113)
# quarentena plana: diretório trocado por symlink não leva a gravação para fora do repositório (SEC-053, cenário D)
new_repo quar-link
mkdir -p "$WORK/vitima-d" && printf 'arquivo da vítima\n' > "$WORK/vitima-d/plugin.cjs"
git checkout -q main && mkdir -p .yarn/plugins/p && printf 'BASE\n' > .yarn/plugins/p/plugin.cjs && git add -A && git commit -qm plugin && git checkout -q -B feat main
git rm -rq .yarn/plugins/p && mkdir -p .yarn/plugins && ln -s "$WORK/vitima-d" .yarn/plugins/p && git add -A && git commit -qm 'diretório vira symlink'
if [ -L .yarn/plugins/p ] && [ "$(git ls-files -s .yarn/plugins/p | cut -c1-6)" = 120000 ]; then ok; else ko 'montagem do cenário D (SEC-053)'; fi
expect 'deps-revert com diretório de manifestos trocado por symlink commitado (SEC-053)' 0 verify deps-revert
if [ "$(cat "$WORK/vitima-d/plugin.cjs")" = 'arquivo da vítima' ] && [ "$(ls "$WORK/vitima-d")" = plugin.cjs ]; then ok; else ko 'deps-revert não grava através do symlink guardado na quarentena (SEC-053)'; fi
if [ -L "$(qfile worktree .yarn/plugins/p)" ] && [ "$(cat .yarn/plugins/p/plugin.cjs)" = BASE ]; then ok; else ko 'symlink do diretório guardado na quarentena e diretório restaurado (SEC-053)'; fi
# cenário E: entrada só no índice sob o diretório trocado por symlink (worktree do Developer)
git reset -q --hard && git checkout -q -B feat2 main
mkdir -p "$WORK/vitima-e" && printf '#!/bin/sh\necho AUTOR\n' > .yarn/plugins/p/run && git add .yarn/plugins/p/run
rm -rf .yarn/plugins/p && ln -s "$WORK/vitima-e" .yarn/plugins/p
if [ -L .yarn/plugins/p ]; then ok; else ko 'montagem do cenário E (SEC-053)'; fi
expect 'deps-revert com entrada do índice sob diretório trocado por symlink (SEC-053)' 0 verify deps-revert
if [ -z "$(ls -A "$WORK/vitima-e")" ]; then ok; else ls -la "$WORK/vitima-e" > "$WORK/out"; ko 'versão do índice não é gravada através do symlink (SEC-053)'; fi
if grep -q AUTOR "$(qfile index .yarn/plugins/p/run)"; then ok; else ko 'versão do índice sob o diretório trocado fica na quarentena (SEC-053)'; fi
# nomes que colidiam no layout antigo: <path>.index × arquivo chamado <path>.index, e mesmo nome em diretórios diferentes (SEC-054/R112)
new_repo quar-colisao
git checkout -q main && mkdir -p .yarn/releases && printf 'v0\n' > .yarn/releases/y.cjs && git add -A && git commit -qm y && git checkout -q -B feat main
printf 'SO-NO-INDICE\n' > .yarn/releases/y.cjs && git add .yarn/releases/y.cjs && printf 'working tree\n' > .yarn/releases/y.cjs
printf 'arquivo novo\n' > .yarn/releases/y.cjs.index
mkdir -p a b && printf 'A\n' > a/package.json && printf 'B\n' > b/package.json
expect 'deps-revert com nomes que colidiriam na quarentena (SEC-054/R112)' 0 verify deps-revert
if [ "$(cat "$(qfile index .yarn/releases/y.cjs)")" = SO-NO-INDICE ] && [ "$(cat "$(qfile worktree .yarn/releases/y.cjs.index)")" = 'arquivo novo' ] \
  && [ "$(cat "$(qfile worktree .yarn/releases/y.cjs)")" = 'working tree' ]; then ok; else ko 'versão do índice e arquivo <nome>.index coexistem na quarentena (SEC-054/R112)'; fi
if [ "$(cat "$(qfile worktree a/package.json)")" = A ] && [ "$(cat "$(qfile worktree b/package.json)")" = B ]; then ok; else ko 'manifestos de mesmo nome em diretórios diferentes coexistem na quarentena (SEC-054)'; fi
if [ "$(find .git/dotagents/deps-quarantine -mindepth 2 -type d | wc -l)" -eq 0 ]; then ok; else ko 'quarentena plana, sem subdiretórios (SEC-053)'; fi

# pré-filtro com nomes que o cmp leria como stdin ou opção (F48)
new_repo nomes-traco
git checkout -q main && printf 'ok\n' > ./- && printf 'ok\n' > ./-b && git add -A && git commit -qm traco && git checkout -q -B feat main
append <<'ENTRY'
### [2026-06-01][Task 014] sem console na raiz
- **Tipo:** `PADRAO_VERIFICAVEL`
- **Escopo (globs):** `*`
- **Regra:** NUNCA console em nenhum arquivo
- **Verify-Cmd:** `grep -rqE -e 'console\.' s*; test $? -eq 1`
- **Origem:** `docs/done/014-x/`

ENTRY
for name in - -b; do
  printf 'o\000k\000\n\000' > "./$name"
  expect "arquivo \"$name\" na raiz com NUL novo vira 🚨 (F48)" 3 verify diff
  has "arquivo \"$name\" na raiz com NUL novo vira 🚨 (F48)" "$name está na working tree com NUL ou BOM"
  has "remédio do pré-commit não descarta o trabalho do Developer (R113)" 'sem descartar o trabalho do Developer'
  git checkout -q -- "./$name"
done

# ---------------------------------------------------------------- awk alternativos
for alt in mawk 'busybox awk'; do
  bin=${alt%% *}
  if ! command -v "$bin" >/dev/null 2>&1; then skip "awk = $alt" "$bin ausente" 3; continue; fi
  mkdir -p "$WORK/awk-$bin" && printf '#!/bin/sh\nexec %s "$@"\n' "$alt" > "$WORK/awk-$bin/awk" && chmod +x "$WORK/awk-$bin/awk"
  new_repo "awk-$bin-repo"
  printf 'parseFloat(1)\n' > src/checkout/n.ts && printf 'x\n' > 'src/a\b.ts'
  expect "diff com awk = $alt (nome com barra invertida, F39)" 1 timeout 60 env PATH="$WORK/awk-$bin:$PATH" sh "$VERIFY" diff
  has "diff com awk = $alt lista o fragmento" 'FRAGMENTO ATIVO: memories/implementations/checkout-padrao-verificavel.md'
  lacks "diff com awk = $alt ignora SUPERSEDED" 'sem console.log'
done

PASSED=$(grep -c '^ok$' "$WORK/tally")
FAILED=$(grep -c '^ko$' "$WORK/tally")
SKIPPED=$(grep -c '^skip$' "$WORK/tally")
printf '\n%s passaram · %s falharam · %s pulados\n' "$PASSED" "$FAILED" "$SKIPPED"
[ "$FAILED" -eq 0 ]

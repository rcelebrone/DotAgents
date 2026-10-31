#!/bin/sh
# Suíte de regressão do hooks/dotagents-verify.sh e dos snippets das skills que o usam.
# Rode a partir da raiz do repositório DotAgents: sh tests/dotagents-verify.test.sh
# Requer: git, awk, timeout, python3. ripgrep, mawk e busybox são opcionais (casos dependentes são pulados sem eles).
# Exit: 0 todos os casos passaram · 1 algum caso falhou.
set -u
LC_ALL=C
export LC_ALL
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
VERIFY="$HERE/hooks/dotagents-verify.sh"
VECTORS="$HERE/tests/fixtures/attack-vectors.txt"
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT
# canários usam caminho absoluto fora do repo e do snapshot: qualquer execução indevida deixa rastro aqui
CANARY="$WORK/canary"
mkdir -p "$CANARY"
HAS_RG=0
command -v rg >/dev/null 2>&1 && HAS_RG=1

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
  [ $? -eq 3 ] || { leaked=$((leaked + 1)); printf '   vetor não barrado: %s\n' "$label"; }
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
mkdir -p "$WORK/minibin"
for tool in sh git awk sed grep sort cut find tr wc mktemp cat cp dirname head timeout rm mkdir; do
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
mkdir -p "$WORK/gitfake"
printf '#!/bin/sh\ncase " $* " in *" checkout-index "*) echo "checkout-index chamado" >&2; exit 99 ;; esac\nexec %s "$@"\n' "$(command -v git)" > "$WORK/gitfake/git" && chmod +x "$WORK/gitfake/git"
new_repo lazy
printf 'x\n' > docs.md
expect 'sem entrada aplicável o snapshot não é montado (R63)' 0 env PATH="$WORK/gitfake:$PATH" sh "$VERIFY" diff
has 'sem entrada aplicável o snapshot não é montado (R63)' 'nenhum Verify-Cmd aplicável'
printf 'x\n' >> src/a.ts
expect 'com entrada aplicável o snapshot é montado' 3 env PATH="$WORK/gitfake:$PATH" sh "$VERIFY" diff
has 'com entrada aplicável o snapshot é montado' 'montagem do snapshot falhou'

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
mkdir -p scope/memories && printf '# G\n' > scope/memories/guidelines.md
cd scope
expect 'verificador da raiz alterado bloqueia em escopo aninhado (SEC-013)' 3 sh ../.claude/hooks/dotagents-verify.sh paths
cd "$REPO"
git show "$(git merge-base HEAD main)":./.claude/hooks/dotagents-verify.sh > "$WORK/verify-base.sh"
expect 'versão do merge-base, fora do repo, roda' 0 sh "$WORK/verify-base.sh" paths

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
ROLLBACK=$(sed -n '/^# 1. Checkpoint da task/,/^git status$/p' "$HERE/skills/state-checkpoint/SKILL.md")
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
  if git cat-file -e refs/dotagents/backup-checkpoint-20260101-000000:src/novo.ts 2>/dev/null; then ok; else ko 'backup do rollback inclui arquivo novo'; fi
  new_repo rollback-falha
  git tag dotagents/checkpoint-20260101-000000
  mkdir -p .git/refs/dotagents && : > .git/refs/dotagents/backup-checkpoint-20260101-000000.lock
  printf 'trabalho\n' > src/novo.ts && printf 'mudou\n' >> src/a.ts
  chmod 000 .git/refs/dotagents
  expect 'backup que falha aborta o rollback (R59)' 3 env CHECKPOINT=dotagents/checkpoint-20260101-000000 sh -c "$ROLLBACK"
  chmod 755 .git/refs/dotagents
  has 'backup que falha aborta o rollback (R59)' 'backup falhou'
  if [ -f src/novo.ts ] && grep -q mudou src/a.ts; then ok; else ko 'rollback abortado não descarta trabalho (R59)'; fi

  new_repo executor
  mkdir -p "$WORK/npxbin" && printf '#!/bin/sh\nprintf "npx %%s\\n" "$*"\n' > "$WORK/npxbin/npx" && chmod +x "$WORK/npxbin/npx"
  expect 'executor por extensão sem arquivos .js' 0 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
  has 'executor por extensão sem arquivos .js' 'nenhum arquivo .js no diff'
  printf 'x\n' > 'src/com espaco.js'
  expect 'executor por extensão chama a ferramenta com os arquivos' 0 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
  has 'executor por extensão chama a ferramenta com os arquivos' 'src/com espaco.js'
  cd "$WORK/nobase"
  expect 'executor por extensão propaga 🚨 sem base (R60)' 3 env PATH="$WORK/npxbin:$PATH" sh -c "$EXECUTOR"
fi

# ---------------------------------------------------------------- awk alternativos
for alt in mawk 'busybox awk'; do
  bin=${alt%% *}
  if ! command -v "$bin" >/dev/null 2>&1; then skip "awk = $alt" "$bin ausente" 3; continue; fi
  mkdir -p "$WORK/awk-$bin" && printf '#!/bin/sh\nexec %s "$@"\n' "$alt" > "$WORK/awk-$bin/awk" && chmod +x "$WORK/awk-$bin/awk"
  new_repo "awk-$bin-repo"
  printf 'parseFloat(1)\n' > src/checkout/n.ts
  expect "diff com awk = $alt" 1 env PATH="$WORK/awk-$bin:$PATH" sh "$VERIFY" diff
  has "diff com awk = $alt lista o fragmento" 'FRAGMENTO ATIVO: memories/implementations/checkout-padrao-verificavel.md'
  lacks "diff com awk = $alt ignora SUPERSEDED" 'sem console.log'
done

PASSED=$(grep -c '^ok$' "$WORK/tally")
FAILED=$(grep -c '^ko$' "$WORK/tally")
SKIPPED=$(grep -c '^skip$' "$WORK/tally")
printf '\n%s passaram · %s falharam · %s pulados\n' "$PASSED" "$FAILED" "$SKIPPED"
[ "$FAILED" -eq 0 ]

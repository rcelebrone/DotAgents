---
name: ast-validator
description: Validação estrutural de código via AST (Abstract Syntax Tree) e analisadores de tipos/símbolos nativos (tsc, mypy, go vet, cargo check, etc.). Garante matematicamente que funções, variáveis, métodos e imports invocados realmente existem, impedindo alucinações de LLM e quebras em refatorações. Use para "validar AST", "checar símbolos", "validar imports" ou "verificação estrutural".
---

# Skill: AST Validator (Parser Estrutural e Resolução de Símbolos)

**Objetivo:** Eliminar alucinações de LLM na manipulação de código (como invocar métodos inexistentes, importar módulos fictícios ou errar assinaturas de funções). Em vez de analisar código como texto plano, esta skill realiza parsing estrutural da Árvore Sintática Abstrata (AST) e verificação estática de tipos, garantindo integridade matemática antes do review e blindando refatorações (skill `refactor`).

## Propriedade (quem usa, quando)

- **Developer:** Durante a codificação e obrigatoriamente após refatorações, antes de acionar a verificação.
- **Architect:** Ao avaliar propostas estruturais e mudanças de interface pública.
- **Tech Lead:** Como gate determinístico pré-review, garantindo que o diff não contém símbolos órfãos ou quebrados.

## 1. O Problema das Alucinações Textuais

Modelos de linguagem que lêem código apenas como strings frequentemente:
- Inventam métodos utilitários plausíveis mas inexistentes (ex.: `date.formatISO()`, `array.unique()`, `response.to_dict()`).
- Erram o path de imports relativos (ex.: `../utils/auth` em vez de `../../utils/auth`).
- Alteram o nome de uma função na refatoração, mas esquecem referências em arquivos secundários.
- Passam número incorreto de argumentos obrigatórios para chamadas de biblioteca externa.

O `ast-validator` resolve isso substituindo palpites por **checagem de compilador / parser**.

## 2. Ferramentas Determinísticas por Linguagem

| Linguagem / Stack | Ferramenta Nativa de AST / Type-Check | Comando Determinístico |
|---|---|---|
| **TypeScript / JS** | Compilador TypeScript (`tsc`) | `npx tsc --noEmit` |
| **JavaScript (puro)** | ESLint com regras AST de símbolos | executor por extensão do § 4 com `.js npx eslint --no-eslintrc --rule '{"no-undef": 2, "no-unused-vars": 2}' --` |
| **Python** | Parser `ast` + Mypy / Pyright | script do § 4 e, com mypy configurado, `mypy --ignore-missing-imports .` |
| **Go** | Compilador Go (`vet` + build check) | `go vet ./... && go build -o /dev/null ./...` |
| **Rust** | Rust Compiler Frontend (`cargo check`) | `cargo check --all-targets` |
| **Java** | Compilador Java (`javac`) | `mvn compile -DskipTests` ou `./gradlew compileJava` |
| **C# / .NET** | Roslyn Compiler Check | `dotnet build /t:Build /p:WarningLevel=4` |

## 3. Os 3 Gates Estruturais

A validação de AST avalia três portões inflexíveis:

### Gate 1: Resolução de Imports (Import Resolution Gate)
- Todo `import`, `require` ou `use` referenciado no diff DEVE resolver para um arquivo físico existente no repositório ou para um pacote declarado nos manifestos de dependência.
- Se o parser indicar módulo não resolvido (`Cannot find module`, `ModuleNotFoundError`, `unresolved import`): **REJEIÇÃO DETERMINÍSTICA**.

### Gate 2: Resolução de Membros e Símbolos (Member & Symbol Gate)
- Toda invocação de função, acesso a método ou propriedade de objeto deve existir formalmente na definição da classe/interface de origem.
- A aridade (número de parâmetros obrigatórios) e tipos básicos devem coincidir.
- Qualquer erro de símbolo indefinido (`is not a function`, `has no attribute`, `undefined variable`, `unknown field`): **REJEIÇÃO DETERMINÍSTICA**.

### Gate 3: Integridade de Refatoração (Caller Integrity Gate)
- Quando utilizado em conjunto com a skill `refactor`:
  1. O parser mapeia todos os pontos de chamada (`callers`) do símbolo antes da alteração.
  2. Após a renomeação ou modificação da assinatura, o parser re-varre o projeto inteiro.
  3. Se restar qualquer chamada antiga quebrada ou apontando para assinatura obsoleta: **REJEIÇÃO DETERMINÍSTICA**.

## 4. Script Auxiliar de Verificação Rápida de AST (Fallback Agnóstico)

Caso o projeto Python não possua `mypy` configurado, execute o validador sintático via módulo nativo `ast`:

```bash
python3 - "{{AGENTS_ROOT}}/hooks/dotagents-verify.sh" <<'PY'
import ast, subprocess, sys
listing = subprocess.run(['sh', sys.argv[1], 'paths', '-z'], stdout=subprocess.PIPE)
if listing.returncode != 0:
    sys.exit(listing.returncode)
failed = False
for path in [p for p in listing.stdout.decode('utf-8', 'surrogateescape').split('\0') if p.endswith('.py')]:
    try:
        with open(path, 'rb') as source:
            ast.parse(source.read(), filename=path)
    except SyntaxError as error:
        print(f'❌ Erro sintático de AST em {path}:{error.lineno}:{error.offset}: {error.msg}')
        failed = True
if failed:
    sys.exit(1)
print('✅ Todos os arquivos possuem AST válida.')
PY
```

Os arquivos vêm de `dotagents-verify.sh paths -z` (lista NUL: nomes com espaço são preservados; sem arquivos `.py` no diff → exit 0). Exit 3 do verificador (🚨 no stderr: sem `<base>`, verificador alterado etc.) é propagado — pare e registre o 🚨.

**Executor por extensão** (qualquer ferramenta que recebe a lista de arquivos do diff — ex.: ESLint para `.js`): os argumentos após a extensão formam o comando, e os arquivos `.js` do diff são acrescentados ao fim; sem arquivos da extensão → exit 0; exit 3 do verificador é propagado.

```bash
python3 - "{{AGENTS_ROOT}}/hooks/dotagents-verify.sh" .js npx eslint --no-eslintrc --rule '{"no-undef": 2, "no-unused-vars": 2}' -- <<'PY'
import subprocess, sys
verify, extension, command = sys.argv[1], sys.argv[2], sys.argv[3:]
listing = subprocess.run(['sh', verify, 'paths', '-z'], stdout=subprocess.PIPE)
if listing.returncode != 0:
    sys.exit(listing.returncode)
files = [p for p in listing.stdout.decode('utf-8', 'surrogateescape').split('\0') if p.endswith(extension)]
if not files:
    print(f'nenhum arquivo {extension} no diff')
    sys.exit(0)
sys.exit(subprocess.run(command + files).returncode)
PY
```

## 5. Workflow de Execução

1. **Identificar arquivos tocados:** `{{AGENTS_ROOT}}/hooks/dotagents-verify.sh paths -z` — arquivos regulares do diff (não commitados e novos incluídos; deletados e symlinks excluídos). Exit 3 → pare e registre o 🚨 do stderr. Lista sem arquivos da stack → registre "nenhum arquivo da stack no diff"; nunca chame o validador sem argumentos.
2. **Executar validador de AST / compilador estático:**
   Rode o comando correspondente à stack.
3. **Decisão:**
   - **Zero erros:** Integridade estrutural comprovada. Código aprovado para avanço.
   - **Erros detectados:** Capture os erros com arquivo e linha exatos e devolva imediatamente ao Developer:
     `- AAAA-MM-DD — ❌ AST-VALIDATOR: símbolo ou import inexistente detectado em <arquivo:linha>. Alucinação/quebra evitada.`

## Restrições

- **Proibido ignorar com comentários de escape:** Não adicione `// @ts-ignore`, `# type: ignore` ou `/* eslint-disable no-undef */` para mascarar falhas de resolução de símbolos geradas por código novo.
- **Não aceita validação probabilística:** Se o compilador/parser disser que o símbolo não existe, prevalece a resposta do compilador, mesmo que o LLM afirme ter certeza de que o método existe.

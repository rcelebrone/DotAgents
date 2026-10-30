---
name: semantic-commit-checker
description: Validação puramente determinística baseada em Expressões Regulares (RegEx) para garantir o cumprimento estrito do padrão Conventional Commits. Integrada ao diretório hooks/ e executada pelo Ops na skill delivery. Use para "validar commit", "checar commit semântico" ou "verificar mensagem de commit".
---

# Skill: Semantic Commit Checker (Validador Determinístico de Commits)

**Objetivo:** Garantir de forma puramente determinística (via Expressões Regulares compiladas) que toda mensagem de commit gerada pela squad siga estritamente o padrão **Conventional Commits v1.0.0**. Atua em conjunto com a estrutura de `hooks/` do DotAgents (`hooks/dotagents-commit-check.sh`), bloqueando commits mal formatados, vagos ou fora do padrão antes que eles entrem no histórico do repositório.

## Propriedade (quem usa, quando)

- **Ops:** Obrigatoriamente na execução da skill `delivery` (passo 4: Commit Local), antes de disparar o comando `git commit`.
- **Tech Lead:** No review pré-commit e verificação de integridade da entrega.
- **Git Hooks (`commit-msg`):** Executado automaticamente pelo Git local caso o hook esteja instalado em `.git/hooks/commit-msg`.

## 1. Especificação RegEx Canônica

A validação não depende de julgamento semântico de IA — ela avalia a string da mensagem contra a seguinte expressão regular POSIX:

### RegEx do Cabeçalho (Header):
```regex
^(feat|fix|refactor|chore|docs|test|perf|style|ci|build)(\([a-z0-9._-]+\))?!?: [^A-Z[:punct:]].{1,99}[^.]$
```

### Regras Inflexíveis:
1. **Tipo (Obrigatório):** Deve ser exatamente um dos tipos canônicos:
   - `feat`: Nova funcionalidade para o usuário.
   - `fix`: Correção de bug.
   - `refactor`: Reestruturação de código sem alteração de comportamento externo.
   - `chore`: Tarefas de manutenção, configs de build ou ferramentas.
   - `docs`: Alterações exclusivamente em documentação.
   - `test`: Adição ou correção de testes automatizados.
   - `perf`: Otimização de performance de código.
   - `style`: Ajustes estéticos que não afetam significado (espaços, formatação).
   - `ci`: Alterações em pipelines de CI/CD.
   - `build`: Modificações no sistema de build ou dependências externas.
2. **Escopo (Opcional):** Entre parênteses em minúsculas kebab-case ou snake_case (ex: `(auth)`, `(api-client)`).
3. **Breaking Change (Opcional):** Indicado por `!` imediatamente antes dos dois pontos (ex: `feat(api)!: remodelar payload`).
4. **Separador (Obrigatório):** Dois pontos seguidos de espaço (`: `).
5. **Descrição (Obrigatória):**
   - Deve iniciar em letra minúscula (imperativo).
   - Não pode terminar com ponto final (`.`).
   - Tamanho máximo total da primeira linha: 100 caracteres.
6. **Corpo e Rodapé:**
   - Se houver corpo, a linha 2 DEVE ser uma linha em branco.
   - O rodapé deve referenciar a task ativa: `Task NNN` ou `Closes #NNN`.

## 2. Execução Determinística via CLI / Hook

A squad utiliza o script oficial em `hooks/dotagents-commit-check.sh`:

```bash
# Validando string diretamente
{{AGENTS_ROOT}}/hooks/dotagents-commit-check.sh "feat(auth): implementar middleware de verificacao de sessao"

# Validando arquivo de mensagem temporária
{{AGENTS_ROOT}}/hooks/dotagents-commit-check.sh /tmp/commit-msg.txt

# Ou via stdin
echo "feat: add user login" | {{AGENTS_ROOT}}/hooks/dotagents-commit-check.sh
```

### Avaliação de Resultado:
- **Exit Code 0:** Mensagem 100% aprovada. O comando `git commit -m "..."` está liberado.
- **Exit Code 1:** **REJEIÇÃO DETERMINÍSTICA**. A mensagem é recusada e o commit não é realizado até que o cabeçalho seja corrigido.

## 3. Integração com a Skill Delivery

Na skill `{{AGENTS_ROOT}}/skills/delivery/SKILL.md`, a etapa de commit segue o protocolo:

```
[Formular mensagem de commit]
             │
             ▼
[Executar dotagents-commit-check.sh]
             │
     ┌───────┴───────┐
     ▼ (Exit != 0)   ▼ (Exit == 0)
[REJEIÇÃO: Corrigir] [Executar git commit]
```

## 4. Instalação Opcional como Git Hook Nativo

Para habilitar a validação automática em todo `git commit` do repositório:

```bash
cp hooks/dotagents-commit-check.sh .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
```

## Restrições

- **Proibido bypass via `--no-verify`:** A persona Ops NUNCA deve executar `git commit --no-verify`.
- **Proibido mensagens genéricas:** Mensagens como `wip`, `fixes`, `alterações`, `update` resultam em falha determinística de regex.
- **Sem emojis no cabeçalho:** O padrão Conventional Commits padrão DotAgents prioriza parseabilidade limpa de changelog sem poluição de caracteres no hash.

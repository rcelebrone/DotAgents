---
name: code-review
description: Realiza revisão assíncrona de código (Peer Review) em diffs recentes, focando em legibilidade, higiene, e conformidade com os padrões. Use para "revisar meu código", "fazer code review" ou "avaliar minhas mudanças".
---

## Workflow

1. **Diff Analysis**: Analisa as mudanças não "commitadas" (`git diff`) ou branch atual contra a main.
2. **Sanity Check Estático**:
   - Código morto ou importações não utilizadas.
   - Variáveis não semânticas ou nomenclaturas confusas.
   - Funções excessivamente grandes (Complexidade Ciclomática alta).
   - Violações diretas ao `memorys/guidelines.md` e aos padrões Clean Code.
3. **Feedback Direto**: Gera um log de melhorias no terminal apontando Arquivo, Linha e Sugestão.
4. **Ação Iterativa**: O Developer consome o feedback e decide se aplica ou ignora antes de entregar o código para o QA Specialist.

## Restrições
- Não focar em bugs funcionais ou segurança (estas são responsabilidades das skills `triage` e `security-audit`, respectivamente).
- Manter o tom rígido e direto na apresentação das melhorias de sintaxe e estilo.

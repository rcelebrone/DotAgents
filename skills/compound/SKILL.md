---
name: compound
description: Especialista em manutenção de contexto e memória técnica. Atualiza arquivos de arquitetura e guias do projeto após merges e mudanças significativas. Use para "atualizar memória", "analisar diff" ou sincronizar o contexto do projeto.
---

## Ações Pós-Merge

1. **Context Gathering**: Analisa o `git diff` e aprendizados da sessão.
2. **State Update**:
   - `memorys/architecture.md`: Adiciona e atualiza decisões de arquitetura globais. Detalhes de implementação técnica específica devem ir para `memorys/implementations/*.md`.
   - `memorys/guidelines.md`: Adiciona restrições aprendidas globais. Padrões de módulos específicos devem ir para `memorys/implementations/*.md`.
   - `memorys/business.md`: Adiciona regras de negócio core. Regras de módulos específicos devem ir para `memorys/implementations/*.md`.

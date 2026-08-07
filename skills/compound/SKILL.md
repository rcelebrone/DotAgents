---
name: compound
description: Especialista em manutenção de contexto e memórias. Atualiza arquivos de arquitetura, regras de negócio e guias do projeto após conclusão de implementações ou pré commit. Use para "atualizar memória", "analisar diff", "guardar aprendizados" ou sincronizar o contexto do projeto.
---

## Ações Pré-Commit

1. **Context Gathering**: Analisa o `git diff` e aprendizados da sessão.
2. **State Update**:
   - `memories/architecture.md`: Adiciona e atualiza decisões de arquitetura globais. Detalhes de implementação técnica específica devem ir para `memories/implementations/*.md`.
   - `memories/guidelines.md`: Adiciona restrições aprendidas globais. Padrões de módulos específicos devem ir para `memories/implementations/*.md`.
   - `memories/business.md`: Adiciona regras de negócio core. Regras de módulos específicos devem ir para `memories/implementations/*.md`.

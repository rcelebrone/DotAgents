---
name: test-scaffold
description: Gera estrutura completa de testes automatizados (unitários, integração e edge cases) com base no código existente. Use para "escrever testes para este arquivo", "aumentar cobertura" ou "criar mocks".
---

## Workflow

1. **Contexto de Teste**: Analisa o código de produção alvo e identifica as dependências externas (banco, APIs, cache, relógio do sistema).
2. **Scaffolding de Mocks**: Cria stubs, spies e mocks para todas as fronteiras externas detectadas, isolando o componente.
3. **Geração de Cenários**:
   - Caminhos Felizes (Happy Paths).
   - Limites (Boundary values / Edge cases).
   - Tratamento de Exceções (Falhas de rede, null pointers, retornos inválidos).
4. **Criação de Artefatos**: Gera o arquivo de teste `*.spec.*` ou `*_test.*` no local adequado conforme o padrão do framework detectado em `memories/architecture.md`.

## Propriedade (quem usa, quando)
- **Developer:** durante a implementação — testes unitários e mocks da própria task (mesmo diff).
- **QA Specialist:** lacunas de integração/E2E encontradas na auditoria — os testes entram no ciclo de QA da task.
- **Projeto sem framework de teste:** a adoção inicial é task P2 própria (sugerida pelo QA), nunca embutida silenciosamente no ciclo corrente.

## Restrições
- Testes devem usar nomes descritivos.
- Foco em testar o comportamento (Behavior) e não a implementação estrutural, evitando testes frágeis.

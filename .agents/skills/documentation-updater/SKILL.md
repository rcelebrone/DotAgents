---
name: documentation-updater
description: |
  Garante que o repositório, README.md, diagramas (Mermaid) e os arquivos em docs reflitam a realidade de negócio e técnica atual do código, sincronizados com as últimas alterações.
---

# Documentation & README Updater

## Gatilhos de Ativação (Triggers)
- Sempre que houver inclusão de variáveis de ambiente obrigatórias.
- Ao atualizar fluxos que tornem um diagrama desatualizado.
- Se houver novos endpoints (APIs) ou componentes públicos.

## Workflow
1. Verifique `README.md` (ou arquivos em `/docs`) para identificar onde as variáveis, endpoints e diagramas (Mermaid.js) residem.
2. Atualize o design da documentação refletindo estritamente as alterações de código feitas em escopo.
3. Se for uma UI ou nova rota, adicione guias básicos de integração ou instruções de uso correspondentes.

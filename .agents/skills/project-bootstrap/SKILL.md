---
name: project-bootstrap
description: |
  Lê e analisa todos os componentes nativos de código de onde a pasta .agents foi inserida, atualizando as skills genéricas para adequar aos tipos, frameworks, restrições e linguagens específicas.
---

# Project Origin Bootstrapper & Context Scanner

## Gatilhos de Ativação (Triggers)
- Deve ser forçado manualmente de primeira vez caso o repositório comece vazio ou quando o usuário enviar: "Setup project context using project-bootstrap".

## Workflow de Adaptação

### 1. Descoberta de Linguagem e Framework
* O Agente deve realizar inspeção de arquivos core (`package.json`, `.csproj`, `pom.xml`, `pubspec.yaml`, `go.mod`, etc.) na raiz do ambiente externo.
* Se necessário, extrair versão de compiladores locais, frameworks nativos de View, e ORMs predominantes.

### 2. Configuração Básica de Guidelines
* Reescrever os placeholders presentes em `.agents/architecture.md` documentando explicitamente: A stack identificada, ORMs em uso, e hierarquia provável (MVC, Clean Arch, etc).
* Inicializar `.agents/guidelines.md` setando regras da sintaxe nativa da linguagem e padronização (ex: snake_case vs camelCase, se é Node ou Dart, etc).

### 3. Modificação Local das Skills
* O Agente deve refatorar os arquivos `SKILL.md` (na pasta `scaffolding`, `architecture-checker` e `finish-feature`) focando apenas na lógica relativa à linguagem daquele repositório, apagando permanentemente escopos soltos (como comandos `cargo` ou `flutter` num projeto puramente C#). Isso garantirá que outros agentes leiam apenas instruções restritas dali para frente.

## Execução Semântica e Confirmação
Após finalizado, informe ao dev que as skills foram especializadas para a stack detectada com sucesso e que agora o `start-feature` está pronto para o serviço adaptado!

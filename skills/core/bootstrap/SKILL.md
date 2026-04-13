---
name: bootstrap
description: Especialista em inicialização de projetos (Bootstrap da Squad). Faz a varredura do projeto para popular a memória técnica e de negócios da Squad. ATENÇÃO: Esta skill SÓ DEVE ser executada se houver a solicitação explícita do usuário para "instalar a squad", "fazer o setup inicial da inteligência" ou "bootstrap do projeto".
---

## Gatilhos (Execution Triggers)

- Execução inicial ou comando explícito do usuário, do tipo: "Setup project context", "Instale a squad neste projeto", ou "Execute o bootstrap". Apenas rode se explicitamente solicitado.

## Papel dos Arquivos de Memória (Regras Claras de Fronteira)

Antes de preencher os arquivos da pasta `rules/`, a IA executora deve respeitar RIGOROSAMENTE as seguintes fronteiras de responsabilidade para separar regras funcionais, regras não-funcionais e regras de código, armazenando cada aprendizado no local correto:

1. **`rules/business.md` (O Que e Para Quem - Requisitos Funcionais)**:
   - Focado em **regra de negócio**, terminologias do produto, modelos estruturais de domínio e restrições funcionais (ex: Direitos de acesso, fluxos de permissão do usuário, lógica do negócio puro).

2. **`rules/architecture.md` (Como o sistema opera estruturalmente - Requisitos Não Funcionais)**:
   - Focado em **decisões de infraestrutura e arquitetura**, fluxo de conexão de serviços, segurança global de sistemas, escalabilidade, escolhas tecnológicas principais (Ex: framework base de backend e frontend, provedor do banco de dados, abordagens de CI/CD). "Quais tecnologias sustentam o software e como os dados fluem macroarquiteturalmente".

3. **`rules/guidelines.md` (Como codificar localmente - Regras de Sintaxe, Código e Restrições)**:
   - Focado em **padrões táticos de desenvolvimento**, convenções locais da equipe, linting obrigatório, antipadrões (o que não usar dentro de components/arquivos), sintaxe da linguagem em uso e aprendizados de bugs resolvidos que não devem ser repetidos taticamente.

## Workflow de Adaptação

1. **Discovery Estrutural**:
   - Analisa todo o código-fonte existente local, identificando manifestos primários (ex: `package.json`, `.csproj`, `go.mod`, `pom.xml`, etc) e lendo partes do ecossistema e do código para extrair inteligência.

2. **Memory Init (Mapeamento de Contexto Inicial)**:
   - Escreve e preenche os tópicos no arquivo `rules/business.md` extraindo as regras de negócio primárias e requisitos funcionais detectados nesta primeira varredura do projeto em que foi instalado.
   - Escreve no arquivo `rules/architecture.md` mapeando rigorosamente os requisitos não funcionais, design do sistema, infraestrutura e arquitetura macro de componentes.
   - Escreve no arquivo `rules/guidelines.md` listando todas as tipagens, restrições técnicas, boas práticas e padrões de desenvolvimento base e sintaxe analisadas na pasta inicial do projeto (se já houver código).

3. **Skill Specialization**: 
   - Adapta comandos na skill de `delivery` (e ferramentas automatizadas de lint/teste) para refletir restritamente a linguagem/tecnologia que foi detectada.

4. **Skill Configuration**: 
   - Se aplicável, reorganiza outras estruturas de skill locais.

5. **Feedback de Instalação**:
   - Após finalizar ativamente a delegação em cascata e extração de contexto nos `rules/`, avisa ao usuário com um resumo das stacks principais detectadas e dá o Setup por Finalizado.

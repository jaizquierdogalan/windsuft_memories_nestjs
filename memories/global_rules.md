# Windsurf Global Rules and Guidelines (Project Index)

This document serves as the central index for all project guidelines. Each section links to detailed guidelines in the `memories/guidelines/` folder.

## Core Guidelines

### 1. [Communication Guidelines](guidelines/01_communication_guidelines.md)
- Response structure and tone
- Documentation style
- Error and status communication
- Maintenance communication
- Localization rules (default docs in English for this repo)

### 2. [Code Generation Guidelines](guidelines/02_code_guidelines.md)
- Language and naming conventions (TypeScript/NestJS)
- Code documentation
- Best practices
- Security considerations
- Performance and maintainability

### 3. [Commit Message Guidelines](guidelines/03_commit_message_guidelines.md)
- Conventional Commits format
- Message structure and prefixes
- Description rules
- Examples and best practices

### 4. [Tool Usage Guidelines](guidelines/04_tool_usage_guidelines.md)
- Strategic tool selection
- Information gathering
- Code modification workflow
- Terminal safety and execution rules

### 5. [Architecture Guidelines](guidelines/05_architecture_mode_guidelines.md)
- CQRS and module boundaries
- Trade-off analysis
- System design workflow
- Implementation planning and traceability

### 6. [NestJS & TypeScript Guidelines](guidelines/06_nestjs_guidelines.md)
- TypeScript general rules (naming, functions, data, classes, testing)
- NestJS module architecture and layering
- DTO validation, controllers/services patterns
- Testing guidance for controllers/services/e2e

### 7. [Monorepo, DDD, and Bounded Contexts](guidelines/07_monorepo_bounded_contexts.md)
- SWC monorepo, DDD boundaries, suggested structure, shared libraries

### 8. [CQRS, Events, and Sagas](guidelines/08_cqrs_events_sagas.md)
- Commands/Queries/Events within service boundary, EventBus, saga orchestration

### 9. [API-First Libraries](guidelines/09_api_first_libraries.md)
- Centralized schemas/DTOs in a reusable library for REST/GraphQL

### 10. [Microservices Deployment and Gateway Strategy](guidelines/10_microservices_deployment_gateway.md)
- Independent Docker deploys, unified gateway (REST/GraphQL)

### 11. [Observability: Health, Logging, and Graceful Shutdown](guidelines/11_observability_health_logging_shutdown.md)
- Terminus health/readiness, structured logging, 60s graceful shutdown for workers

### 12. [Security Baseline](guidelines/12_security_baseline.md)
- Helmet, CORS, CSRF, validation/sanitization, secrets

### 13. [Typed Configuration](guidelines/13_configuration_typed_properties.md)
- Typed/validated config, environment mappings, centralized access

### 14. [Async Local Storage](guidelines/14_async_local_storage.md)
- Correlation IDs and context propagation across async boundaries

### 15. [Branching and Environments](guidelines/15_branching_environments.md)
- main/master (prod), staging (preprod), dev (development), and short-lived branches

### 16. [API Documentation](guidelines/16_api_documentation.md)
- Swagger/OpenAPI for REST, GraphQL SDL/docs, project documentation

### 17. [Async Providers, Lazy Modules, and Circular Dependencies](guidelines/17_async_providers_lazy_modules_circular_deps.md)
- forRootAsync/forFeatureAsync with typed configuration, LazyModuleLoader patterns, avoiding circular deps (and limited forwardRef)

### 18. [Project Documentation with Compodoc](guidelines/18_documentation_compodoc.md)
- Compodoc as the project documentation tool; CI build to keep docs up-to-date

### 19. [Discord Bots with Necord](guidelines/19_discord_necord.md)
- Structure and principles for Discord bots built with Necord in NestJS

### 20. [Docker Container Baseline](guidelines/20_docker_container_baseline.md)
- Docker best practices for containerized applications

### 21. [Architecture Compliance Checklist](guidelines/21_architecture_compliance_checklist.md)
- Systematic approach to detect and fix common architectural violations
- CQRS handlers returning DTOs
- API pagination and limits enforcement
- Hexagonal architecture layer boundaries
- Domain models as interfaces with factories
- Input validation with class-validator

### 22. [NestJS Monorepo Setup](guidelines/22_nestjs_monorepo_setup.md)
- Step-by-step guide to convert single app to monorepo
- Multiple apps and shared libraries structure
- GraphQL Federation setup
- Deployment strategies (monolith vs microservices)
- Best practices and common issues

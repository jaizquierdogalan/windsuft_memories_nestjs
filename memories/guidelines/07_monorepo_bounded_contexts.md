# Monorepo, DDD, and Bounded Contexts (NestJS)

Adopt a monorepo structure for DDD with bounded contexts, using Nest's SWC monorepo recipe.

References:
- NestJS SWC Monorepo: https://docs.nestjs.com/recipes/swc#monorepo

## Principles
- One bounded context per library/app.
- Keep domains independent; share only via explicit libraries.
- Favor clear ownership of modules and APIs.

## Suggested Structure
```
/ apps/
  <service-a>/
  <service-b>/
/ libs/
  api-schema/            # API-first shared schemas (GraphQL SDL/OpenAPI/DTOs)
  shared-config/         # Typed config module
  shared-kernel/         # Shared domain abstractions (if needed)
  <context-a>/           # Context-specific domain or utilities (optional)
```

## Libraries
- api-schema: centralizes API definitions (queries/mutations/endpoints and DTOs) to reuse across services.
- shared-config: provides typed configuration with validation and sensible defaults.
- shared-kernel: optional domain primitives, do not leak concrete dependencies.

## SWC Monorepo Notes
- Use Nest CLI libraries: https://docs.nestjs.com/cli/libraries#nest-libraries
- Configure path aliases to import libraries cleanly.
- Ensure each app can be built and deployed independently.

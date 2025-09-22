# API-First: Shared Libraries for Schemas

References:
- Nest Libraries: https://docs.nestjs.com/cli/libraries#nest-libraries

## Principles
- Treat the API contract (REST or GraphQL) as the source of truth.
- Define schemas and DTOs in a dedicated library (e.g., `libs/api-schema`).
- Reuse the library across microservices in the monorepo and across external projects if needed.
- Version the schema library and publish (private registry or git-tag) for consumers.

## For GraphQL
- Store SDL (schema.graphql) or code-first resolvers/types in `libs/api-schema`.
- Export TypeScript types for inputs/outputs and re-use them in services.
- Enforce backward compatibility rules (no breaking changes without version bump).

## For REST/OpenAPI
- Centralize DTOs and validation rules in `libs/api-schema`.
- Optionally, publish an OpenAPI spec from the library for external clients.

## Tooling
- Path aliases for import convenience.
- CI job to validate schema changes (diff vs previous version).

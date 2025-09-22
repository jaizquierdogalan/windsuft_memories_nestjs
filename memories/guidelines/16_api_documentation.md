# API Documentation

## REST
- Use `@nestjs/swagger` to generate OpenAPI docs.
- Expose Swagger UI only in non-production environments or protect it.
- Keep DTOs annotated for accurate schema generation.

## GraphQL
- Keep SDL authoritative and versioned (see `libs/api-schema`).
- Use Apollo plugins to provide schema and query/mutation docs.
- Generate TypeScript types for clients where possible.

## Project Docs
- Include a high-level architecture and module overview.
- Keep the traceability matrix in sync with features and tests.

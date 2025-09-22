# Architecture Guidelines

- Follow CQRS: queries and commands separated; keep domain logic in `domain/` and adapters in `infrastructure/`.
- Keep GraphQL resolvers thin; delegate to application layer.
- Centralize configuration with `@nestjs/config`; avoid scattering `process.env`.
- Use DTOs and mappers to control boundaries and avoid leaking internals.
- Consider idempotency and retries for external calls (e.g., Jira API) and backoff strategies.
- Capture significant architectural decisions (ADRs) in `docs/` or extend `memories/` with an ADR log.
- Monitor performance and add logging/metrics for critical paths.

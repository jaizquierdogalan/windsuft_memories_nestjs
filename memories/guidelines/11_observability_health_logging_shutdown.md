# Observability: Health, Logging, and Graceful Shutdown (NestJS)

References:
- Terminus (health): https://docs.nestjs.com/recipes/terminus
- Logger: https://docs.nestjs.com/techniques/logger

## Health/Readiness
- Expose `/health` with Terminus including:
  - Liveness (process up)
  - Readiness (DB/message broker/cache reachable)
- Include version/build info for traceability.

## Logging
- Use Nest's Logger (or a structured logger like pino) via dependency injection.
- Log in structured JSON in production, include correlation/request IDs.
- Redact PII and secrets. Use log levels consistently.

## Graceful Shutdown
- Enable Nest's graceful shutdown hooks.
- Use a shutdown timeout of up to 60 seconds for background workers (consumers/cron/SQS, etc.) to finish in-flight jobs.
- HTTP servers may terminate earlier (configurable) to avoid holding connections too long, while still draining.
- Handle SIGTERM/SIGINT, stop accepting new work, and drain queues.

## Metrics & Tracing (optional)
- Export Prometheus metrics or OpenTelemetry traces if required.

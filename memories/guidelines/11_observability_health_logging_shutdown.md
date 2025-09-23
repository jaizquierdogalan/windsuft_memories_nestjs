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

### Hexagonal logging policy

- Do NOT use `console.*` in the codebase. Enforce with ESLint (`no-console: "error"`).
- Domain and Application layers MUST NOT depend on framework loggers.
  - Define a logging Port (interface) in Domain/Shared Domain.
  - Provide an Infrastructure Adapter that implements the Port using Nest Logger/Pino/Winston.
  - Inject the Port via DI where logging is needed.

Example Port (Domain):

```ts
// src/shared/domain/ports/logger.port.ts
export interface LoggerPort {
  debug(message: string, meta?: Record<string, unknown>): void;
  info(message: string, meta?: Record<string, unknown>): void;
  warn(message: string, meta?: Record<string, unknown>): void;
  error(message: string | Error, meta?: Record<string, unknown>): void;
  withContext(context: string): LoggerPort;
}
```

Example Adapter (Infrastructure):

```ts
// src/shared/infrastructure/logging/nest-logger.adapter.ts
import { Injectable, Logger } from '@nestjs/common';
import { LoggerPort } from '../../domain/ports/logger.port';

@Injectable()
export class NestLoggerAdapter implements LoggerPort {
  constructor(private readonly context = 'App') {}
  private raw(): Logger { return new Logger(this.context); }
  private fmt(msg: string, meta?: Record<string, unknown>) { return meta ? `${msg} ${JSON.stringify(meta)}` : msg; }
  debug(m: string, meta?: Record<string, unknown>) { this.raw().debug(this.fmt(m, meta)); }
  info(m: string, meta?: Record<string, unknown>)  { this.raw().log(this.fmt(m, meta)); }
  warn(m: string, meta?: Record<string, unknown>)  { this.raw().warn(this.fmt(m, meta)); }
  error(m: string | Error, meta?: Record<string, unknown>) { const s = m instanceof Error ? m.message : m; this.raw().error(this.fmt(s, meta)); }
  withContext(ctx: string): LoggerPort { return new NestLoggerAdapter(ctx); }
}
```

Binding (Global module):

```ts
// src/core/core.module.ts
import { Global, Module } from '@nestjs/common';
import { LOGGER_PORT } from '../shared/domain/ports/tokens';
import { NestLoggerAdapter } from '../shared/infrastructure/logging/nest-logger.adapter';

@Global()
@Module({
  providers: [{ provide: LOGGER_PORT, useClass: NestLoggerAdapter }],
  exports: [LOGGER_PORT],
})
export class CoreModule {}
```

### ESLint enforcement

Add the following rule to your ESLint configuration to enforce the prohibition of `console.*` calls:

```js
// .eslintrc.js
module.exports = {
  // ...
  rules: {
    // Disallow console usage across the codebase
    'no-console': 'error',
  },
};
```

Alternatively, for JSON-based configs:

```json
// .eslintrc.json
{
  "rules": {
    "no-console": "error"
  }
}
```

## Graceful Shutdown
- Enable Nest's graceful shutdown hooks.
- Use a shutdown timeout of up to 60 seconds for background workers (consumers/cron/SQS, etc.) to finish in-flight jobs.
- HTTP servers may terminate earlier (configurable) to avoid holding connections too long, while still draining.
- Handle SIGTERM/SIGINT, stop accepting new work, and drain queues.

## Metrics & Tracing (optional)
- Export Prometheus metrics or OpenTelemetry traces if required.

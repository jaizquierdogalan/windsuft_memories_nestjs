# Architecture Guidelines

- Follow CQRS: queries and commands separated; keep domain logic in `domain/` and adapters in `infrastructure/`.
- Keep GraphQL resolvers thin; delegate to application layer.
- Centralize configuration with `@nestjs/config`; avoid scattering `process.env`.
- Use DTOs and mappers to control boundaries and avoid leaking internals.
- Consider idempotency and retries for external calls (e.g., Jira API) and backoff strategies.
- Capture significant architectural decisions (ADRs) in `docs/` or extend `memories/` with an ADR log.
- Monitor performance and add logging/metrics for critical paths.

## Hexagonal Dependency Injection Policy (NestJS)

- Do NOT inject concrete implementations into Domain/Application. Always depend on Ports (interfaces) and inject them via DI tokens.
- Infrastructure provides Adapters that implement the Ports and are bound in a module (ideally a global/core module) using `{ provide: TOKEN, useClass: Adapter }`.
- Consumers (Application services, handlers, resolvers) inject the Port by token and type against the interface.

### Structure

- Domain/Shared Domain:
  - `src/shared/domain/ports/feature.port.ts` (interface)
  - `src/shared/domain/ports/tokens.ts` (DI tokens)
- Infrastructure:
  - `src/shared/infrastructure/feature/feature.adapter.ts` (implements interface)
  - `src/core/core.module.ts` binds token → adapter

### Example

Port (interface):

```ts
// src/shared/domain/ports/time.port.ts
export interface TimePort {
  now(): Date;
}

// src/shared/domain/ports/tokens.ts
export const TIME_PORT = Symbol('TIME_PORT');
```

Adapter (infrastructure):

```ts
// src/shared/infrastructure/time/system-time.adapter.ts
import { Injectable } from '@nestjs/common';
import { TimePort } from '../../domain/ports/time.port';

@Injectable()
export class SystemTimeAdapter implements TimePort {
  now(): Date {
    return new Date();
  }
}
```

Binding (module):

```ts
// src/core/core.module.ts
import { Global, Module } from '@nestjs/common';
import { TIME_PORT } from '../shared/domain/ports/tokens';
import { SystemTimeAdapter } from '../shared/infrastructure/time/system-time.adapter';

@Global()
@Module({
  providers: [{ provide: TIME_PORT, useClass: SystemTimeAdapter }],
  exports: [TIME_PORT],
})
export class CoreModule {}
```

Consumption (Application):

```ts
// src/feature/application/use-cases/do-something.handler.ts
import { Inject } from '@nestjs/common';
import { TIME_PORT } from 'src/shared/domain/ports/tokens';
import type { TimePort } from 'src/shared/domain/ports/time.port';

export class DoSomethingHandler {
  constructor(@Inject(TIME_PORT) private readonly clock: TimePort) {}
  execute() {
    const ts = this.clock.now();
    // ...
  }
}
```

### Prohibited Practices

- Injecting concrete classes from `infrastructure/` directly into Domain/Application.
- Importing framework-specific classes (Nest `Logger`, ORM repositories, HTTP clients) into Domain/Application.
- Bypassing Ports by referencing Adapters directly.

Follow this policy to keep the Domain/Application layers framework-agnostic and easily testable, while Infrastructure remains free to depend on concrete libraries.

### Enforcement (Recommended)

Add lint rules to ensure interfaces (Ports) are injected and to prevent cross-layer imports:

1) ESLint Boundaries (preferred)

```js
// .eslintrc.js
module.exports = {
  plugins: ['boundaries'],
  settings: {
    'boundaries/elements': [
      { type: 'domain', pattern: 'src/**/domain/**' },
      { type: 'application', pattern: 'src/**/application/**' },
      { type: 'infrastructure', pattern: 'src/**/infrastructure/**' },
      { type: 'shared', pattern: 'src/shared/**' },
    ],
  },
  rules: {
    'boundaries/element-types': [
      'error',
      {
        default: 'allow',
        message:
          'Hexagonal rule violation: Domain/Application cannot depend on Infrastructure. Depend on Ports (interfaces) instead.',
        rules: [
          { from: 'domain', disallow: ['infrastructure', 'application'] },
          { from: 'application', disallow: ['infrastructure'] },
          // shared can be used by any
        ],
      },
    ],
  },
};
```

2) ESLint Import Restrictions (alternative)

```js
// .eslintrc.js (requires eslint-plugin-import)
module.exports = {
  plugins: ['import'],
  rules: {
    'import/no-restricted-paths': [
      'error',
      {
        zones: [
          {
            target: './src/**/domain/',
            from: './src/**/infrastructure/',
            message:
              'Domain must not import from Infrastructure. Use Ports (interfaces).',
          },
          {
            target: './src/**/application/',
            from: './src/**/infrastructure/',
            message:
              'Application must not import from Infrastructure. Use Ports (interfaces).',
          },
        ],
      },
    ],
  },
};
```

3) DI Usage Pattern (code review checklist)

- Providers bind tokens to adapters in modules: `{ provide: TOKEN, useClass: Adapter }`.
- Consumers inject by token and type against the interface: `constructor(@Inject(TOKEN) dep: Port)`.
- No `new ConcreteAdapter()` or direct import of adapter types in Domain/Application.

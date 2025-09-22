# CQRS, Events, and Sagas (NestJS)

References:
- CQRS: https://docs.nestjs.com/recipes/cqrs
- Events: https://docs.nestjs.com/recipes/cqrs#events
- Sagas: https://docs.nestjs.com/recipes/cqrs#sagas

## Scope
- Use CQRS within the service boundary (no distributed CQRS implied here).
- Commands mutate state; Queries read state; Events notify other parts of the system.
- Use the Nest EventBus for internal domain events and microservice integration events (published through the messaging layer if applicable).
- Use Sagas to orchestrate long-running, multi-step workflows via reactive streams of events.

## Structure
Suggested per bounded context (app or library):
```
src/
  application/
    commands/ + handlers/
    queries/  + handlers/
    events/   + handlers/
    sagas/
  domain/
    models/ entities/ value-objects/
    services/
  infrastructure/
    messaging/ (publish/subscribe adapters)
    persistence/
```

## Guidelines
- Naming: `CreateOrderCommand`, `GetOrderQuery`, `OrderCreatedEvent`, `OrderProcessSaga`.
- Idempotency: command handlers and event handlers must be idempotent where re-delivery is possible.
- Version events: include `version` and `occurredAt` to support evolution.
- Event boundaries: differentiate domain events (inside service) from integration events (published to other services).
- Sagas:
  - Keep orchestration logic in sagas; keep handlers focused on a single responsibility.
  - Use timeouts/retries/backoff for external calls.
  - Ensure compensating actions are well-defined for error branches.

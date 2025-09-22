# Microservices Deployment and Gateway Strategy (NestJS)

## Deployment
- Each microservice must be independently deployable via Docker (own Dockerfile).
- Support a unified deployment (compose/helm) for local/dev if desired.
- Expose health/readiness endpoints per service.

## API Gateway
- REST: implement an API Gateway service that proxies/aggregates routes to internal services.
- GraphQL: consider Federation with Apollo Gateway or schema stitching to unify schemas.
- Validate authentication/authorization at the edge and propagate identity/claims downstream.

## NestJS Options
- For GraphQL federation, see Nest GraphQL federation and Apollo Gateway integrations.
- For REST, create a dedicated gateway app within `/apps/gateway` that routes requests to services.

## Contracts
- API-first library (`libs/api-schema`) is shared between services and the gateway.
- The gateway must not implement business logic; only orchestration, authn/z, and cross-cutting concerns.

## Operations
- Canary or progressive delivery per service.
- Standardized logging/metrics and health checks across services.

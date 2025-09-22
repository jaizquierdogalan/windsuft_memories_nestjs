# Async Local Storage (ALS) Usage

References:
- ALS: https://docs.nestjs.com/recipes/async-local-storage

## Use Cases
- Propagate correlation IDs and user context across async boundaries.
- Attach request-specific metadata to logs and metrics.

## Guidelines
- Initialize ALS per request in an interceptor/middleware.
- Store read-only contextual data (ids, tenant, user) to avoid hidden coupling.
- Clean up context on request completion.

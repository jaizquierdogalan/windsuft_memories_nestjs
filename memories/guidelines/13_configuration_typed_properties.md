# Typed Configuration (NestJS)

References:
- Configuration: https://docs.nestjs.com/techniques/configuration

## Principles
- Each config property must be typed and validated at startup.
- Centralize config in a library (e.g., `libs/shared-config`) and expose typed accessors.
- Use schemas (e.g., Joi/class-validator) to validate environment variables.

## Environments
- Standard branches map to environments: `dev`, `staging`, `main/master` (prod).
- Use convention-driven defaults to reduce infra configuration; override via explicit env vars when needed.

## Usage
- Inject `ConfigService` or a typed wrapper (e.g., `AppConfig`) into modules/services.
- No direct `process.env` access outside the config module.

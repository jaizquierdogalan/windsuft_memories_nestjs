# Discord Bots with Necord (NestJS)

References:
- Necord: https://docs.nestjs.com/recipes/necord#necord

## Principles
- Encapsulate Discord bot logic in a dedicated module (e.g., `discord-bot` app or module) within the monorepo.
- Keep command/interaction handlers small and testable; separate infrastructure (Discord API) from application logic.
- Reuse shared DTOs/types from `libs/api-schema` where applicable.

## Structure
```
apps/
  discord-bot/
    src/
      bot.module.ts
      bot.update.ts         # Update handlers (interactions/events)
      commands/
      services/
      config/
```

## Configuration
- Load Discord token, client ID, guild IDs via typed configuration.
- Use environment-specific registration (dev/staging/prod) for commands.

## Testing
- Unit test handlers and services with mocked Necord adapters.
- Do not hit the real Discord API in unit tests.

## Security & Operations
- Store tokens in secret stores; rotate periodically.
- Scope bot permissions to the minimum required.

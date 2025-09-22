# Async Providers, Lazy-loaded Modules, and Circular Dependencies (NestJS)

References:
- Async Providers: https://docs.nestjs.com/fundamentals/async-providers
- Lazy-loading Modules: https://docs.nestjs.com/fundamentals/lazy-loading-modules
- Circular Dependency: https://docs.nestjs.com/fundamentals/circular-dependency

## Async Providers
- Prefer `forRootAsync` / `forFeatureAsync` registration for modules that depend on runtime configuration or secrets.
- Use `useFactory` with async support to build options and clients; inject `ConfigService` (or a typed config wrapper) and other dependencies.
- Consider `useClass` or `useExisting` patterns when delegating to a custom options factory.
- Avoid hard-coded sync configs in module registration; keep secrets/config in the typed configuration layer.
- Example (options factory):
```ts
@Module({
  imports: [
    SomeModule.forRootAsync({
      inject: [ConfigService],
      useFactory: async (cfg: ConfigService) => ({
        endpoint: cfg.getOrThrow('SOME_ENDPOINT'),
        apiKey: cfg.getOrThrow('SOME_API_KEY'),
      }),
    }),
  ],
})
export class AppModule {}
```

## Lazy-loaded Modules
- Use `LazyModuleLoader` to defer loading of heavy or optional modules until needed (e.g., admin tools, batch features, expensive clients).
- Avoid importing heavy modules in the root graph by default when they are not always required at runtime.
- Keep lazy-loaded providers stateless or clearly lifecycle-managed; avoid hidden global state.
- Example:
```ts
@Injectable()
export class FeatureService {
  constructor(private readonly lazy: LazyModuleLoader) {}

  async loadAndRun() {
    const { FeatureModule } = await import('./feature/feature.module');
    const moduleRef = await this.lazy.load(() => FeatureModule);
    const svc = moduleRef.get(FeatureRunnerService, { strict: false });
    return svc.run();
  }
}
```

## Avoiding Circular Dependencies
- Design for acyclic dependencies across modules and providers:
  - Respect bounded contexts; depend inward on abstractions, not outward on concrete modules.
  - Extract shared abstractions (interfaces/tokens) into dedicated libraries to break cycles.
  - Use events (CQRS/EventBus) to decouple write/read flows and cross-context notifications.
- If a cycle is unavoidable, use `forwardRef` sparingly as a last resort at the module and/or provider level; plan a refactor to remove the cycle.
- Prefer dependency inversion via injection tokens and interfaces over direct class-to-class references.
- Consider static analysis lint rules to detect cycles (e.g., `import/no-cycle`) and keep module graphs clean.

# NestJS Monorepo Setup Guide

This guide explains how to convert a NestJS single application into a monorepo structure with multiple apps and shared libraries.

References:
- NestJS Monorepo: https://docs.nestjs.com/cli/monorepo
- NestJS Libraries: https://docs.nestjs.com/cli/libraries

## Why Monorepo?

**Benefits:**
- Share code between microservices
- Unified development experience
- Single repository for related services
- Flexible deployment (monolith or microservices)
- Easier refactoring and testing

**When to use:**
- Multiple related services (auth, api, workers)
- Shared domain logic or DTOs
- Want to start as monolith, scale to microservices later

## Structure

```
project/
├── apps/
│   ├── gateway/          # API Gateway (monolith or federation)
│   ├── service-a/        # Microservice A
│   └── service-b/        # Microservice B
├── libs/
│   ├── api-schema/       # Shared DTOs and GraphQL types
│   ├── shared-config/    # Shared configuration
│   └── shared-kernel/    # Shared domain logic
├── nest-cli.json         # Monorepo configuration
├── tsconfig.json         # Root TypeScript config
└── package.json          # Shared dependencies
```

## Step-by-Step Migration

### Step 1: Update nest-cli.json

Convert from single app to monorepo:

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "apps/gateway/src",
  "monorepo": true,
  "root": "apps/gateway",
  "compilerOptions": {
    "deleteOutDir": true,
    "webpack": true,
    "tsConfigPath": "apps/gateway/tsconfig.app.json"
  },
  "projects": {
    "gateway": {
      "type": "application",
      "root": "apps/gateway",
      "entryFile": "main",
      "sourceRoot": "apps/gateway/src",
      "compilerOptions": {
        "tsConfigPath": "apps/gateway/tsconfig.app.json"
      }
    },
    "service-a": {
      "type": "application",
      "root": "apps/service-a",
      "entryFile": "main",
      "sourceRoot": "apps/service-a/src",
      "compilerOptions": {
        "tsConfigPath": "apps/service-a/tsconfig.app.json"
      }
    },
    "api-schema": {
      "type": "library",
      "root": "libs/api-schema",
      "entryFile": "index",
      "sourceRoot": "libs/api-schema/src",
      "compilerOptions": {
        "tsConfigPath": "libs/api-schema/tsconfig.lib.json"
      }
    }
  }
}
```

### Step 2: Create Directory Structure

```bash
# Create apps
mkdir -p apps/gateway/src
mkdir -p apps/service-a/src

# Create libs
mkdir -p libs/api-schema/src
mkdir -p libs/shared-config/src

# Move existing code
mv src apps/gateway/
mv test apps/gateway/
```

### Step 3: Update Root tsconfig.json

Add path aliases for apps and libs:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "paths": {
      "@app/gateway": ["apps/gateway/src"],
      "@app/gateway/*": ["apps/gateway/src/*"],
      "@app/service-a": ["apps/service-a/src"],
      "@app/service-a/*": ["apps/service-a/src/*"],
      "@lib/api-schema": ["libs/api-schema/src"],
      "@lib/api-schema/*": ["libs/api-schema/src/*"],
      "@lib/shared-config": ["libs/shared-config/src"],
      "@lib/shared-config/*": ["libs/shared-config/src/*"]
    }
  }
}
```

### Step 4: Create tsconfig for Each App/Lib

**apps/gateway/tsconfig.app.json:**
```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "declaration": false,
    "outDir": "../../dist/apps/gateway"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test", "**/*spec.ts"]
}
```

**libs/api-schema/tsconfig.lib.json:**
```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "declaration": true,
    "outDir": "../../dist/libs/api-schema"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test", "**/*spec.ts"]
}
```

### Step 5: Update package.json Scripts

```json
{
  "scripts": {
    "build": "nest build",
    "build:gateway": "nest build gateway",
    "build:service-a": "nest build service-a",
    "build:all": "nest build gateway && nest build service-a",
    
    "start": "nest start gateway",
    "start:dev": "nest start gateway --watch",
    "start:prod": "node dist/apps/gateway/main",
    
    "start:service-a": "nest start service-a --watch",
    
    "test": "jest",
    "test:gateway": "jest --projects apps/gateway",
    "test:service-a": "jest --projects apps/service-a"
  }
}
```

### Step 6: Create Shared Library

**libs/api-schema/src/index.ts:**
```typescript
// Export all shared DTOs
export * from './user/user.dto';
export * from './common/pagination.dto';
```

**Usage in apps:**
```typescript
// apps/gateway/src/users/users.controller.ts
import { UserDto } from '@lib/api-schema';

@Controller('users')
export class UsersController {
  @Get()
  findAll(): UserDto[] {
    return [];
  }
}
```

## Deployment Strategies

### Strategy 1: Monolith (Development/Staging)

Deploy gateway with all modules imported:

```typescript
// apps/gateway/src/app.module.ts
import { Module } from '@nestjs/common';
import { UsersModule } from '@app/service-a/users/users.module';

@Module({
  imports: [
    UsersModule, // Import directly
  ],
})
export class AppModule {}
```

**Build:**
```bash
npm run build:gateway
node dist/apps/gateway/main
```

### Strategy 2: Microservices (Production)

Deploy each app independently:

```bash
# Build all
npm run build:all

# Deploy separately
node dist/apps/gateway/main      # Port 3000
node dist/apps/service-a/main    # Port 3001
```

Use GraphQL Federation or API Gateway to unify.

## GraphQL Federation Setup

### Gateway (Apollo Federation)

```typescript
// apps/gateway/src/app.module.ts
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloGatewayDriver, ApolloGatewayDriverConfig } from '@nestjs/apollo';
import { IntrospectAndCompose } from '@apollo/gateway';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloGatewayDriverConfig>({
      driver: ApolloGatewayDriver,
      gateway: {
        supergraphSdl: new IntrospectAndCompose({
          subgraphs: [
            { name: 'users', url: 'http://localhost:3001/graphql' },
            { name: 'posts', url: 'http://localhost:3002/graphql' },
          ],
        }),
      },
    }),
  ],
})
export class AppModule {}
```

### Subgraph (Service)

```typescript
// apps/service-a/src/app.module.ts
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloFederationDriver, ApolloFederationDriverConfig } from '@nestjs/apollo';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloFederationDriverConfig>({
      driver: ApolloFederationDriver,
      autoSchemaFile: {
        federation: 2,
      },
    }),
    UsersModule,
  ],
})
export class AppModule {}
```

## Best Practices

### 1. Shared Libraries
- Keep libs focused and cohesive
- Use `@lib/*` prefix for imports
- Export only public APIs in `index.ts`

### 2. Dependencies
- Shared dependencies in root `package.json`
- App-specific dependencies in app's `package.json` (if needed)

### 3. Testing
- Unit tests per app/lib
- Integration tests in gateway
- E2E tests for full system

### 4. CI/CD
- Build all apps in parallel
- Deploy independently
- Use Docker multi-stage builds

### 5. Versioning
- Version shared libs independently
- Use semantic versioning
- Document breaking changes

## Common Issues

### Issue 1: Import Errors

**Problem:** `Cannot find module '@app/service-a'`

**Solution:** Ensure `tsconfig.json` paths are correct and restart IDE/TS server.

### Issue 2: Circular Dependencies

**Problem:** Apps importing from each other

**Solution:** Use shared libs for common code, never import between apps.

### Issue 3: Build Errors

**Problem:** `Cannot find module` during build

**Solution:** Build dependencies first:
```bash
nest build api-schema
nest build gateway
```

## Migration Checklist

- [ ] Backup current code
- [ ] Update `nest-cli.json` for monorepo
- [ ] Create directory structure
- [ ] Move existing code to `apps/`
- [ ] Update root `tsconfig.json` with paths
- [ ] Create `tsconfig.app.json` for each app
- [ ] Create `tsconfig.lib.json` for each lib
- [ ] Update `package.json` scripts
- [ ] Test build: `npm run build:all`
- [ ] Test dev: `npm run start:dev`
- [ ] Update imports to use `@app/*` and `@lib/*`
- [ ] Update CI/CD pipelines
- [ ] Update documentation

## References

- [NestJS Monorepo Documentation](https://docs.nestjs.com/cli/monorepo)
- [NestJS Libraries](https://docs.nestjs.com/cli/libraries)
- [Apollo Federation](https://www.apollographql.com/docs/federation/)
- [Guideline 07: Monorepo & Bounded Contexts](07_monorepo_bounded_contexts.md)

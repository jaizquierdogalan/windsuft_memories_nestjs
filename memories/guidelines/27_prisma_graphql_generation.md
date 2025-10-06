# Guideline 27: Prisma + GraphQL Type Generation with PalJS

## Overview

This project uses **Prisma** as the ORM and automatically generates GraphQL types, inputs, and models from the Prisma schema using **@paljs/generator**. The **@paljs/plugins** library provides runtime utilities like `PrismaSelect` to optimize database queries.

## Stack Components

### 1. Prisma
- **ORM**: Handles database migrations, schema definition, and type-safe database access
- **Schema location**: `prisma/schema.prisma`
- **Client**: Auto-generated `@prisma/client` provides type-safe database operations

### 2. @paljs/generator
- **Purpose**: Generates NestJS GraphQL types from Prisma schema
- **Output**: Creates `@InputType`, `@ObjectType`, filters, and update/create inputs
- **Location**: `src/@generated/`

### 3. @paljs/plugins
- **PrismaSelect**: Runtime plugin that optimizes Prisma queries by selecting only requested GraphQL fields
- **Prevents N+1 queries** and overfetching from database

## Workflow

### Step 1: Define Schema in Prisma

```prisma
// prisma/schema.prisma
model Programmer {
  id             String    @id @default(uuid())
  email          String
  name           String
  startDate      DateTime
  endDate        DateTime?
  githubUsername String?
  jiraUsername   String?
  
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  createdBy String?
  updatedBy String?

  @@map("programmers")
}
```

### Step 2: Generate Prisma Client & GraphQL Types

Run the following commands in sequence:

```bash
# 1. Generate Prisma Client
npx prisma generate

# 2. Generate GraphQL types from Prisma schema
npm run prisma:generate

# 3. Generate GraphQL schema file (schema.graphql)
npm run generate:schema
```

**What gets generated:**
- `src/@generated/programmer/`
  - `programmer.model.ts` - GraphQL ObjectType
  - `programmer-create.input.ts` - Create input DTO
  - `programmer-update.input.ts` - Update input DTO
  - `programmer-where.input.ts` - Filter/query input
  - Various field update inputs

### Step 3: Use Generated Types in Resolvers

```typescript
import { Resolver, Query, Args, Info } from '@nestjs/graphql';
import { PrismaService } from '@/shared/infrastructure/database/prisma.service';
import { PrismaSelect } from '@paljs/plugins';
import { GraphQLResolveInfo } from 'graphql';
import { Programmer } from '@/@generated/programmer/programmer.model';
import { ProgrammerWhereInput } from '@/@generated/programmer/programmer-where.input';

@Resolver(() => Programmer)
export class ProgrammerResolver {
  constructor(private readonly prisma: PrismaService) {}

  @Query(() => [Programmer], { name: 'programmers' })
  async findProgrammers(
    @Args('where', { nullable: true }) where?: ProgrammerWhereInput,
    @Info() info?: GraphQLResolveInfo,
  ): Promise<Programmer[]> {
    // PrismaSelect optimizes the query to only select requested fields
    const select = info ? new PrismaSelect(info).value : undefined;
    return this.prisma.programmer.findMany({ where, ...select });
  }
}
```

## Key Principles

### 1. Schema-First Approach
- **Prisma schema is the source of truth** for both database and GraphQL types
- Any changes to data models start in `schema.prisma`

### 2. Regenerate After Schema Changes
After modifying `schema.prisma`:
```bash
npx prisma migrate dev --name description_of_change  # Creates migration
npm run prisma:generate                               # Regenerates types
npm run generate:schema                               # Updates schema.graphql
```

### 3. Use PrismaSelect for Optimization
Always use `PrismaSelect` in resolvers to:
- Only query fields that the client requested
- Avoid N+1 queries
- Optimize database performance

```typescript
const select = info ? new PrismaSelect(info).value : undefined;
return this.prisma.model.findMany({ ...select });
```

### 4. Never Manually Edit Generated Files
- Files in `src/@generated/` are auto-generated
- Manual edits will be overwritten on next generation
- Extend functionality through custom resolvers or DTOs

## Frontend Type Generation

The backend's `schema.graphql` is used to generate frontend types:

```bash
# In frontend directory
GRAPHQL_SCHEMA=../back/schema.graphql npm run codegen
```

This creates type-safe Apollo client operations.

## Package.json Scripts

```json
{
  "scripts": {
    "prisma:generate": "prisma generate",
    "generate:schema": "ts-node src/generate-schema.ts",
    "prisma:migrate": "npx prisma migrate dev",
    "prisma:seed": "ts-node prisma/seed.ts"
  }
}
```

## Configuration

### prisma/schema.prisma

```prisma
generator client {
  provider = "prisma-client-js"
}

generator nestgraphql {
  provider = "node node_modules/@paljs/generator"
  output   = "../src/@generated"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

## Best Practices

### ✅ DO
- Keep Prisma schema as single source of truth
- Use generated types in resolvers
- Use PrismaSelect for all queries
- Regenerate after schema changes
- Run migrations before deploying

### ❌ DON'T
- Manually edit files in `src/@generated/`
- Skip regeneration after schema changes
- Create custom GraphQL types that duplicate Prisma models
- Forget to run migrations after schema changes

## Common Issues

### Issue: Frontend shows "property should not exist"
**Solution**: Frontend types are stale. Regenerate frontend types:
```bash
cd front
GRAPHQL_SCHEMA=../back/schema.graphql npm run codegen
```

### Issue: Generated types missing after schema change
**Solution**: Run the full generation workflow:
```bash
npx prisma generate
npm run prisma:generate
npm run generate:schema
```

### Issue: Database out of sync with schema
**Solution**: Create and apply migration:
```bash
npx prisma migrate dev --name fix_schema_sync
```

## Related Guidelines

- **06_nestjs_guidelines.md**: NestJS patterns and module structure
- **25_database_transactions.md**: Prisma transaction patterns
- **16_api_documentation.md**: GraphQL schema documentation

# Architecture Compliance Checklist

This guideline provides a systematic approach to detect and fix common architectural violations in NestJS projects following CQRS, Hexagonal Architecture, and DDD principles.

## Common Violations and Solutions

### 1. CQRS: Handlers Returning Domain Objects

**Violation:**
Query/Command handlers return domain entities, primitives, or infrastructure types instead of DTOs.

**Why it's wrong:**
- Leaks internal domain structure to API consumers
- Prevents API versioning independent of domain
- Couples API contract to domain implementation
- Makes it harder to add/remove fields without breaking changes

**Detection:**
```typescript
// ❌ WRONG: Returns primitive
@QueryHandler(GetUserQuery)
export class GetUserHandler implements IQueryHandler<GetUserQuery, number> {
  async execute(query: GetUserQuery): Promise<number> {
    return userId; // Primitive leaked to API
  }
}

// ❌ WRONG: Returns domain entity
@QueryHandler(GetUserQuery)
export class GetUserHandler implements IQueryHandler<GetUserQuery, User> {
  async execute(query: GetUserQuery): Promise<User> {
    return userEntity; // Domain entity leaked to API
  }
}
```

**Solution:**
```typescript
// ✅ CORRECT: Returns DTO
// application/queries/dto/user-response.dto.ts
import { Field, ObjectType } from '@nestjs/graphql';

@ObjectType()
export class UserResponseDto {
  @Field(() => String)
  readonly id: string;

  @Field(() => String)
  readonly email: string;

  @Field(() => String)
  readonly name: string;

  @Field(() => Date)
  readonly createdAt: Date;
}

// application/queries/handlers/get-user.handler.ts
@QueryHandler(GetUserQuery)
export class GetUserHandler 
  implements IQueryHandler<GetUserQuery, UserResponseDto> {
  
  async execute(query: GetUserQuery): Promise<UserResponseDto> {
    const user = await this.userRepository.findById(query.userId);
    
    // Map domain to DTO
    return {
      id: user.id,
      email: user.email,
      name: user.fullName,
      createdAt: user.createdAt,
    };
  }
}
```

**Checklist:**
- [ ] All Query Handlers return DTOs
- [ ] All Command Handlers return DTOs or void
- [ ] DTOs are annotated with GraphQL/Swagger decorators
- [ ] Mappers exist to convert domain ↔ DTO
- [ ] No domain entities exposed in API layer

---

### 2. API: Missing Pagination and Limits

**Violation:**
Search/list endpoints don't enforce pagination or have unreasonably high limits.

**Why it's wrong:**
- Can return thousands of records, degrading performance
- No way for clients to paginate results
- Memory issues on both server and client
- Poor user experience with slow loading

**Detection:**
```typescript
// ❌ WRONG: No pagination, no limit
export interface SearchPort {
  search(query: string): Promise<Item[]>; // Can return 10,000+ items
}

// ❌ WRONG: Optional limit without maximum
export interface SearchOptions {
  limit?: number; // Could be 999,999
}
```

**Solution:**
```typescript
// ✅ CORRECT: Mandatory pagination with max limit
// domain/criteria/pagination.ts
import { IsInt, Min, Max } from 'class-validator';

export class Pagination {
  @IsInt()
  @Min(1)
  readonly page: number;

  @IsInt()
  @Min(1)
  @Max(100) // Enforce maximum
  readonly limit: number;

  constructor(page: number = 1, limit: number = 20) {
    this.page = page;
    this.limit = Math.min(limit, 100); // Double-check
  }

  get offset(): number {
    return (this.page - 1) * this.limit;
  }
}

// domain/criteria/search-criteria.ts
export interface SearchCriteria {
  readonly filters: Record<string, unknown>;
  readonly pagination: Pagination; // Mandatory
  readonly sorting?: {
    readonly field: string;
    readonly order: 'ASC' | 'DESC';
  };
}

// domain/criteria/search-result.ts
export interface SearchResult<T> {
  readonly items: T[];
  readonly total: number;
  readonly page: number;
  readonly limit: number;
  readonly hasMore: boolean;
  readonly totalPages: number;
}

// domain/ports/search.port.ts
export interface SearchPort<T> {
  search(criteria: SearchCriteria): Promise<SearchResult<T>>;
}

// GraphQL Input with validation
import { InputType, Field, Int } from '@nestjs/graphql';

@InputType()
export class SearchInput {
  @Field(() => String)
  query: string;

  @Field(() => Int, { defaultValue: 1 })
  @Min(1)
  page: number;

  @Field(() => Int, { defaultValue: 20 })
  @Min(1)
  @Max(100) // Validated at API boundary
  limit: number;
}
```

**Checklist:**
- [ ] All search/list operations require pagination
- [ ] Maximum limit is 100 (or project-specific reasonable limit)
- [ ] Pagination is validated with `class-validator`
- [ ] Results include metadata (total, hasMore, totalPages)
- [ ] GraphQL/REST inputs enforce limits
- [ ] Documentation mentions pagination requirements

---

### 3. Hexagonal: Domain Depending on Infrastructure

**Violation:**
Domain or Application layers import concrete implementations from Infrastructure.

**Why it's wrong:**
- Violates Dependency Inversion Principle
- Makes domain untestable without infrastructure
- Couples business logic to technical details
- Prevents swapping implementations

**Detection:**
```typescript
// ❌ WRONG: Domain importing infrastructure
// domain/services/user.service.ts
import { TypeOrmUserRepository } from '../../infrastructure/persistence/typeorm-user.repository';

export class UserDomainService {
  constructor(
    private readonly userRepo: TypeOrmUserRepository, // Concrete class!
  ) {}
}

// ❌ WRONG: Application importing infrastructure
// application/commands/handlers/create-user.handler.ts
import { JiraClient } from '../../../infrastructure/api-client/jira-client';

export class CreateUserHandler {
  constructor(
    private readonly jiraClient: JiraClient, // Concrete class!
  ) {}
}
```

**Solution:**
```typescript
// ✅ CORRECT: Use Ports (interfaces)
// domain/ports/user-repository.port.ts
export interface UserRepositoryPort {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

export const USER_REPOSITORY_PORT = Symbol('USER_REPOSITORY_PORT');

// domain/services/user.service.ts
import { Inject } from '@nestjs/common';
import { USER_REPOSITORY_PORT } from '../ports/user-repository.port';
import type { UserRepositoryPort } from '../ports/user-repository.port';

export class UserDomainService {
  constructor(
    @Inject(USER_REPOSITORY_PORT)
    private readonly userRepo: UserRepositoryPort, // Interface!
  ) {}
}

// infrastructure/persistence/typeorm-user.repository.ts
import { Injectable } from '@nestjs/common';
import { UserRepositoryPort } from '../../domain/ports/user-repository.port';

@Injectable()
export class TypeOrmUserRepository implements UserRepositoryPort {
  async findById(id: string): Promise<User | null> {
    // TypeORM implementation
  }
  
  async save(user: User): Promise<void> {
    // TypeORM implementation
  }
}

// core/core.module.ts
import { Global, Module } from '@nestjs/common';
import { USER_REPOSITORY_PORT } from '../domain/ports/user-repository.port';
import { TypeOrmUserRepository } from '../infrastructure/persistence/typeorm-user.repository';

@Global()
@Module({
  providers: [
    {
      provide: USER_REPOSITORY_PORT,
      useClass: TypeOrmUserRepository,
    },
  ],
  exports: [USER_REPOSITORY_PORT],
})
export class CoreModule {}
```

**Checklist:**
- [ ] Domain layer only imports from domain/
- [ ] Application layer only imports from domain/ and application/
- [ ] All external dependencies injected via Ports (interfaces)
- [ ] DI tokens used for all Port injections
- [ ] Infrastructure binds Ports to Adapters in modules
- [ ] No `new ConcreteClass()` in domain/application
- [ ] ESLint rules enforce layer boundaries

---

### 4. Domain Models: Classes Instead of Interfaces

**Violation:**
Domain models are concrete classes with methods, coupling domain to implementation details.

**Why it's wrong:**
- Harder to test (need to instantiate classes)
- Couples domain to specific OOP patterns
- Makes mocking more complex
- Can leak framework dependencies

**Detection:**
```typescript
// ❌ WRONG: Concrete class in domain
// domain/models/user.model.ts
export class User {
  constructor(
    public readonly id: string,
    public readonly email: string,
    public readonly name: string,
  ) {}

  static create(email: string, name: string): User {
    return new User(uuid(), email, name);
  }

  changeName(newName: string): User {
    return new User(this.id, this.email, newName);
  }
}
```

**Solution:**
```typescript
// ✅ CORRECT: Interface + Factory
// domain/models/user.ts
export interface User {
  readonly id: string;
  readonly email: string;
  readonly name: string;
}

// domain/factories/user.factory.ts
import { Injectable } from '@nestjs/common';
import { v4 as uuid } from 'uuid';

@Injectable()
export class UserFactory {
  create(email: string, name: string): User {
    // Domain validations
    if (!email.includes('@')) {
      throw new Error('Invalid email');
    }
    
    if (name.length < 2) {
      throw new Error('Name too short');
    }

    return {
      id: uuid(),
      email,
      name,
    };
  }

  changeName(user: User, newName: string): User {
    if (newName.length < 2) {
      throw new Error('Name too short');
    }

    return {
      ...user,
      name: newName,
    };
  }
}
```

**Checklist:**
- [ ] Domain models are interfaces, not classes
- [ ] Factories handle object creation
- [ ] Domain validations in factories
- [ ] Factories are injectable services
- [ ] Easy to mock in tests
- [ ] No framework dependencies in domain models

---

### 5. Missing Input Validation

**Violation:**
Query/Command inputs not validated with `class-validator`.

**Why it's wrong:**
- Runtime errors instead of validation errors
- Unclear error messages for clients
- Security vulnerabilities (injection attacks)
- Inconsistent validation across endpoints

**Detection:**
```typescript
// ❌ WRONG: No validation
export class CreateUserCommand {
  constructor(
    public readonly email: string,
    public readonly age: number,
  ) {}
}
```

**Solution:**
```typescript
// ✅ CORRECT: Validated with class-validator
import { IsEmail, IsInt, Min, Max, IsNotEmpty } from 'class-validator';

export class CreateUserCommand {
  @IsEmail()
  @IsNotEmpty()
  readonly email: string;

  @IsInt()
  @Min(18)
  @Max(120)
  readonly age: number;

  constructor(email: string, age: number) {
    this.email = email;
    this.age = age;
  }
}

// GraphQL Input
import { InputType, Field, Int } from '@nestjs/graphql';

@InputType()
export class CreateUserInput {
  @Field(() => String)
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @Field(() => Int)
  @IsInt()
  @Min(18)
  @Max(120)
  age: number;
}
```

**Checklist:**
- [ ] All Commands have validation decorators
- [ ] All Queries have validation decorators
- [ ] GraphQL Inputs use `class-validator`
- [ ] REST DTOs use `class-validator`
- [ ] ValidationPipe enabled globally
- [ ] Custom validators for complex rules

---

## Automated Detection

### ESLint Configuration

```javascript
// .eslintrc.js
module.exports = {
  plugins: ['boundaries'],
  settings: {
    'boundaries/elements': [
      { type: 'domain', pattern: 'src/**/domain/**' },
      { type: 'application', pattern: 'src/**/application/**' },
      { type: 'infrastructure', pattern: 'src/**/infrastructure/**' },
    ],
  },
  rules: {
    'boundaries/element-types': [
      'error',
      {
        default: 'allow',
        message: 'Hexagonal rule violation: {{from}} cannot depend on {{to}}',
        rules: [
          { from: 'domain', disallow: ['infrastructure', 'application'] },
          { from: 'application', disallow: ['infrastructure'] },
        ],
      },
    ],
  },
};
```

### Pre-commit Hook

```bash
#!/bin/bash
# .husky/pre-commit

# Run linter
npm run lint

# Check for common violations
echo "Checking for architectural violations..."

# Check for domain importing infrastructure
if grep -r "from.*infrastructure" src/**/domain/**/*.ts; then
  echo "❌ Domain layer importing from Infrastructure!"
  exit 1
fi

# Check for handlers returning non-DTOs
if grep -r "IQueryHandler.*Promise<number>" src/**/*.ts; then
  echo "⚠️  Query handler returning primitive - should return DTO"
fi

echo "✅ Architecture checks passed"
```

---

## Refactoring Checklist

When fixing violations in an existing project:

### Phase 1: Critical (Week 1-2)
- [ ] Add pagination with max limits to all searches
- [ ] Create DTOs for all Query/Command handlers
- [ ] Update handlers to return DTOs
- [ ] Update GraphQL schema
- [ ] Update tests

### Phase 2: High Priority (Week 3)
- [ ] Convert domain models to interfaces
- [ ] Create factories for domain objects
- [ ] Add validation to all Commands/Queries
- [ ] Verify all Ports are used (no concrete classes)

### Phase 3: Medium Priority (Week 4)
- [ ] Add JSDoc documentation
- [ ] Configure Compodoc
- [ ] Add ESLint boundary rules
- [ ] Create ADRs for decisions

### Phase 4: Maintenance (Ongoing)
- [ ] Code review checklist includes architecture
- [ ] CI/CD enforces linting
- [ ] Regular architecture reviews
- [ ] Update documentation

---

## Success Metrics

### Before Refactoring
- % of handlers returning DTOs
- % of searches with pagination
- % of domain using interfaces
- % of code documented
- Number of layer boundary violations

### After Refactoring
- 100% handlers return DTOs
- 100% searches have max limit 100
- 100% domain models are interfaces
- 80%+ code documented with JSDoc
- 0 layer boundary violations
- ESLint enforces architecture

---

## References

- [05_architecture_mode_guidelines.md](05_architecture_mode_guidelines.md) - Hexagonal Architecture
- [06_nestjs_guidelines.md](06_nestjs_guidelines.md) - NestJS Best Practices
- [08_cqrs_events_sagas.md](08_cqrs_events_sagas.md) - CQRS Pattern
- [09_api_first_libraries.md](09_api_first_libraries.md) - API Design
- [18_documentation_compodoc.md](18_documentation_compodoc.md) - Documentation

# GraphQL DataLoaders Pattern

## CRITICAL RULE

**ALL GraphQL field resolvers that fetch related entities MUST use DataLoaders to prevent N+1 query problems.**

---

## What is the N+1 Problem?

When resolving GraphQL queries with nested fields, without DataLoaders you get:

```graphql
query {
  userMemberships {
    organizations {      # 1 query to get memberships
      organization {     # N queries (one per organization!)
        id
        name
      }
    }
  }
}
```

**Without DataLoader:**
- 1 query to get memberships
- N queries to get each organization (one per membership)
- **Total: 1 + N queries** ❌

**With DataLoader:**
- 1 query to get memberships
- 1 batched query to get all organizations at once
- **Total: 2 queries** ✅

---

## DataLoader Import (CRITICAL)

**ALWAYS use namespace import for DataLoader:**

```typescript
// ✅ CORRECT - Namespace import
import * as DataLoader from 'dataloader';

// ❌ WRONG - Default import (causes "is not a constructor" error)
import DataLoader from 'dataloader';
```

**Why?** TypeScript/CommonJS interop issues cause the default import to fail at runtime.

---

## Implementation Pattern

### 1. Create DataLoader Service (REQUEST-scoped)

```typescript
import { Injectable, Scope } from '@nestjs/common';
import * as DataLoader from 'dataloader';
import { PrismaService } from '@app/kpis/shared/infrastructure/database/prisma.service';

/**
 * DataLoader service to prevent N+1 queries in GraphQL resolvers.
 * Scoped to REQUEST so each request gets its own loader instances.
 */
@Injectable({ scope: Scope.REQUEST })
export class EntityLoadersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Batch load organizations by IDs
   */
  readonly organizationLoader = new DataLoader<string, any>(
    async (ids: readonly string[]) => {
      // Fetch all organizations in a single query
      const organizations = await this.prisma.organization.findMany({
        where: { id: { in: [...ids] } },
      });

      // Map results in the same order as input IDs
      const orgMap = new Map(organizations.map((org) => [org.id, org]));
      return ids.map((id) => orgMap.get(id) || null);
    },
  );

  /**
   * Batch load companies by IDs
   */
  readonly companyLoader = new DataLoader<string, any>(
    async (ids: readonly string[]) => {
      const companies = await this.prisma.company.findMany({
        where: { id: { in: [...ids] } },
      });

      const companyMap = new Map(companies.map((c) => [c.id, c]));
      return ids.map((id) => companyMap.get(id) || null);
    },
  );

  /**
   * Batch load departments by IDs
   */
  readonly departmentLoader = new DataLoader<string, any>(
    async (ids: readonly string[]) => {
      const departments = await this.prisma.department.findMany({
        where: { id: { in: [...ids] } },
      });

      const deptMap = new Map(departments.map((d) => [d.id, d]));
      return ids.map((id) => deptMap.get(id) || null);
    },
  );

  /**
   * Batch load teams by IDs
   */
  readonly teamLoader = new DataLoader<string, any>(
    async (ids: readonly string[]) => {
      const teams = await this.prisma.team.findMany({
        where: { id: { in: [...ids] } },
      });

      const teamMap = new Map(teams.map((t) => [t.id, t]));
      return ids.map((id) => teamMap.get(id) || null);
    },
  );
}
```

### 2. Use DataLoader in Field Resolvers

```typescript
import { Resolver, ResolveField, Parent } from '@nestjs/graphql';
import { EntityLoadersService } from '../loaders/entity.loaders';

@Resolver(() => OrganizationMembershipDto)
export class OrganizationMembershipResolver {
  constructor(private readonly loaders: EntityLoadersService) {}

  @ResolveField(() => OrganizationDto)
  async organization(
    @Parent() membership: OrganizationMembershipDto,
  ): Promise<OrganizationDto> {
    // Use DataLoader to batch-load organization
    const org = await this.loaders.organizationLoader.load(
      membership.organizationId,
    );

    if (!org) {
      throw new Error('Organization not found');
    }

    return { id: org.id, name: org.name };
  }
}

@Resolver(() => CompanyMembershipDto)
export class CompanyMembershipResolver {
  constructor(private readonly loaders: EntityLoadersService) {}

  @ResolveField(() => CompanyDto)
  async company(
    @Parent() membership: CompanyMembershipDto,
  ): Promise<CompanyDto> {
    // Use DataLoader to batch-load company
    const company = await this.loaders.companyLoader.load(membership.companyId);

    if (!company) {
      throw new Error('Company not found');
    }

    return {
      id: company.id,
      name: company.name,
      organizationId: company.organizationId,
    };
  }

  @ResolveField(() => DepartmentDto, { nullable: true })
  async department(
    @Parent() membership: CompanyMembershipDto,
  ): Promise<DepartmentDto | null> {
    if (!membership.departmentId) {
      return null;
    }

    const dept = await this.loaders.departmentLoader.load(
      membership.departmentId,
    );

    if (!dept) {
      return null;
    }

    return { id: dept.id, name: dept.name, companyId: dept.companyId };
  }

  @ResolveField(() => TeamDto, { nullable: true })
  async team(
    @Parent() membership: CompanyMembershipDto,
  ): Promise<TeamDto | null> {
    if (!membership.teamId) {
      return null;
    }

    const team = await this.loaders.teamLoader.load(membership.teamId);

    if (!team) {
      return null;
    }

    return { id: team.id, name: team.name, departmentId: team.departmentId };
  }
}
```

### 3. Register DataLoader Service in Module

```typescript
import { Module } from '@nestjs/common';
import { EntityLoadersService } from './loaders/entity.loaders';
import { OrganizationMembershipResolver } from './resolvers/membership.resolver';

@Module({
  providers: [
    EntityLoadersService,
    OrganizationMembershipResolver,
    CompanyMembershipResolver,
    // ... other resolvers
  ],
})
export class IamModule {}
```

---

## Key Principles

### 1. REQUEST Scope is CRITICAL

```typescript
@Injectable({ scope: Scope.REQUEST })
export class EntityLoadersService {
  // Each GraphQL request gets its own loader instances
  // This ensures batching works correctly and caching is per-request
}
```

**Why REQUEST scope?**
- ✅ Each request gets fresh loaders (no stale cache)
- ✅ Batching works within the request
- ✅ Memory is freed after request completes

### 2. Preserve Order in Batch Function

```typescript
readonly organizationLoader = new DataLoader<string, any>(
  async (ids: readonly string[]) => {
    const organizations = await this.prisma.organization.findMany({
      where: { id: { in: [...ids] } },
    });

    // CRITICAL: Return results in the SAME ORDER as input IDs
    const orgMap = new Map(organizations.map((org) => [org.id, org]));
    return ids.map((id) => orgMap.get(id) || null);
    //     ^^^ Must match input order!
  },
);
```

**Why preserve order?**
- DataLoader expects results in the same order as input IDs
- If order doesn't match, wrong data will be returned

### 3. Handle Not Found Cases

```typescript
// Return null for missing entities
return ids.map((id) => orgMap.get(id) || null);
//                                      ^^^ null if not found

// Then check in resolver
const org = await this.loaders.organizationLoader.load(id);
if (!org) {
  throw new Error('Organization not found');
}
```

---

## Performance Benefits

### Before DataLoader (N+1 Problem)

```
Query: Get 100 memberships with organizations

Queries executed:
1. SELECT * FROM organization_memberships (1 query)
2. SELECT * FROM organizations WHERE id = '1' (1 query)
3. SELECT * FROM organizations WHERE id = '2' (1 query)
4. SELECT * FROM organizations WHERE id = '3' (1 query)
... (97 more queries)

Total: 101 queries ❌
```

### After DataLoader (Batched)

```
Query: Get 100 memberships with organizations

Queries executed:
1. SELECT * FROM organization_memberships (1 query)
2. SELECT * FROM organizations WHERE id IN ('1','2','3',...,'100') (1 query)

Total: 2 queries ✅
```

**Performance improvement: 50x fewer queries!**

---

## Common Patterns

### Pattern 1: Nullable Relations

```typescript
@ResolveField(() => DepartmentDto, { nullable: true })
async department(
  @Parent() membership: CompanyMembershipDto,
): Promise<DepartmentDto | null> {
  // Check if relation exists
  if (!membership.departmentId) {
    return null;
  }

  const dept = await this.loaders.departmentLoader.load(membership.departmentId);
  return dept ? { id: dept.id, name: dept.name } : null;
}
```

### Pattern 2: Multiple Loaders in One Resolver

```typescript
@Resolver(() => CompanyDto)
export class CompanyResolver {
  constructor(private readonly loaders: EntityLoadersService) {}

  @ResolveField(() => OrganizationDto)
  async organization(@Parent() company: CompanyDto) {
    return this.loaders.organizationLoader.load(company.organizationId);
  }

  @ResolveField(() => [DepartmentDto])
  async departments(@Parent() company: CompanyDto) {
    // For one-to-many, you might need a different approach
    // DataLoader is best for one-to-one or many-to-one
    const departments = await this.prisma.department.findMany({
      where: { companyId: company.id },
    });
    return departments;
  }
}
```

### Pattern 3: Custom Cache Key

```typescript
// For composite keys
readonly userCompanyLoader = new DataLoader<string, any>(
  async (keys: readonly string[]) => {
    // keys are like "userId:companyId"
    const pairs = keys.map(k => {
      const [userId, companyId] = k.split(':');
      return { userId, companyId };
    });

    const memberships = await this.prisma.companyMembership.findMany({
      where: {
        OR: pairs.map(p => ({ userId: p.userId, companyId: p.companyId })),
      },
    });

    const map = new Map(
      memberships.map(m => [`${m.userId}:${m.companyId}`, m])
    );
    return keys.map(k => map.get(k) || null);
  },
);
```

---

## Testing DataLoaders

```typescript
describe('EntityLoadersService', () => {
  let service: EntityLoadersService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [EntityLoadersService, PrismaService],
    }).compile();

    service = module.get(EntityLoadersService);
    prisma = module.get(PrismaService);
  });

  it('should batch load organizations', async () => {
    const spy = jest.spyOn(prisma.organization, 'findMany');

    // Load 3 organizations
    const [org1, org2, org3] = await Promise.all([
      service.organizationLoader.load('id1'),
      service.organizationLoader.load('id2'),
      service.organizationLoader.load('id3'),
    ]);

    // Should only call findMany ONCE (batched)
    expect(spy).toHaveBeenCalledTimes(1);
    expect(spy).toHaveBeenCalledWith({
      where: { id: { in: ['id1', 'id2', 'id3'] } },
    });
  });

  it('should cache results within request', async () => {
    const spy = jest.spyOn(prisma.organization, 'findMany');

    // Load same organization twice
    await service.organizationLoader.load('id1');
    await service.organizationLoader.load('id1');

    // Should only query once (cached)
    expect(spy).toHaveBeenCalledTimes(1);
  });
});
```

---

## NEVER

- ❌ Use default import for DataLoader (`import DataLoader from 'dataloader'`)
- ❌ Make DataLoader service DEFAULT or SINGLETON scoped
- ❌ Return results in different order than input IDs
- ❌ Use DataLoader for one-to-many relations (use direct query instead)
- ❌ Forget to handle null cases

---

## ALWAYS

- ✅ Use namespace import (`import * as DataLoader from 'dataloader'`)
- ✅ Make DataLoader service REQUEST-scoped
- ✅ Preserve order in batch function
- ✅ Use DataLoader for one-to-one and many-to-one relations
- ✅ Handle not found cases gracefully

---

## Benefits

- ✅ **Performance**: Reduces N+1 queries to 2 queries
- ✅ **Automatic batching**: DataLoader batches requests automatically
- ✅ **Per-request caching**: Avoids duplicate queries in same request
- ✅ **Simplicity**: Resolvers look like simple async functions
- ✅ **Type safety**: Full TypeScript support

# Database Audit Pattern

## CRITICAL RULE

**ALL database records MUST have `createdBy`, `updatedBy`, and `deletedBy` fields.**

---

## Prisma Schema

All models must include:

```prisma
model Organization {
  id        String    @id @default(uuid())
  name      String    @unique
  deletedAt DateTime? @map("deleted_at")  // Soft delete
  deletedBy String?   @map("deleted_by")  // User ID who deleted this
  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @updatedAt @map("updated_at")
  
  // 👇 MANDATORY AUDIT FIELDS
  createdBy String?   @map("created_by")  // User ID who created this
  updatedBy String?   @map("updated_by")  // User ID who last updated this
  
  @@map("organizations")
}
```

---

## AuditContextService

**REQUEST-scoped**: Captures the authenticated user's userId for each request.

```typescript
import { Injectable, Scope } from '@nestjs/common';

@Injectable({ scope: Scope.REQUEST })
export class AuditContextService {
  private userId: string | null = null;

  setUserId(userId: string): void {
    this.userId = userId;
  }

  getUserId(): string | null {
    return this.userId;
  }

  getCreateAuditFields(): { createdBy: string | null; updatedBy: string | null } {
    return {
      createdBy: this.userId,
      updatedBy: this.userId,
    };
  }

  getUpdateAuditFields(): { updatedBy: string | null } {
    return {
      updatedBy: this.userId,
    };
  }
}
```

---

## AuthGuard

Must call `auditContext.setUserId(user.id)` after authenticating the user:

```typescript
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly auditContext: AuditContextService,
    // ... other services
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // ... authentication ...
    
    const user = await this.commandBus.execute(
      new SyncUserFromAuth0Command(payload.sub, email, name)
    );

    // 👇 INJECT USER ID INTO AUDIT CONTEXT
    this.auditContext.setUserId(user.id);
    
    return true;
  }
}
```

---

## Prisma Repositories

### Inject AuditContextService

```typescript
import { AuditContextService } from '@app/kpis/shared/infrastructure/audit/audit-context.service';

@Injectable()
export class PrismaOrganizationRepository implements OrganizationRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditContext: AuditContextService, // 👈 Inyectar
  ) {}
}
```

### CREATE - Use getCreateAuditFields()

```typescript
async save(organization: Organization): Promise<void> {
  const auditFields = this.auditContext.getCreateAuditFields();

  await this.prisma.organization.upsert({
    where: { id: organization.id },
    create: {
      id: organization.id,
      name: organization.name,
      createdAt: organization.createdAt,
      updatedAt: organization.updatedAt,
      ...auditFields, // 👈 createdBy + updatedBy
    },
    update: {
      name: organization.name,
      updatedAt: organization.updatedAt,
      ...this.auditContext.getUpdateAuditFields(), // 👈 updatedBy
    },
  });
}
```

### UPDATE - Use getUpdateAuditFields()

```typescript
async update(id: string, data: Partial<Organization>): Promise<void> {
  await this.prisma.organization.update({
    where: { id },
    data: {
      ...data,
      ...this.auditContext.getUpdateAuditFields(), // 👈 updatedBy
    },
  });
}
```

### DELETE (Soft Delete) - Use getDeleteAuditFields()

```typescript
async delete(id: string): Promise<void> {
  await this.prisma.organization.update({
    where: { id },
    data: {
      deletedAt: new Date(),
      ...this.auditContext.getDeleteAuditFields(), // 👈 deletedBy
    },
  });
}
```

---

## NEVER

- ❌ Create/update/delete records without audit fields
- ❌ Hardcode `createdBy`/`updatedBy`/`deletedBy` values
- ❌ Forget to inject `AuditContextService` in repositories
- ❌ Perform hard delete without recording who deleted

---

## Benefits

- ✅ **Complete traceability**: Always know who created or modified each record
- ✅ **Automatic auditing**: No manual intervention required
- ✅ **Regulatory compliance**: Facilitates audits and compliance

---

## Important Note

Fields are **nullable** (`String?`) for system operations where there's no authenticated user:
- Database seeds
- Migrations
- Automated jobs/cron
- System operations

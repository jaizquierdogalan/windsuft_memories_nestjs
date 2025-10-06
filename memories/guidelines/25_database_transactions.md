# Database Transactions Pattern

## CRITICAL RULE

**ALL operations that involve multiple database writes MUST use transactions to ensure atomicity.**

---

## When to Use Transactions

Use transactions when:
- ✅ Creating an entity and its related records (e.g., Organization + OrganizationMembership)
- ✅ Updating multiple tables that must stay consistent
- ✅ Deleting an entity and its dependencies
- ✅ Any operation where partial success would leave the database in an inconsistent state

---

## Prisma Transaction Syntax

### Basic Transaction

```typescript
await this.prisma.$transaction(async (tx) => {
  // All operations here are atomic
  await tx.organization.create({ data: {...} });
  await tx.organizationMembership.create({ data: {...} });
  // If any operation fails, ALL are rolled back
});
```

### Transaction with Repository Pattern

```typescript
async execute(command: CreateOrganizationCommand): Promise<string> {
  const organization = Organization.create(command.name);
  const userId = this.auditContext.getUserId();

  // Use transaction to ensure atomicity
  await this.prisma.$transaction(async (tx) => {
    // Save organization (repository uses Prisma internally)
    await this.organizationRepo.save(organization);

    // Create membership using transaction client
    if (userId) {
      await tx.organizationMembership.create({
        data: {
          userId,
          organizationId: organization.id,
          role: 'OWNER',
        },
      });
    }
  });

  return organization.id;
}
```

---

## Real-World Example: Create Organization

**Problem without transaction:**
```typescript
// ❌ BAD - No transaction
await organizationRepo.save(organization);     // ✅ Success
await prisma.organizationMembership.create(); // ❌ Fails
// Result: Orphaned organization in database without owner
```

**Solution with transaction:**
```typescript
// ✅ GOOD - With transaction
await prisma.$transaction(async (tx) => {
  await organizationRepo.save(organization);     // ✅ Success
  await tx.organizationMembership.create(...);   // ❌ Fails
  // Result: AUTOMATIC ROLLBACK - nothing is saved
});
```

---

## Transaction Guarantees (ACID)

### Atomicity
- ✅ All operations succeed together, or all fail together
- ✅ No partial updates

### Consistency
- ✅ Database remains in a valid state
- ✅ All constraints are enforced

### Isolation
- ✅ Concurrent transactions don't interfere
- ✅ Other transactions don't see intermediate states

### Durability
- ✅ Once committed, changes are permanent
- ✅ Survives system crashes

---

## Common Use Cases

### 1. Create Entity with Relationships

```typescript
await prisma.$transaction(async (tx) => {
  const org = await tx.organization.create({ data: {...} });
  await tx.organizationMembership.create({
    data: { userId, organizationId: org.id, role: 'OWNER' }
  });
});
```

### 2. Update Multiple Related Entities

```typescript
await prisma.$transaction(async (tx) => {
  await tx.company.update({ where: { id }, data: {...} });
  await tx.companyMembership.updateMany({
    where: { companyId: id },
    data: { updatedAt: new Date() }
  });
});
```

### 3. Delete with Cascade

```typescript
await prisma.$transaction(async (tx) => {
  await tx.companyMembership.deleteMany({ where: { companyId: id } });
  await tx.department.deleteMany({ where: { companyId: id } });
  await tx.company.delete({ where: { id } });
});
```

### 4. Transfer Ownership

```typescript
await prisma.$transaction(async (tx) => {
  // Remove old owner
  await tx.organizationMembership.update({
    where: { id: oldOwnerId },
    data: { role: 'ADMIN' }
  });
  
  // Set new owner
  await tx.organizationMembership.update({
    where: { id: newOwnerId },
    data: { role: 'OWNER' }
  });
});
```

---

## Advanced: Interactive Transactions

For complex scenarios with conditional logic:

```typescript
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUnique({ where: { id } });
  
  if (user.credits < 100) {
    throw new Error('Insufficient credits');
  }
  
  await tx.user.update({
    where: { id },
    data: { credits: { decrement: 100 } }
  });
  
  await tx.purchase.create({
    data: { userId: id, amount: 100 }
  });
});
```

---

## NEVER

- ❌ Create related records without a transaction
- ❌ Update multiple tables without ensuring atomicity
- ❌ Assume partial success is acceptable
- ❌ Mix transactional and non-transactional operations without careful consideration

---

## Benefits

- ✅ **Data integrity**: Database always in consistent state
- ✅ **Error recovery**: Automatic rollback on failure
- ✅ **Concurrency safety**: Prevents race conditions
- ✅ **Simplified error handling**: No need to manually undo operations

---

## Performance Considerations

- Transactions have overhead - use them when needed, not everywhere
- Keep transactions short and focused
- Avoid long-running operations inside transactions
- Don't make external API calls inside transactions

---

## Testing Transactions

```typescript
describe('CreateOrganizationHandler', () => {
  it('should rollback if membership creation fails', async () => {
    // Mock membership creation to fail
    jest.spyOn(prisma.organizationMembership, 'create')
      .mockRejectedValue(new Error('DB Error'));
    
    await expect(handler.execute(command)).rejects.toThrow();
    
    // Verify organization was NOT created (rollback worked)
    const org = await prisma.organization.findUnique({ 
      where: { id: organization.id } 
    });
    expect(org).toBeNull();
  });
});
```

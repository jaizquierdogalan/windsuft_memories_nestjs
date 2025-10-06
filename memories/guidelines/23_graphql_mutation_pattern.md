# GraphQL Mutation Pattern

## REGLA CRÍTICA

**Las mutations GraphQL siempre devuelven SOLO el ID (String), nunca objetos completos.**

El frontend debe hacer queries GET separadas para obtener los datos completos después de una mutation.

---

## Backend - Mutation devuelve String

```typescript
@Mutation(() => String, { name: 'createOrganization' })
@CheckPermission('iam.organization', 'CREATE')
async createOrganization(@Args('name') name: string): Promise<string> {
  return await this.commandBus.execute(new CreateOrganizationCommand(name));
}
```

## Backend - Handler devuelve String (ID)

```typescript
@CommandHandler(CreateOrganizationCommand)
export class CreateOrganizationHandler
  implements ICommandHandler<CreateOrganizationCommand, string>
{
  async execute(command: CreateOrganizationCommand): Promise<string> {
    const org = Organization.create(command.name);
    await this.repo.save(org);
    return org.id; // Solo el ID
  }
}
```

## Frontend - Mutation solo obtiene ID

```typescript
const result = await apollo.mutate<{ createOrganization: string }>({
  mutation: CREATE_ORGANIZATION,
  variables: { name: 'Acme Corp' }
});

const orgId = result?.data?.createOrganization;
// El frontend gestiona el nombre localmente, ya lo tiene del formulario
```

## Frontend - Query GraphQL

```graphql
# ✅ CORRECTO
mutation CreateOrganization($name: String!) {
  createOrganization(name: $name)  # Solo devuelve String (ID)
}

# ❌ INCORRECTO - No hacer esto
mutation CreateOrganization($name: String!) {
  createOrganization(name: $name) {
    id
    name
    createdAt
  }
}
```

---

## NUNCA

- ❌ `@Mutation(() => OrganizationDto)` - esto viola el patrón
- ❌ Devolver objetos completos desde mutations

---

## Razón

**Separación de responsabilidades**: Mutations mutan, Queries consultan.

---

## Beneficios

- ✅ Cacheo consistente en Apollo Client
- ✅ Evita sobre-fetching en mutations
- ✅ Patrón CQRS puro - Commands devuelven IDs, Queries devuelven objetos
- ✅ Frontend gestiona datos localmente - ya tiene el `name` del formulario

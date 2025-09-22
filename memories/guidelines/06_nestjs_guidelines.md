# NestJS & TypeScript Guidelines

These guidelines complement the generic project rules for teams building services with NestJS and TypeScript. They emphasize clarity, consistency, and clean architecture.

## TypeScript General Guidelines

### Basic Principles
- Use English for all code and documentation.
- Always declare the type of each variable and function (parameters and return value).
  - Avoid using `any`.
  - Create necessary types.
- Use JSDoc to document public classes and methods.
- Don't leave blank lines within a function.
- One export per file.

### Nomenclature
- Use PascalCase for classes.
- Use camelCase for variables, functions, and methods.
- Use kebab-case for file and directory names.
- Use UPPERCASE for environment variables.
  - Avoid magic numbers and define constants.
- Start each function with a verb.
- Use verbs for boolean variables. Example: `isLoading`, `hasError`, `canDelete`, etc.
- Use complete words instead of abbreviations and correct spelling.
  - Except for standard abbreviations like API, URL, etc.
  - Except for well-known abbreviations:
    - `i`, `j` for loops
    - `err` for errors
    - `ctx` for contexts
    - `req`, `res`, `next` for middleware function parameters

### Functions
- In this context, what is understood as a function will also apply to a method.
- Write short functions with a single purpose. Prefer fewer than 20 statements.
- Name functions with a verb and something else.
  - If it returns a boolean, use `isX`/`hasX`/`canX`, etc.
  - If it doesn't return anything, use `executeX`, `saveX`, etc.
- Avoid deep nesting by:
  - Early checks and returns.
  - Extraction to utility functions.
- Use higher-order functions (`map`, `filter`, `reduce`, etc.) to avoid nested loops where appropriate.
  - Use arrow functions for simple functions (≤3 statements).
  - Use named functions for non-simple functions.
- Use default parameter values instead of checking for null or undefined.
- Reduce function parameters using RO-RO (receive object, return object):
  - Use an object to pass multiple parameters.
  - Use an object to return results.
  - Declare necessary types for input arguments and output.
- Keep a single level of abstraction within a function.

### Data
- Don't abuse primitive types; encapsulate data in composite types.
- Avoid data validations in functions and use classes with internal validation.
- Prefer immutability for data.
  - Use `readonly` for data that doesn't change.
  - Use `as const` for literals that don't change.

### Classes
- Follow SOLID principles.
- Prefer composition over inheritance.
- Declare interfaces to define contracts.
- Write small classes with a single purpose.
  - Less than ~200 statements.
  - Fewer than 10 public methods.
  - Fewer than 10 properties.

### Exceptions
- Use exceptions to handle errors you don't expect.
- If you catch an exception, it should be to:
  - Fix an expected problem.
  - Add context.
  - Otherwise, prefer a global handler.

### Testing
- Follow the Arrange-Act-Assert convention for tests.
- Name test variables clearly.
  - Convention: `inputX`, `mockX`, `actualX`, `expectedX`, etc.
- Write unit tests for each public function.
  - Use test doubles to simulate dependencies.
    - Except for third-party dependencies that are not expensive to execute.
- Write acceptance/integration tests for each module.
  - Follow the Given-When-Then convention.

## Specific to NestJS

### Basic Principles
- Use modular architecture.
- Encapsulate the API in modules:
  - One module per main domain/route.
  - One controller for its primary route; additional controllers for secondary routes.
  - A `models` (or `dto`) folder with data types:
    - DTOs validated with `class-validator` for inputs.
    - Declare simple types for outputs.
  - A `services` module with business logic and persistence.
    - Entities with an ORM (e.g., Mongoose/TypeORM/Prisma) for data persistence.
    - One service per entity (or cohesive aggregate root).
- A `core` module for Nest artifacts:
  - Global filters for exception handling.
  - Global middlewares for request management.
  - Guards for permission/authorization management.
  - Interceptors for cross-cutting concerns (logging, metrics, caching).
- A `shared` module for services shared between modules:
  - Utilities
  - Shared business logic

### Testing
- Use the standard Jest framework for testing.
- Write tests for each controller and service.
- Write end-to-end tests for each API module.
- Optionally, add an `admin/test` method to each controller as a smoke test (guard appropriately, do not expose in production environments).

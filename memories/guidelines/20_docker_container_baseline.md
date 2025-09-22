# Docker Containerization Baseline

## Principles (Executive Summary)
- Multi-stage builds: compile in a toolchain image, run in a minimal runtime (distroless preferred; Alpine if you need a shell).
- Production-only dependencies: `npm ci --omit=dev` in the final stage.
- PID 1 with init: use `--init` (Docker/Compose) or `tini`/`dumb-init`.
- Clean shutdown: `STOPSIGNAL SIGTERM`, `app.enableShutdownHooks()`, SIGTERM/SIGINT handlers that stop HTTP and close DB/queues.
- Health & readiness: `/health` and `/ready` endpoints plus `HEALTHCHECK`.
- Minimal images: no build toolchains in runtime.
- Security: non-root user, read-only FS, `tmpfs` for `/tmp`, drop capabilities, default seccomp.
- Logs: stdout/stderr (JSON) for the orchestrator.
- Resources: CPU/mem limits/requests, `ulimits nofile`, optional `NODE_OPTIONS=--max-old-space-size=...`.
- Determinism: `.dockerignore`, pinned Node/PNPM/NPM, BuildKit caches.

## Graceful Shutdown (NestJS/Node)
```ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.enableShutdownHooks();
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();

const shutdown = async (signal: string) => {
  try {
    if ((globalThis as any).otelSDK?.shutdown) {
      await (globalThis as any).otelSDK.shutdown();
    }
    // const newrelic = require('newrelic');
    // await new Promise(res => newrelic.shutdown({ collectPendingData: true }, res));
  } catch (e) {
  } finally {
    process.exit(0);
  }
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));
```

## Dockerfile — Option A (distroless, production-minimal)
Place at project root as `Dockerfile`:
```dockerfile
# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=20.15.1

########################
# 1) Builder
FROM node:${NODE_VERSION}-bookworm-slim AS builder
WORKDIR /app

# Deterministic installs with cache
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY tsconfig*.json ./
COPY src ./src

# Build
RUN npm run build

# Prune dev deps
RUN npm prune --omit=dev

########################
# 2) Runner (distroless)
FROM gcr.io/distroless/nodejs20-debian12:nonroot AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Minimal artifacts
COPY --chown=nonroot:nonroot --from=builder /app/node_modules ./node_modules
COPY --chown=nonroot:nonroot --from=builder /app/dist ./dist
COPY --chown=nonroot:nonroot --from=builder /app/package.json ./

# Clean shutdown
STOPSIGNAL SIGTERM

EXPOSE 3000
# Start application (no shell in distroless)
CMD ["dist/main.js"]
```

## Dockerfile — Option B (Alpine + tini, debuggable)
Place at project root as `Dockerfile.alpine`:
```dockerfile
# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=20.15.1

########################
# 1) Builder
FROM node:${NODE_VERSION}-alpine AS builder
WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY tsconfig*.json ./
COPY src ./src

RUN npm run build
RUN npm prune --omit=dev

########################
# 2) Runner
FROM node:${NODE_VERSION}-alpine AS runner
WORKDIR /app

# tini as init (PID 1)
RUN apk add --no-cache tini curl
ENTRYPOINT ["/sbin/tini","--"]

ENV NODE_ENV=production
ENV PORT=3000

# Non-root
RUN addgroup -S nodegrp && adduser -S node -G nodegrp
USER node

COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist
COPY --chown=node:node --from=builder /app/package.json ./

STOPSIGNAL SIGTERM
EXPOSE 3000

HEALTHCHECK --interval=20s --timeout=3s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3000/health || exit 1

CMD ["node","dist/main.js"]
```

## Docker Compose (optional for dev)
Place at project root as `docker-compose.yml`:
```yaml
version: "3.9"
services:
  api:
    build:
      context: .
      target: runner
      args:
        NODE_VERSION: "20.15.1"
    image: org/service:latest
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      PORT: "3000"
    command: ["node","dist/main.js"]
    init: true
    restart: unless-stopped
    stop_grace_period: 30s
    ulimits:
      nofile:
        soft: 65535
        hard: 65535
    read_only: true
    tmpfs:
      - /tmp:size=64m
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

## .dockerignore (example)
Place at project root as `.dockerignore`:
```gitignore
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-store

.git
.gitignore

coverage
logs
*.log

# Local build outputs
/dist
/.cache
/.turbo

# Docs (not needed for runtime)
/docs

# Env files
.env
.env.*
```

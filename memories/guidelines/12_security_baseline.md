# Security Baseline (NestJS)

References:
- Helmet: https://docs.nestjs.com/security/helmet
- CORS: https://docs.nestjs.com/security/cors
- CSRF: https://docs.nestjs.com/security/csrf

## Minimum Requirements
- Enable Helmet with sane defaults; configure per environment if needed.
- Enable CORS with allowed origins/methods/headers configured.
- Enable CSRF protection for state-changing requests in browser-based apps.
- Validate all inputs (global validation pipe) and sanitize outputs.
- Rate limiting and brute-force protection (edge or app-level) where appropriate.
- Secure cookies and headers; disable x-powered-by; enforce HTTPS in production behind a proxy.

## Keys & Secrets
- Load secrets from environment/secret stores; do not commit.
- Rotate keys regularly; use per-environment segregation.

# STRUCTURE

  This is a polyglot microservices monorepo with the following architecture:

  Directory Layout

  saaas-product/
  ├── frontend/          # Next.js 16 monorepo (pnpm + Turbo)
  ├── go-services/       # Go microservices (workspaces)
  ├── php-services/      # Symfony 8 with FrankenPHP
  ├── rust-services/     # Tokio-based async services
  ├── shared-schemas/    # Protocol Buffer definitions (Buf)
  ├── docker/            # Multi-stage Dockerfiles
  ├── .github/           # CI/CD pipelines
  └── docs/              # Documentation

  Technology Stack
  ┌────────────────┬───────────────────────────────────────────────────┐
  │     Layer      │                   Technologies                    │
  ├────────────────┼───────────────────────────────────────────────────┤
  │ Frontend       │ Next.js 16, React 19, Tailwind CSS 4, pnpm, Turbo │
  ├────────────────┼───────────────────────────────────────────────────┤
  │ PHP Backend    │ Symfony 8.0, FrankenPHP, PHP 8.4+                 │
  ├────────────────┼───────────────────────────────────────────────────┤
  │ Go Backend     │ Go 1.24.3, stdlib HTTP                            │
  ├────────────────┼───────────────────────────────────────────────────┤
  │ Rust Backend   │ Tokio, Tonic, Prost                               │
  ├────────────────┼───────────────────────────────────────────────────┤
  │ Database       │ PostgreSQL 18                                     │
  ├────────────────┼───────────────────────────────────────────────────┤
  │ Infrastructure │ Docker Compose, GitHub Actions, GHCR              │
  └────────────────┴───────────────────────────────────────────────────┘
  Service Routing (via API Gateway on :8080)

  - /services/php-apis/* → PHP (8081)
  - /services/go-apis/* → Go (8083)
  - /services/rust-apis/* → Rust (8082)
  - /* → Frontend (3000)

  Key Patterns

  - Shared Schemas: Protocol Buffers with Buf for cross-language type safety
  - Layered Architecture: DDD approach in PHP (domain/application/infrastructure)
  - Workspace Management: Each language uses its native monorepo tooling
  - Containerization: Multi-stage builds, Alpine images, non-root execution

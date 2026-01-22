# SaaS Product Monorepo

A polyglot microservices monorepo demonstrating a modern cloud-native architecture with multiple backend services, API gateway, and frontend applications.

## Architecture Overview

```
                    ┌──────────────────┐
                    │   Frontend       │
                    │   (Next.js)      │
                    │   Port: 3000     │
                    └──────────────────┘
                             │
┌────────────────────────────┼────────────────────────────┐
│                  API Gateway (Go) - Port: 8080          │
│                                                          │
│  Routes:                                                 │
│    /services/php-apis/*  → PHP Backend                  │
│    /services/go-apis/*   → Go Backend                   │
│    /services/rust-apis/* → Rust Backend                 │
│    /health               → Gateway Health               │
│    /*                    → Frontend                     │
└──────┬──────────────┬──────────────┬────────────────────┘
       │              │              │
  ┌────▼─────┐   ┌───▼────┐    ┌───▼─────┐
  │ PHP API  │   │ Go API │    │Rust API │
  │Port: 8081│   │Port:   │    │Port:    │
  │(Symfony) │   │  8083  │    │  8082   │
  └────┬─────┘   └────────┘    └─────────┘
       │
  ┌────▼─────┐
  │PostgreSQL│
  │Port: 5432│
  └──────────┘
```

## Tech Stack

### Backend Services
- **PHP Service**: Symfony 8.0 with FrankenPHP
- **Go Service**: Native Go HTTP server
- **Rust Service**: Tokio async runtime
- **API Gateway**: Go reverse proxy

### Frontend
- **Web App**: Next.js 16 (App Router)
- **Admin App**: Placeholder for admin interface

### Infrastructure
- **Database**: PostgreSQL 18
- **Container Runtime**: Docker with Docker Compose
- **API Schemas**: Protocol Buffers (Buf)

## Project Structure

```
.
├── docker/                        # Docker configuration
│   ├── docker-compose.yml        # Production/staging orchestration
│   ├── docker-compose.dev.yml    # Development with hot-reload
│   ├── Dockerfile.php-api        # PHP production container
│   ├── Dockerfile.php-api.dev    # PHP dev with Xdebug
│   ├── Dockerfile.go-api         # Go production container
│   ├── Dockerfile.go-api.dev     # Go dev with Air + Delve
│   ├── Dockerfile.go-gateway     # Gateway production container
│   ├── Dockerfile.go-gateway.dev # Gateway dev with Air + Delve
│   ├── Dockerfile.rust-api       # Rust production container
│   ├── Dockerfile.rust-api.dev   # Rust dev with cargo-watch
│   ├── Dockerfile.frontend       # Frontend production container
│   └── Dockerfile.frontend.dev   # Frontend dev server
│
├── go-services/                  # Go microservices
│   ├── services/
│   │   ├── api-service/         # Go API service
│   │   └── api-gateway/         # API Gateway
│   ├── libs/                    # Shared Go libraries
│   │   └── proto/               # Generated protobuf code
│   ├── .air.toml                # Air hot-reload config (API)
│   └── .air.gateway.toml        # Air hot-reload config (Gateway)
│
├── rust-services/               # Rust microservices
│   ├── services/
│   │   └── api-service/        # Rust API service
│   └── libs/                   # Shared Rust libraries
│       └── shared-utils/       # Common utilities
│
├── php-services/                # PHP microservices
│   ├── apps/
│   │   └── main-api/           # Symfony API application
│   ├── packages/               # Shared PHP packages
│   │   ├── api-contracts/      # Protobuf generated code
│   │   ├── application/        # Application layer
│   │   ├── domain/             # Domain layer
│   │   └── infrastructure/     # Infrastructure layer
│   └── tests/                  # PHP tests
│
├── frontend/                   # Frontend applications
│   ├── apps/
│   │   ├── web/               # Next.js web application
│   │   └── admin/             # Admin application
│   └── packages/              # Shared frontend packages
│
├── shared-schemas/            # Protocol Buffers schemas
│   └── buf.gen.yaml          # Buf code generation config
│
├── scripts/                   # Automation scripts
│   └── railway-init.sh       # Railway infrastructure setup
│
├── docs/                      # Documentation
│   ├── LOCAL_DEVELOPMENT.md  # Local dev setup guide
│   └── RAILWAY_DEPLOYMENT.md # Railway deployment guide
│
├── .vscode/                   # VS Code configuration
│   └── launch.json           # Debug configurations
│
└── Makefile                  # Build automation
```

## Services & Ports

| Service       | Port | Technology      | Purpose                          |
|---------------|------|-----------------|----------------------------------|
| API Gateway   | 8080 | Go              | Reverse proxy & routing          |
| PHP API       | 8081 | Symfony 8       | Main business logic API          |
| Rust API      | 8082 | Tokio           | High-performance service         |
| Go API        | 8083 | Go stdlib       | Lightweight microservice         |
| Frontend      | 3000 | Next.js 16      | User-facing web application      |
| PostgreSQL    | 5432 | PostgreSQL 18   | Primary database                 |

## API Endpoints

### Health Checks
All services expose a standardized health check endpoint:

```bash
# Direct service access
GET http://localhost:8081/health  # PHP API
GET http://localhost:8082/health  # Rust API
GET http://localhost:8083/health  # Go API
GET http://localhost:3000/health  # Frontend

# Via API Gateway
GET http://localhost:8080/services/php-apis/health
GET http://localhost:8080/services/rust-apis/health
GET http://localhost:8080/services/go-apis/health
GET http://localhost:8080/health  # Gateway health
```

**Response Format:**
```json
{
  "status": "ok",
  "service": "service-name"
}
```

## Getting Started

### Prerequisites
- Docker & Docker Compose
- Make (optional, for shortcuts)

### Quick Start

1. **Build all services:**
   ```bash
   make docker-build
   # or
   docker compose -f docker/docker-compose.yml build
   ```

2. **Start all services:**
   ```bash
   make docker-up
   # or
   docker compose -f docker/docker-compose.yml up -d
   ```

3. **Check service status:**
   ```bash
   make docker-ps
   # or
   docker compose -f docker/docker-compose.yml ps
   ```

4. **Test the services:**
   ```bash
   # Test via gateway
   curl http://localhost:8080/services/php-apis/health
   curl http://localhost:8080/services/go-apis/health
   curl http://localhost:8080/services/rust-apis/health
   
   # Access frontend
   open http://localhost:3000
   ```

5. **Stop all services:**
   ```bash
   make docker-down
   # or
   docker compose -f docker/docker-compose.yml down
   ```

## Development

### Local Development with Hot-Reload

For local development with hot-reload and debugging, use the development Docker Compose setup:

```bash
# Build development containers
make dev-build

# Start development environment
make dev-up

# View logs
make dev-logs

# Stop
make dev-down
```

**Development features:**
- Hot-reload for all services (Air for Go, cargo-watch for Rust, Symfony CLI for PHP, Next.js HMR)
- Xdebug for PHP debugging (port 9003)
- Delve for Go debugging (ports 2345, 2346)
- VS Code debug configurations included

See **[docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md)** for the complete local development guide.

### Native Development (without Docker)

#### PHP
```bash
cd php-services
composer install
vendor/bin/phpunit
```

#### Go
```bash
cd go-services
go mod download
go test ./...
```

#### Rust
```bash
cd rust-services
cargo build
cargo test
```

#### Frontend
```bash
cd frontend
pnpm install
pnpm --filter web dev
```

### Code Generation (Protocol Buffers)

Generate code from protobuf schemas:
```bash
cd shared-schemas
buf generate
```

This generates:
- Go code → `go-services/libs/proto/`
- PHP code → `php-services/packages/api-contracts/src/`
- Rust code → `rust-services/libs/proto/src/`

## Key Features

### API Gateway Routing
The Go gateway provides intelligent routing:
- `/services/php-apis/*` → Routes to PHP backend
- `/services/go-apis/*` → Routes to Go backend
- `/services/rust-apis/*` → Routes to Rust backend
- `/*` → Routes to frontend (catch-all)

### Monorepo Benefits
- **Shared Schema Definitions**: Protocol Buffers ensure type safety across services
- **Unified CI/CD**: Single pipeline for all services
- **Dependency Management**: Centralized version control
- **Code Sharing**: Shared libraries and utilities

### Container Architecture
- **Multi-stage builds**: Optimized image sizes
- **Alpine-based images**: Minimal attack surface
- **Health checks**: Built-in service health monitoring
- **Environment configuration**: 12-factor app compliance

## Deployment

### Railway Deployment

This project is configured for deployment to Railway with automated CI/CD:

```bash
# Run the automated setup script
make railway-init
```

This will guide you through:
1. Railway CLI installation check
2. Authentication
3. Project creation
4. Database setup
5. Service creation with environment variables
6. GitHub secret configuration

**Deployment triggers:**
- **Production**: Auto-deploys on push to `main` branch
- **Staging**: Auto-deploys on push to `staging` branch
- **PR Previews**: Automatically created for pull requests

**GitHub Actions workflows:**
- `deploy-railway.yml` - Full deployment pipeline with environment management
- `build-images.yml` - Docker image builds to GHCR

See **[docs/RAILWAY_DEPLOYMENT.md](docs/RAILWAY_DEPLOYMENT.md)** for the complete deployment guide.

## Production Considerations

### Security
- All services run as non-root users
- Minimal container images (Alpine Linux)
- Environment-based configuration
- Database credentials via environment variables

### Scalability
- Stateless services for horizontal scaling
- Database connection pooling
- Async I/O in Rust service
- Reverse proxy load distribution

### Monitoring
- Standardized health check endpoints
- Structured logging (where implemented)
- Container resource limits (configurable)

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check if ports are in use
   lsof -i :8080
   lsof -i :8081
   ```

2. **Database connection issues:**
   ```bash
   # Check PostgreSQL logs (production)
   docker logs saaas-product-postgres-1

   # Check PostgreSQL logs (development)
   docker compose -f docker/docker-compose.dev.yml logs postgres
   ```

3. **Service not responding:**
   ```bash
   # Production containers
   docker logs saaas-product-php-api-1
   docker logs saaas-product-go-api-1
   docker logs saaas-product-rust-api-1

   # Development containers
   make dev-logs-php
   make dev-logs-go
   make dev-logs-rust
   ```

4. **Rebuild specific service:**
   ```bash
   # Production
   docker compose -f docker/docker-compose.yml build php-api
   docker compose -f docker/docker-compose.yml up -d php-api

   # Development
   docker compose -f docker/docker-compose.dev.yml build php-api
   docker compose -f docker/docker-compose.dev.yml up -d php-api
   ```

5. **Reset development environment:**
   ```bash
   make dev-down
   docker volume rm saaas-dev_postgres_data saaas-dev_redis_data
   make dev-build
   make dev-up
   ```

## License

Proprietary

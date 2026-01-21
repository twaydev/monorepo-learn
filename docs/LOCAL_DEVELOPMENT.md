# Local Development Guide

This guide covers setting up a local development environment with hot-reload and debugging capabilities for all services.

## Overview

The development environment uses Docker Compose with specialized development containers that include:
- **Hot-reload** for instant code changes
- **Debug support** with IDE integration
- **Volume mounts** for live code editing
- **Development tools** pre-installed

## Development Stack

| Service | Hot-Reload Tool | Debug Tool | Ports |
|---------|----------------|------------|-------|
| PHP/Symfony | Symfony CLI | Xdebug 3 | 8081 (app), 9003 (debug) |
| Go API | Air | Delve | 8083 (app), 2345 (debug) |
| Go Gateway | Air | Delve | 8080 (app), 2346 (debug) |
| Rust API | cargo-watch | - | 8082 |
| Frontend | Next.js HMR | Chrome DevTools | 3000 |
| PostgreSQL | - | - | 5432 |
| Redis | - | - | 6379 |

## Quick Start

### 1. Build Development Containers

```bash
make dev-build
```

This builds all development containers with hot-reload tools installed.

### 2. Start Development Environment

```bash
make dev-up
```

### 3. Verify Services

```bash
# Check container status
make dev-ps

# Test health endpoints
curl http://localhost:8080/health                      # Gateway
curl http://localhost:8080/services/php-apis/health    # PHP API
curl http://localhost:8080/services/go-apis/health     # Go API
curl http://localhost:8080/services/rust-apis/health   # Rust API
curl http://localhost:3000/health                      # Frontend
```

### 4. View Logs

```bash
# All services
make dev-logs

# Specific services
make dev-logs-php
make dev-logs-go
make dev-logs-rust
make dev-logs-frontend
```

### 5. Stop Environment

```bash
make dev-down
```

## Service URLs

| Service | URL | Direct Access |
|---------|-----|---------------|
| Frontend | http://localhost:3000 | Next.js dev server |
| API Gateway | http://localhost:8080 | Routes to all backends |
| PHP API | http://localhost:8081 | Symfony dev server |
| Go API | http://localhost:8083 | Air hot-reload |
| Rust API | http://localhost:8082 | cargo-watch |
| PostgreSQL | localhost:5432 | Database |
| Redis | localhost:6379 | Cache |

## Hot-Reload Behavior

### PHP (Symfony)
- Edit files in `php-services/`
- Symfony CLI automatically detects changes
- No manual restart required

### Go Services
- Edit files in `go-services/`
- Air watches for `.go` file changes
- Rebuilds and restarts in ~1 second

### Rust Service
- Edit files in `rust-services/`
- cargo-watch detects changes
- Rebuilds incrementally

### Frontend (Next.js)
- Edit files in `frontend/`
- Next.js HMR updates browser instantly
- No page refresh needed for most changes

## Debugging

### VS Code Configuration

The project includes VS Code debug configurations in `.vscode/launch.json`:

#### PHP Debugging (Xdebug)
1. Install the PHP Debug extension
2. Set breakpoints in PHP code
3. Start the "PHP: Xdebug (Docker)" configuration
4. Make a request to the PHP API
5. Debugger will pause at breakpoints

#### Go Debugging (Delve)
1. Install the Go extension
2. Set breakpoints in Go code
3. Start "Go API: Attach (Docker)" or "Go Gateway: Attach (Docker)"
4. Connect to the remote debugger

#### Frontend Debugging
1. Use "Next.js: Chrome" configuration
2. Or use browser DevTools directly

### Debug Ports

| Service | Debug Port | Protocol |
|---------|-----------|----------|
| PHP API | 9003 | Xdebug |
| Go API | 2345 | Delve |
| Go Gateway | 2346 | Delve |

## Development Commands

### Makefile Targets

```bash
# Start/Stop
make dev-up              # Start all services
make dev-down            # Stop all services

# Build
make dev-build           # Build all dev containers

# Logs
make dev-logs            # Follow all logs
make dev-logs-php        # PHP service logs
make dev-logs-go         # Go services logs
make dev-logs-rust       # Rust service logs
make dev-logs-frontend   # Frontend logs

# Status
make dev-ps              # Show container status

# Restart specific service
make dev-restart-php-api
make dev-restart-go-api
make dev-restart-frontend
```

## Configuration Files

### Docker Compose
- **Development**: `docker/docker-compose.dev.yml`
- **Production/Staging**: `docker/docker-compose.yml`

### Development Dockerfiles
| File | Purpose |
|------|---------|
| `docker/Dockerfile.php-api.dev` | PHP with Xdebug + Symfony CLI |
| `docker/Dockerfile.go-api.dev` | Go with Air + Delve |
| `docker/Dockerfile.go-gateway.dev` | Gateway with Air + Delve |
| `docker/Dockerfile.rust-api.dev` | Rust with cargo-watch |
| `docker/Dockerfile.frontend.dev` | Next.js dev server |

### Hot-Reload Configuration
| File | Purpose |
|------|---------|
| `go-services/.air.toml` | Air config for Go API |
| `go-services/.air.gateway.toml` | Air config for Gateway |

## Database Access

### Connect to PostgreSQL

```bash
# Via Docker
docker exec -it saaas-dev-postgres-1 psql -U postgres -d myapp

# Via local client
psql -h localhost -p 5432 -U postgres -d myapp
# Password: postgres
```

### Connection String
```
postgresql://postgres:postgres@localhost:5432/myapp
```

## Redis Access

```bash
# Via Docker
docker exec -it saaas-dev-redis-1 redis-cli

# Via local client
redis-cli -h localhost -p 6379
```

## Troubleshooting

### Services Not Starting

```bash
# Check container logs
docker compose -f docker/docker-compose.dev.yml logs [service-name]

# Rebuild specific service
docker compose -f docker/docker-compose.dev.yml build [service-name]
docker compose -f docker/docker-compose.dev.yml up -d [service-name]
```

### Port Conflicts

```bash
# Check what's using a port
lsof -i :8080
lsof -i :3000

# Kill process using port
kill -9 $(lsof -t -i :8080)
```

### Hot-Reload Not Working

**Go Services (Air)**
```bash
# Check Air is running
docker compose -f docker/docker-compose.dev.yml logs go-api | grep "watching"

# Restart the service
make dev-restart-go-api
```

**Rust Service (cargo-watch)**
```bash
# Check cargo-watch output
docker compose -f docker/docker-compose.dev.yml logs rust-api

# Force rebuild
docker compose -f docker/docker-compose.dev.yml restart rust-api
```

**PHP Service**
```bash
# Clear Symfony cache
docker exec saaas-dev-php-api-1 php bin/console cache:clear
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker compose -f docker/docker-compose.dev.yml ps postgres

# Check PostgreSQL logs
docker compose -f docker/docker-compose.dev.yml logs postgres

# Test connection
docker exec saaas-dev-postgres-1 pg_isready
```

### Reset Development Environment

```bash
# Stop and remove all containers and volumes
make dev-down
docker volume rm saaas-dev_postgres_data saaas-dev_redis_data saaas-dev_rust_target

# Rebuild from scratch
make dev-build
make dev-up
```

## IDE Setup

### VS Code Extensions

Recommended extensions for this project:
- **PHP**: PHP Intelephense, PHP Debug
- **Go**: Go (official extension)
- **Rust**: rust-analyzer
- **Frontend**: ES7+ React/Redux/React-Native snippets
- **Docker**: Docker, Docker Compose
- **General**: GitLens, Prettier

### JetBrains IDEs

#### PHPStorm
1. Configure PHP interpreter to use Docker
2. Set up Xdebug with port 9003
3. Map `/app` to `php-services/`

#### GoLand
1. Configure Go SDK
2. Set up remote debugging on ports 2345/2346
3. Map `/app` to `go-services/`

#### WebStorm
1. Configure Node.js interpreter
2. Set up npm/pnpm scripts
3. Enable HMR debugging

## Performance Tips

1. **Use volume caching**: The Rust target directory is cached in a Docker volume to speed up builds

2. **Selective service startup**: Start only needed services:
   ```bash
   docker compose -f docker/docker-compose.dev.yml up -d postgres php-api frontend
   ```

3. **Resource limits**: Adjust Docker Desktop resources if builds are slow

4. **Parallel builds**: Docker Compose builds services in parallel by default

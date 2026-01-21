.PHONY:

docker-up:
	docker compose -f docker/docker-compose.yml up -d

docker-down:
	docker compose -f docker/docker-compose.yml down

docker-build:
	docker compose -f docker/docker-compose.yml build

docker-ps:
	docker compose -f docker/docker-compose.yml ps

# Development commands (hot-reload + debugging)
dev-up:
	docker compose -f docker/docker-compose.dev.yml up -d

dev-down:
	docker compose -f docker/docker-compose.dev.yml down

dev-build:
	docker compose -f docker/docker-compose.dev.yml build

dev-logs:
	docker compose -f docker/docker-compose.dev.yml logs -f

dev-ps:
	docker compose -f docker/docker-compose.dev.yml ps

# Service-specific dev logs
dev-logs-php:
	docker compose -f docker/docker-compose.dev.yml logs -f php-api

dev-logs-go:
	docker compose -f docker/docker-compose.dev.yml logs -f go-api go-gateway

dev-logs-rust:
	docker compose -f docker/docker-compose.dev.yml logs -f rust-api

dev-logs-frontend:
	docker compose -f docker/docker-compose.dev.yml logs -f frontend

# Restart individual services
dev-restart-%:
	docker compose -f docker/docker-compose.dev.yml restart $*

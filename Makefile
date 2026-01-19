.PHONY: setup test help
help:
	@echo "setup: Setup all services"
	@echo "test: Run all tests"
setup:
	pnpm install
	cd php-backend && composer install
	cd ../go-services && go mod download
test:
	@echo "Frontend tests..."
	cd frontend && pnpm test
	@echo "PHP tests..."
	cd php-backend && vendor/bin/phpunit
	@echo "Go tests..."
	cd go-services && go test ./...

docker-up:
	docker compose -f docker/docker-compose.yml up -d

docker-down:
	docker compose -f docker/docker-compose.yml down

docker-build:
	docker compose -f docker/docker-compose.yml build

.PHONY:

docker-up:
	docker compose -f docker/docker-compose.yml up -d

docker-down:
	docker compose -f docker/docker-compose.yml down

docker-build:
	docker compose -f docker/docker-compose.yml build

docker-ps:
	docker compose -f docker/docker-compose.yml ps

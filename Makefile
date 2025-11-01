# Hexo JP KLC Makefile
# Replaces justfile and converts docker compose to docker CLI

# Load environment variables from settings.env
include settings.env
export

# Docker configuration
DOCKER_IMAGE := postgres:18.0-trixie
CONTAINER_NAME := hexojpdb
NETWORK_NAME := hexojp-network
VOLUME_NAME := hexojp-klc_postgres

# Derived paths
DB_INIT_SCRIPT := $(CURDIR)/dockerfiles/db/init-user-db.sh
DB_DUMP_PATH := $(CURDIR)/dockerfiles/db/hexojp.tar.gz

################################################################################
## General/shorthand targets
################################################################################

.PHONY: daily
daily:
	@cd db && perl daily.pl

.PHONY: generate
generate:
	@node_modules/.bin/hexo generate

.PHONY: server
server:
	@node_modules/.bin/hexo server --port $(SERVER_PORT)

.PHONY: init
init: docker-up

################################################################################
## Docker targets (using docker CLI instead of docker compose)
################################################################################

.PHONY: docker-network
docker-network:
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || \
		docker network create $(NETWORK_NAME)

.PHONY: docker-volume
docker-volume:
	@docker volume inspect $(VOLUME_NAME) >/dev/null 2>&1 || \
		docker volume create $(VOLUME_NAME)

.PHONY: docker-up
docker-up: docker-network docker-volume
	@if [ "$$(docker ps -a -q -f name=$(CONTAINER_NAME))" ]; then \
		if [ "$$(docker ps -q -f name=$(CONTAINER_NAME))" ]; then \
			echo "Container $(CONTAINER_NAME) is already running"; \
		else \
			echo "Starting existing container $(CONTAINER_NAME)"; \
			docker start $(CONTAINER_NAME); \
		fi \
	else \
		echo "Creating and starting new container $(CONTAINER_NAME)"; \
		docker run -d \
			--name $(CONTAINER_NAME) \
			--network $(NETWORK_NAME) \
			-p $(DB_PORT):5432 \
			-e POSTGRES_USER=$(POSTGRES_USER) \
			-e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
			-e POSTGRES_DB=$(POSTGRES_DB) \
			-e PGDATA=$(POSTGRES_PGDATA) \
			-v $(VOLUME_NAME):/var/lib/postgresql/data \
			-v $(DB_INIT_SCRIPT):/docker-entrypoint-initdb.d/init-user-db.sh \
			-v $(DB_DUMP_PATH):/docker-entrypoint-initdb.d/hexojp.tar.gz \
			$(DOCKER_IMAGE) \
			postgres \
			-c max_connections=$(MAX_CONNECTIONS) \
			-c shared_buffers=$(SHARED_BUFFERS); \
	fi

.PHONY: docker-stop
docker-stop:
	@if [ "$$(docker ps -q -f name=$(CONTAINER_NAME))" ]; then \
		echo "Stopping container $(CONTAINER_NAME)"; \
		docker stop $(CONTAINER_NAME); \
	else \
		echo "Container $(CONTAINER_NAME) is not running"; \
	fi

.PHONY: docker-down
docker-down:
	@echo "Stopping and removing container $(CONTAINER_NAME)"
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@echo "Removing volume $(VOLUME_NAME)"
	@docker volume rm $(VOLUME_NAME) 2>/dev/null || true

.PHONY: docker-build
docker-build:
	@echo "Note: Using official postgres image, no custom build needed"
	@docker pull $(DOCKER_IMAGE)

.PHONY: docker-build-nocache
docker-build-nocache: docker-build

.PHONY: docker-logs
docker-logs:
	@docker logs $(CONTAINER_NAME)

.PHONY: docker-logs-follow
docker-logs-follow:
	@docker logs -f $(CONTAINER_NAME)

.PHONY: docker-prune
docker-prune:
	@docker system prune

.PHONY: docker-prune-db
docker-prune-db:
	@echo "Removing container $(CONTAINER_NAME)"
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@echo "Removing volume $(VOLUME_NAME)"
	@docker volume rm $(VOLUME_NAME) 2>/dev/null || true
	@echo "Removing image $(DOCKER_IMAGE)"
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

.PHONY: docker-prune-volumes
docker-prune-volumes:
	@docker system prune --volumes

################################################################################
## Database targets
################################################################################

.PHONY: db-dump
db-dump:
	@rm -f dockerfiles/db/*.tar.gz && \
		pg_dump -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) $(DB_NAME) -F c -Z 9 -f dockerfiles/db/$(DB_DUMP_FILE)

.PHONY: db-restore
db-restore:
	@echo "Restoring database from dockerfiles/db/$(DB_DUMP_FILE)"
	@echo "Variables: DB_HOST=$(DB_HOST), DB_PORT=$(DB_PORT), DB_NAME=$(DB_NAME)"
	@PGPASSWORD=$(DB_PASSWORD) pg_restore -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d $(DB_NAME) dockerfiles/db/$(DB_DUMP_FILE)

.PHONY: db-logs
db-logs: docker-logs

.PHONY: db-connect
db-connect:
	@docker exec -it --privileged -u $(ROOT_USER) $(CONTAINER_NAME) bash

.PHONY: help
help:
	@echo "Hexo JP KLC - Available Make targets:"
	@echo ""
	@echo "General targets:"
	@echo "  daily           - Generate new daily kanji post"
	@echo "  generate        - Generate static site with Hexo"
	@echo "  server          - Start Hexo development server"
	@echo "  init            - Initialize environment (start docker)"
	@echo ""
	@echo "Docker targets:"
	@echo "  docker-up       - Start PostgreSQL container"
	@echo "  docker-stop     - Stop PostgreSQL container"
	@echo "  docker-down     - Stop and remove container + volume"
	@echo "  docker-build    - Pull PostgreSQL image"
	@echo "  docker-logs     - Show container logs"
	@echo "  docker-logs-follow - Follow container logs"
	@echo "  docker-prune    - Prune docker system"
	@echo "  docker-prune-db - Remove container, volume, and image"
	@echo ""
	@echo "Database targets:"
	@echo "  db-dump         - Dump database to file"
	@echo "  db-restore      - Restore database from dump"
	@echo "  db-logs         - Show database logs"
	@echo "  db-connect      - Connect to database container"
	@echo ""
	@echo "  help            - Show this help message"

set dotenv-load
set dotenv-filename := "./settings.env"
set dotenv-required := true

################################################################################
## Utility functions
################################################################################

# Private function to run subcommand tasks
_subcommand prefix subcommand:
    @just {{prefix}}_{{subcommand}}

# DB subcommand dispatcher
db subcommand:
    @just _subcommand db {{subcommand}}

# Docker subcommand dispatcher
docker subcommand:
    @just _subcommand docker {{subcommand}}

################################################################################
## General/shorthand tasks
################################################################################

daily:
    @cd db && perl daily.pl

# Generate static site with Hexo
generate:
    @hexo generate

# Start Hexo development server
server:
    @hexo server --port $SERVER_PORT

# Initialize environment: start docker
init: docker_up

################################################################################
## Docker tasks
################################################################################

# Stop containers and remove postgres volume
docker_down:
    @docker compose down
    @docker volume rm hexojp-klc_postgres

# Start containers in detached mode
docker_up:
    @docker compose up -d

# Build docker images
docker_build:
    @docker compose build

# Build docker images without cache
docker_build_nocache:
    @docker compose build --no-cache

# Get logs for db container
docker_logs_db:
    @docker compose logs $DB_CONTAINER

# Stop containers
docker_stop:
    @docker compose stop

# Prune docker system
docker_prune:
    @docker system prune

# Prune DB container, volume, and image
docker_prune_db:
    @docker rm -f hexojpdb
    @docker volume rm hexojp-klc_postgres
    @docker image rm hexojp-klc-hexojpdb

# Prune docker system including volumes
docker_prune_volumes:
    @docker system prune --volumes

################################################################################
## Database tasks
################################################################################

# Dump database to file
db_dump:
    @cd db && rm *.tar.gz && pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME -F c -Z 9 -f $DB_DUMP_FILE

# Restore database from dump
db_restore:
    @echo "Restoring database from db/$DB_DUMP_FILE"
    @echo "Variables: DB_HOST=$DB_HOST, DB_PORT=$DB_PORT, DB_NAME=$DB_NAME"
    @cd db && pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -F c < $DB_DUMP_FILE

# Show database logs
db_logs:
    @docker compose logs $DB_CONTAINER

# Connect to database container as root
db_connect:
    @docker compose exec --privileged -u $ROOT_USER $DB_CONTAINER bash

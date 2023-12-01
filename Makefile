# Makefile for multiwoven-core monorepo management

# Declare variables for the subtrees
MULTIWOVEN_SERVER = git@github.com:Multiwoven/multiwoven-server.git

# Compose files
DEV_COMPOSE_FILE = docker-compose-dev.yml
PROD_COMPOSE_FILE = docker-compose.yml

# Initialize all subtrees (to be run once when setting up the repo)
init:
	git subtree add --prefix=control-plane $(MULTIWOVEN_SERVER) main --squash

# Initialize subtrees for development
dev-init: init

# Initialize subtrees for production
prod-init: init

# Update all subtrees from their respective remotes
update:
	git subtree pull --prefix=control-plane $(MULTIWOVEN_SERVER) main --squash

# Push changes to all subtrees to their respective remotes
push:
	git subtree push --prefix=control-plane $(MULTIWOVEN_SERVER) main

# Start local development environment
dev-up:
	docker-compose -f $(DEV_COMPOSE_FILE) up -d

# Stop local development environment
dev-down:
	docker-compose -f $(DEV_COMPOSE_FILE) down

# Start production environment
prod-up:
	docker-compose -f $(PROD_COMPOSE_FILE) up -d

# Stop production environment
prod-down:
	docker-compose -f $(PROD_COMPOSE_FILE) down

# View logs from all containers in dev environment
dev-logs:
	docker-compose -f $(DEV_COMPOSE_FILE) logs -f

# View logs from all containers in prod environment
prod-logs:
	docker-compose -f $(PROD_COMPOSE_FILE) logs -f

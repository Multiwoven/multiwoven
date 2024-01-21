# Makefile for multiwoven-core monorepo management using Git submodules

# Declare variables for the submodules
MULTIWOVEN_SERVER_REPO = git@github.com:Multiwoven/multiwoven-server.git
MULTIWOVEN_UI_REPO = git@github.com:Multiwoven/multiwoven-ui.git
MULTIWOVEN_INTEGRATIONS = git@github.com:Multiwoven/multiwoven-integrations.git

# Compose files
DEV_COMPOSE_FILE = docker-compose-dev.yml
PROD_COMPOSE_FILE = docker-compose.yml

# Initialize all submodules (to be run once when setting up the repo)
init:
	git submodule add $(MULTIWOVEN_SERVER_REPO) server
	git submodule add $(MULTIWOVEN_UI_REPO) ui
	git submodule add $(MULTIWOVEN_INTEGRATIONS) integrations
	git submodule init
	git submodule update

# Initialize submodules for development
dev-init: init

# Initialize submodules for production
prod-init: init

# Update all submodules from their respective remotes
update:
	git submodule update --remote

# Pull latest changes for all submodules and push updated submodules to monorepo
update-submodules:
	git submodule update --remote
	git submodule foreach '(git checkout main; git pull origin main;)'
	git commit -am "Updated submodules to the latest commits"
	git push origin main

# Update and push submodules to the latest commit
update-push:
	git submodule foreach '(git checkout main; git pull origin main; git submodule update --remote --merge; git commit -am "Updated submodule to latest commit."; git push origin main;)'

# Push changes to the main repository
push:
	git push origin main

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

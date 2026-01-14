# =============================================================================
# Rediver Platform - Root Makefile
# =============================================================================
# Staging environment management for both API and UI
#
# Quick Start:
#   1. cp .env.staging.example .env.staging
#   2. Edit .env.staging (update AUTH_JWT_SECRET, CSRF_SECRET)
#   3. make staging-up
#
# With test data:
#   make staging-up-seed
# =============================================================================

COMPOSE_FILE := docker-compose.staging.yml
ENV_FILE := .env.staging

.PHONY: help staging-up staging-up-seed staging-down staging-logs staging-ps staging-restart \
        staging-build staging-rebuild staging-clean db-shell db-seed redis-shell \
        build-api build-ui check-env generate-secrets

# =============================================================================
# Help
# =============================================================================

help: ## Show this help
	@echo "Usage: make [target]"
	@echo ""
	@echo "Quick Start:"
	@echo "  1. cp .env.staging.example .env.staging"
	@echo "  2. make generate-secrets  # Generate secure secrets"
	@echo "  3. make staging-up        # Start all services"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Quick Start Commands
# =============================================================================

staging-up: check-env ## Start staging (build + migrate + run)
	@echo "Starting staging environment..."
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build
	@echo ""
	@echo "Services starting..."
	@echo "  UI: http://localhost:$${UI_PORT:-3000}"
	@echo ""
	@echo "Note: API is internal only (accessible via Docker network)"
	@echo "View logs: make staging-logs"

staging-up-seed: check-env ## Start staging with test data seeding
	@echo "Starting staging environment with test data..."
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) --profile seed up -d --build
	@echo ""
	@echo "Test credentials: admin@rediver.io / Password123"
	@echo ""
	@echo "Services starting..."
	@echo "  UI: http://localhost:$${UI_PORT:-3000}"
	@echo ""
	@echo "Note: API is internal only (accessible via Docker network)"

staging-down: ## Stop all staging services
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down

staging-logs: ## View all logs (follow mode)
	docker compose -f $(COMPOSE_FILE) logs -f

staging-logs-api: ## View API logs only
	docker compose -f $(COMPOSE_FILE) logs -f api

staging-logs-ui: ## View UI logs only
	docker compose -f $(COMPOSE_FILE) logs -f ui

staging-ps: ## Show running containers
	docker compose -f $(COMPOSE_FILE) ps

staging-restart: ## Restart all services
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) restart

staging-restart-api: ## Restart API only
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) restart api

staging-restart-ui: ## Restart UI only
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) restart ui

# =============================================================================
# Build Commands
# =============================================================================

staging-build: ## Build images without starting
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build

staging-rebuild: ## Force rebuild and restart
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build --force-recreate

build-api: ## Build only API image
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build api

build-ui: ## Build only UI image
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build ui

# =============================================================================
# Database Commands
# =============================================================================

db-shell: ## Open PostgreSQL shell
	docker compose -f $(COMPOSE_FILE) exec postgres psql -U $${DB_USER:-rediver} -d $${DB_NAME:-rediver}

db-migrate: ## Run migrations manually
	docker run --rm -v $$(pwd)/rediver-api/migrations:/migrations --network host \
		migrate/migrate -path=/migrations -database "postgres://$${DB_USER:-rediver}:$${DB_PASSWORD:-secret}@localhost:$${DB_EXTERNAL_PORT:-5432}/$${DB_NAME:-rediver}?sslmode=disable" up

db-migrate-down: ## Rollback last migration
	docker run --rm -v $$(pwd)/rediver-api/migrations:/migrations --network host \
		migrate/migrate -path=/migrations -database "postgres://$${DB_USER:-rediver}:$${DB_PASSWORD:-secret}@localhost:$${DB_EXTERNAL_PORT:-5432}/$${DB_NAME:-rediver}?sslmode=disable" down 1

db-seed: ## Seed test data
	docker compose -f $(COMPOSE_FILE) exec -T postgres psql -U $${DB_USER:-rediver} -d $${DB_NAME:-rediver} < rediver-api/migrations/seed/seed_test.sql
	@echo "Seeding complete! Test login: admin@rediver.io / Password123"

db-reset: ## Reset database (drop all data)
	docker compose -f $(COMPOSE_FILE) exec postgres psql -U $${DB_USER:-rediver} -d $${DB_NAME:-rediver} -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	@echo "Database reset. Restart services to re-run migrations."

redis-shell: ## Open Redis CLI
	docker compose -f $(COMPOSE_FILE) exec redis redis-cli

# =============================================================================
# Cleanup Commands
# =============================================================================

staging-clean: ## Stop and remove all containers, volumes
	docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down -v
	@echo "Cleaned up. Run 'make staging-up' to start fresh."

staging-prune: ## Remove unused Docker resources
	docker system prune -f
	docker volume prune -f

# =============================================================================
# Utility Commands
# =============================================================================

check-env: ## Check if .env.staging exists
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Error: $(ENV_FILE) not found!"; \
		echo "Run: cp .env.staging.example .env.staging"; \
		echo "Then update the secrets in .env.staging"; \
		exit 1; \
	fi

generate-secrets: ## Generate secure secrets for .env.staging
	@echo "JWT Secret (copy to AUTH_JWT_SECRET):"
	@openssl rand -base64 48
	@echo ""
	@echo "CSRF Secret (copy to CSRF_SECRET):"
	@openssl rand -hex 32
	@echo ""
	@echo "DB Password (copy to DB_PASSWORD):"
	@openssl rand -base64 24

status: ## Show service status and URLs
	@echo "=== Staging Environment Status ==="
	@docker compose -f $(COMPOSE_FILE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "URLs:"
	@echo "  UI:  http://localhost:$${UI_PORT:-3000}"
	@echo "  API: http://localhost:$${API_PORT:-8080}"
	@echo "  API Health: http://localhost:$${API_PORT:-8080}/health"

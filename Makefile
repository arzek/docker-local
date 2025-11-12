# Docker Compose Management
.PHONY: help up down restart logs ps clean backup restore

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Start all services
	docker-compose up -d
	@echo "Services started. Checking health..."
	@sleep 5
	@docker-compose ps

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## Show logs for all services
	docker-compose logs -f

logs-postgres: ## Show PostgreSQL logs
	docker-compose logs -f postgres

logs-redis: ## Show Redis logs
	docker-compose logs -f redis

ps: ## Show service status
	docker-compose ps

clean: ## Stop services and remove volumes (WARNING: deletes all data!)
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker-compose down -v

shell-postgres: ## Open PostgreSQL shell
	docker-compose exec postgres psql -U postgres -d postgres

shell-redis: ## Open Redis CLI
	docker-compose exec redis redis-cli

backup: ## Create backup (volume snapshots)
	@mkdir -p backups
	@echo "Creating volume backups..."
	@TIMESTAMP=$$(date +%Y-%m-%d_%H-%M-%S); \
	docker run --rm -v postgres-data:/data -v "$$(pwd)/backups:/backup" alpine tar czf /backup/postgres_$$TIMESTAMP.tar.gz -C /data . && \
	docker run --rm -v redis-data:/data -v "$$(pwd)/backups:/backup" alpine tar czf /backup/redis_$$TIMESTAMP.tar.gz -C /data .
	@echo "✅ Backup completed!"
	@ls -lh backups/*.tar.gz | tail -2

restore: ## Restore from backup (usage: make restore POSTGRES=backups/postgres_20241027.tar.gz REDIS=backups/redis_20241027.tar.gz)
	@if [ -z "$(POSTGRES)" ] || [ -z "$(REDIS)" ]; then echo "Usage: make restore POSTGRES=postgres_backup.tar.gz REDIS=redis_backup.tar.gz"; exit 1; fi
	@echo "Restoring from backups..."
	@docker-compose down
	@docker volume rm -f postgres-data redis-data
	@docker volume create postgres-data
	@docker volume create redis-data
	@docker run --rm -v postgres-data:/data -v "$$(pwd)/$(POSTGRES):/backup.tar.gz" alpine tar xzf /backup.tar.gz -C /data
	@docker run --rm -v redis-data:/data -v "$$(pwd)/$(REDIS):/backup.tar.gz" alpine tar xzf /backup.tar.gz -C /data
	@docker-compose up -d
	@echo "✅ Restore completed!"

health: ## Check health status of all services
	@echo "Checking health status..."
	@docker inspect postgres --format='PostgreSQL: {{.State.Health.Status}}'
	@docker inspect redis --format='Redis: {{.State.Health.Status}}'

stats: ## Show resource usage statistics
	docker stats --no-stream

test-connection: ## Test database connections
	@echo "Testing PostgreSQL connection..."
	@docker-compose exec postgres pg_isready -U postgres -d postgres && echo "PostgreSQL: OK" || echo "PostgreSQL: FAILED"
	@echo "\nTesting Redis connection..."
	@docker-compose exec redis redis-cli ping | grep -q PONG && echo "Redis: OK" || echo "Redis: FAILED"

init: ## Initialize project (copy .env.example to .env)
	@if [ ! -f .env ]; then cp .env.example .env && echo ".env file created. Please update passwords!"; else echo ".env file already exists"; fi
	@mkdir -p init-scripts
	@echo "Project initialized. Run 'make up' to start services."
.PHONY: help up down logs ps

help: ## Show this help message
	@echo 'Usage: make [target] service=[service_name]'
	@echo
	@echo 'Targets:'
	@echo '  up       Start a service (e.g., make up service=wordpress)'
	@echo '  down     Stop a service (e.g., make down service=wordpress)'
	@echo '  logs     View logs for a service (e.g., make logs service=wordpress)'
	@echo '  ps       List containers for a service (e.g., make ps service=wordpress)'
	@echo

up: ## Start a service
	@if [ -z "$(service)" ]; then echo "Error: service argument is required (e.g., make up service=wordpress)"; exit 1; fi
	@if [ ! -d "$(service)" ]; then echo "Error: directory '$(service)' does not exist"; exit 1; fi
	@echo "Starting $(service)..."
	@cd $(service) && docker compose up -d

down: ## Stop a service
	@if [ -z "$(service)" ]; then echo "Error: service argument is required (e.g., make down service=wordpress)"; exit 1; fi
	@if [ ! -d "$(service)" ]; then echo "Error: directory '$(service)' does not exist"; exit 1; fi
	@echo "Stopping $(service)..."
	@cd $(service) && docker compose down

logs: ## View logs for a service
	@if [ -z "$(service)" ]; then echo "Error: service argument is required (e.g., make logs service=wordpress)"; exit 1; fi
	@if [ ! -d "$(service)" ]; then echo "Error: directory '$(service)' does not exist"; exit 1; fi
	@cd $(service) && docker compose logs -f

ps: ## List containers for a service
	@if [ -z "$(service)" ]; then echo "Error: service argument is required (e.g., make ps service=wordpress)"; exit 1; fi
	@if [ ! -d "$(service)" ]; then echo "Error: directory '$(service)' does not exist"; exit 1; fi
	@cd $(service) && docker compose ps

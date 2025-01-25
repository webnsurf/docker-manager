.PHONY: default
default:
	@echo Tasks:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

run: ## Run Docker manager container
	docker compose up -d

clean: ## Stop and remove Docker manager container
	docker compose down

logs: ## Stop and remove Docker manager container
	docker compose logs --tail="100" --follow

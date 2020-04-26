.PHONY: default
default:
	@echo Tasks:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY:
run: ## Run Docker manager container
	docker-compose up -d

.PHONY:
clean: ## Stop and remove Docker manager container
	docker-compose down

.PHONY: help install test build clean docker-build docker-test lint validate

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Claude Docker - Makefile Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install claude-dev and claude-flow globally
	@echo "Installing Claude Docker..."
	@bash install.sh

test: ## Run all tests
	@echo "Running tests..."
	@bash tests/test-install.sh

build: docker-build ## Alias for docker-build

docker-build: ## Build Docker images locally
	@echo "Building Docker images..."
	@docker build -f docker/Dockerfile.dev -t claude-docker:local-dev .
	@docker build -f docker/Dockerfile.flow -t claude-docker:local-flow .
	@echo "✅ Images built: claude-docker:local-dev, claude-docker:local-flow"

docker-test: ## Test Docker images
	@echo "Testing dev image..."
	@docker run --rm claude-docker:local-dev node --version
	@docker run --rm claude-docker:local-dev php --version
	@docker run --rm claude-docker:local-dev python3 --version
	@echo "Testing flow image..."
	@docker run --rm claude-docker:local-flow playwright --version
	@docker run --rm claude-docker:local-flow deno --version
	@echo "✅ All images tested successfully"

lint: ## Lint shell scripts with shellcheck
	@echo "Linting shell scripts..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed, skipping..."; exit 0; }
	@shellcheck install.sh || true
	@shellcheck bin/claude-dev || true
	@shellcheck bin/claude-flow || true
	@shellcheck bin/git-commit-ai || true
	@shellcheck bin/claude-health || true
	@shellcheck bin/mcp-status || true
	@shellcheck tests/*.sh || true
	@echo "✅ Linting complete"

validate: ## Validate JSON and bash syntax
	@echo "Validating JSON files..."
	@jq empty mcp/config.json
	@jq empty mcp/cache/claude-project-settings-template.json
	@echo "Validating bash syntax..."
	@bash -n install.sh
	@bash -n bin/claude-dev
	@bash -n bin/claude-flow
	@bash -n bin/git-commit-ai
	@bash -n bin/claude-health
	@bash -n bin/mcp-status
	@bash -n tests/test-install.sh
	@bash -n tests/validate-mcp.sh
	@echo "✅ All files valid"

clean: ## Remove built images and temporary files
	@echo "Cleaning up..."
	@docker rmi -f claude-docker:local-dev 2>/dev/null || true
	@docker rmi -f claude-docker:local-flow 2>/dev/null || true
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@echo "✅ Cleaned up"

dev: ## Start claude-dev in current directory
	@echo "Starting claude-dev..."
	@claude-dev

flow: ## Start claude-flow in current directory  
	@echo "Starting claude-flow..."
	@claude-flow

health: ## Check container health
	@claude-health

stop: ## Stop all Claude containers
	@echo "Stopping containers..."
	@docker stop claude-dev 2>/dev/null || true
	@docker stop claude-flow 2>/dev/null || true
	@echo "✅ Containers stopped"

logs-dev: ## Show logs from dev container
	@docker logs claude-dev

logs-flow: ## Show logs from flow container
	@docker logs claude-flow

shell-dev: ## Open shell in dev container
	@docker exec -it claude-dev bash

shell-flow: ## Open shell in flow container
	@docker exec -it claude-flow bash

push: ## Build and push images to Docker Hub (requires credentials)
	@echo "Building and pushing to Docker Hub..."
	@docker buildx build --platform linux/amd64,linux/arm64 \
		-f docker/Dockerfile.dev \
		-t andreashurst/claude-docker:latest-dev \
		--push .
	@docker buildx build --platform linux/amd64,linux/arm64 \
		-f docker/Dockerfile.flow \
		-t andreashurst/claude-docker:latest-flow \
		--push .
	@echo "✅ Images pushed to Docker Hub"

ci: lint validate test docker-build docker-test ## Run full CI pipeline locally
	@echo "✅ Full CI pipeline completed"

version: ## Show version information
	@echo "Claude Docker"
	@grep "VERSION=" bin/claude-dev | head -1
	@echo ""
	@echo "Docker:"
	@docker --version
	@echo ""
	@echo "Available images:"
	@docker images | grep claude-docker || echo "  No local images found"

benchmark: ## Run performance benchmarks
	@bash tests/benchmark.sh

image-report: ## Show Docker image size report
	@docker-image-report

update: ## Check for updates
	@claude-update --check

install-completions: ## Install shell completions
	@echo "Installing shell completions..."
	@if [ -d /etc/bash_completion.d ]; then \
		sudo cp completions/claude-dev.bash /etc/bash_completion.d/; \
		sudo cp completions/claude-flow.bash /etc/bash_completion.d/; \
		echo "✅ Bash completions installed"; \
	fi
	@if [ -d /usr/local/share/zsh/site-functions ]; then \
		sudo cp completions/_claude-dev /usr/local/share/zsh/site-functions/; \
		sudo cp completions/_claude-flow /usr/local/share/zsh/site-functions/; \
		echo "✅ Zsh completions installed"; \
	fi

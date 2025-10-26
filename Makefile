# Makefile for SIPp Docker Testing
# Common operations automation

.PHONY: help build up down status logs stats clean install test

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_IMAGE := sipp:3.4.1
COMPOSE_FILE := docker-compose.yml
COMPOSE_SBC := docker-compose-sbc-test.yml
LOGS_DIR := logs

# Help target
help: ## Show this help message
	@echo "SIPp Docker Testing - Available Commands"
	@echo "========================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build           - Build SIPp Docker image"
	@echo "  make up              - Start containers"
	@echo "  make status          - Show container status"
	@echo "  make logs            - View logs"
	@echo "  make monitor         - Real-time monitoring"
	@echo ""

## Build Commands
build: ## Build SIPp Docker image
	@echo "Building SIPp Docker image..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "Build complete: $(DOCKER_IMAGE)"

rebuild: ## Rebuild SIPp Docker image (no cache)
	@echo "Rebuilding SIPp Docker image (no cache)..."
	docker build --no-cache -t $(DOCKER_IMAGE) .
	@echo "Rebuild complete: $(DOCKER_IMAGE)"

## Docker Compose Commands
up: ## Start basic Docker Compose containers
	@echo "Starting containers..."
	docker compose -f $(COMPOSE_FILE) up -d
	@$(MAKE) status

up-sbc: ## Start SBC testing containers
	@echo "Starting SBC testing containers..."
	docker compose -f $(COMPOSE_SBC) up -d
	@$(MAKE) status

up-advanced: ## Start SBC containers with advanced profile
	@echo "Starting SBC containers with advanced scenarios..."
	docker compose -f $(COMPOSE_SBC) --profile advanced up -d
	@$(MAKE) status

up-all: ## Start all SBC containers (all profiles)
	@echo "Starting all SBC containers..."
	docker compose -f $(COMPOSE_SBC) --profile advanced --profile stress --profile registration up -d
	@$(MAKE) status

down: ## Stop and remove all containers
	@echo "Stopping containers..."
	docker compose -f $(COMPOSE_FILE) down 2>/dev/null || true
	docker compose -f $(COMPOSE_SBC) down 2>/dev/null || true
	@echo "Containers stopped"

restart: down up ## Restart containers

## Status and Monitoring
status: ## Show container status
	@echo "Container Status:"
	@echo "================="
	@docker ps -a --filter "name=sipp-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

stats: ## Show resource usage statistics
	@echo "Resource Usage:"
	@echo "==============="
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $$(docker ps --filter "name=sipp-" --format "{{.Names}}")

monitor: ## Start real-time monitoring dashboard
	@./scripts/monitor.sh watch

## Logging
logs: ## Show logs for all containers
	docker compose -f $(COMPOSE_FILE) logs -f 2>/dev/null || docker compose -f $(COMPOSE_SBC) logs -f

logs-uac: ## Show UAC container logs
	@docker logs -f $$(docker ps --filter "name=sipp-uac" --format "{{.Names}}" | head -n 1)

logs-uas: ## Show UAS container logs
	@docker logs -f $$(docker ps --filter "name=sipp-uas" --format "{{.Names}}" | head -n 1)

## Testing
test-basic: build ## Run basic connectivity test
	@echo "Running basic test..."
	@./sipp-control.sh run-uac sipp_uac_basic.xml ${SBC_IP:-127.0.0.1} 1 10 100

test-g711: build ## Run G.711 codec test
	@echo "Running G.711 test..."
	@./sipp-control.sh run-uac sipp_uac_pcap_g711a.xml ${SBC_IP:-127.0.0.1} 5 50 500

menu: ## Open interactive menu
	@./sipp-control.sh

## Cleanup
clean: down ## Clean up containers and logs
	@echo "Cleaning up..."
	@docker ps -a --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Containers removed"

clean-logs: ## Remove log files
	@echo "Removing log files..."
	@rm -rf $(LOGS_DIR)/*
	@echo "Logs cleaned"

clean-all: clean clean-logs ## Clean everything (containers + logs)
	@echo "Full cleanup complete"

## Container Management
stop-all: ## Stop all running SIPp containers
	@echo "Stopping all SIPp containers..."
	@docker ps --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker stop
	@echo "All containers stopped"

rm-all: stop-all ## Remove all SIPp containers
	@echo "Removing all SIPp containers..."
	@docker ps -a --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker rm
	@echo "All containers removed"

## Environment Setup
install: ## Install Docker on Oracle Enterprise Linux
	@echo "Installing Docker on Oracle Enterprise Linux..."
	@sudo ./scripts/setup-docker-el.sh

init: ## Initialize environment (create .env from template)
	@if [ ! -f .env ]; then \
		echo "Creating .env file from template..."; \
		cp .env.example .env; \
		echo ".env file created. Please edit with your settings."; \
	else \
		echo ".env file already exists"; \
	fi

setup: init build ## Complete setup (init + build)
	@echo "Setup complete! Run 'make menu' to start testing"

## Information
info: ## Show system and Docker information
	@echo "System Information"
	@echo "=================="
	@echo "Docker Version: $$(docker --version)"
	@echo "Docker Compose: $$(docker compose version)"
	@echo "Images:"
	@docker images | grep sipp || echo "  No SIPp images found"
	@echo ""
	@echo "Networks:"
	@docker network ls --filter "name=sipp" || echo "  No SIPp networks found"
	@echo ""
	@echo "Volumes:"
	@docker volume ls --filter "name=sipp" || echo "  No SIPp volumes found"
	@echo ""
	@$(MAKE) status

scenarios: ## List available test scenarios
	@./sipp-control.sh list-scenarios

## Advanced
shell-uac: ## Open shell in UAC container
	@docker exec -it $$(docker ps --filter "name=sipp-uac" --format "{{.Names}}" | head -n 1) /bin/bash

shell-uas: ## Open shell in UAS container
	@docker exec -it $$(docker ps --filter "name=sipp-uas" --format "{{.Names}}" | head -n 1) /bin/bash

tcpdump: ## Capture SIP/RTP traffic (requires root)
	@echo "Starting packet capture (Ctrl+C to stop)..."
	@sudo tcpdump -i any -n -s 0 -w sipp-capture-$$(date +%Y%m%d-%H%M%S).pcap \
		'(udp port 5060) or (udp portrange 16384-32768)'

## CI/CD
ci-test: build ## Run CI/CD tests
	@echo "Running CI/CD test suite..."
	@./sipp-control.sh run-uac sipp_uac_basic.xml 127.0.0.1 10 100 1000
	@sleep 5
	@if [ -f $(LOGS_DIR)/sipp-uac-*/errors.log ]; then \
		echo "Test completed - checking for errors..."; \
		if [ -s $(LOGS_DIR)/sipp-uac-*/errors.log ]; then \
			echo "FAILED: Errors detected"; \
			exit 1; \
		else \
			echo "PASSED: No errors"; \
		fi \
	fi

## Documentation
docs: ## Generate documentation
	@echo "Documentation available at:"
	@echo "  README.md                    - Main documentation"
	@echo "  scens/README.md              - Scenario catalog"
	@echo "  .env.example                 - Configuration reference"
	@echo ""
	@echo "Quick start: make setup && make menu"

version: ## Show version information
	@echo "JAST - Just Another SIP Tester"
	@echo "Version: 1.0.0"
	@echo "SIPp Version: 3.4.1"
	@echo "Repository: https://github.com/user/jast"

.PHONY: help up monitoring app all status port-forward test down clean

help: ## Display available make commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## 1. Create multi-node Kind cluster
	@bash scripts/setup-cluster.sh

monitoring: ## 2. Install kube-prometheus-stack via Helm
	@bash scripts/install-monitoring.sh

app: ## 3. Deploy multi-service application, ServiceMonitors, and Grafana Dashboards
	@bash scripts/deploy-app.sh

all: up monitoring app ## Complete automated setup: cluster -> monitoring -> app
	@echo "=========================================================="
	@echo "✅ All components deployed and active!"
	@echo "   - Grafana UI:     http://localhost:30000 (admin/admin)"
	@echo "   - Prometheus UI:  http://localhost:30090"
	@echo "   - Frontend App:   http://localhost:30080"
	@echo "=========================================================="

status: ## Inspect all pods, services, and monitors
	@echo "=== Application Namespace ==="
	@kubectl get all,servicemonitor,prometheusrule -n app
	@echo "\n=== Monitoring Namespace ==="
	@kubectl get pods,svc -n monitoring

port-forward: ## Forward ports to localhost (standard port numbers)
	@bash scripts/port-forward.sh

test: ## Send synthetic test requests to sample application
	@echo "Sending test requests to frontend..."
	@curl -s http://localhost:30080/api/data | jq . || curl -s http://localhost:30080/api/data
	@echo "\nTesting latency endpoint..."
	@curl -s http://localhost:30080/api/slow | jq . || curl -s http://localhost:30080/api/slow
	@echo "\nTesting error endpoint..."
	@curl -s http://localhost:30080/api/error || true
	@echo "\nFinished test requests."

down: ## Delete kind cluster
	@bash scripts/teardown.sh

clean: down ## Alias for down

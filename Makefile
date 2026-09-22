.PHONY: build run docker-up tf-init tf-apply tf-destroy k8s-deploy k8s-status port-forward

# Go commands
build:
	go build -o bin/server ./cmd/server

run:
	go run ./cmd/server

# Docker Compose (legacy)
docker-up:
	docker-compose -f deployments/docker-compose.yml up --build

# Terraform commands
tf-init:
	cd deployments/terraform && terraform init

tf-plan:
	cd deployments/terraform && terraform plan

tf-apply:
	cd deployments/terraform && terraform apply -auto-approve

tf-destroy:
	cd deployments/terraform && terraform destroy -auto-approve

tf-output:
	cd deployments/terraform && terraform output

# Kubernetes commands
k8s-deploy:
	@echo "Building Docker image for kind..."
	docker build -t crypto-tracker-trader:latest .
	kind load docker-image crypto-tracker-trader:latest --name ctt-cluster
	@echo "Applying Kubernetes manifests..."
	kubectl apply -f deployments/k8s/postgres.yaml
	kubectl apply -f deployments/k8s/redis.yaml
	kubectl apply -f deployments/k8s/kafka.yaml
	kubectl apply -f deployments/k8s/prometheus.yaml
	kubectl apply -f deployments/k8s/grafana.yaml
	kubectl apply -f deployments/k8s/grafana-dashboards.yaml
	kubectl apply -f deployments/k8s/redis-exporter.yaml
	kubectl apply -f deployments/k8s/kafka-exporter.yaml
	kubectl apply -f deployments/k8s/postgres-exporter.yaml
	kubectl apply -f deployments/k8s/otel-collector.yaml
	kubectl apply -f deployments/k8s/tempo.yaml
	kubectl apply -f deployments/k8s/app.yaml
	@echo "Waiting for pods to be ready..."
	kubectl wait --for=condition=ready pod -l app=postgres -n ctt-dev --timeout=120s
	kubectl wait --for=condition=ready pod -l app=redis -n ctt-dev --timeout=120s
	kubectl wait --for=condition=ready pod -l app=kafka -n ctt-dev --timeout=120s
	kubectl wait --for=condition=ready pod -l app=prometheus -n ctt-dev --timeout=120s
	kubectl wait --for=condition=ready pod -l app=grafana -n ctt-dev --timeout=120s
	kubectl wait --for=condition=ready pod -l app=crypto-tracker-app -n ctt-dev --timeout=120s
	@echo "Deployment complete!"

k8s-status:
	@echo "=== Pods ==="
	@kubectl get pods -n ctt-dev
	@echo ""
	@echo "=== Services ==="
	@kubectl get svc -n ctt-dev
	@echo ""
	@echo "=== Deployments ==="
	@kubectl get deployments -n ctt-dev

k8s-logs-app:
	kubectl logs -f deployment/crypto-tracker-app -n ctt-dev

k8s-logs-postgres:
	kubectl logs -f deployment/postgres -n ctt-dev

k8s-delete:
	kubectl delete namespace ctt-dev --ignore-not-found

# Port-forward all services
port-forward:
	@./scripts/port-forward.sh

# Full setup (Terraform + K8s)
setup: tf-init tf-apply k8s-deploy
	@echo "Setup complete! Run 'make port-forward' to access services."

# Teardown
teardown: tf-destroy
	@echo "Teardown complete!"

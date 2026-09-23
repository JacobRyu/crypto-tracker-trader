#!/bin/bash

# Port-forward all services in ctt-dev namespace
# Usage: ./scripts/port-forward.sh

set -e

echo "Starting port-forwarding for ctt-dev services..."
echo ""

# Kill existing port-forward processes
pkill -f "kubectl port-forward.*ctt-dev" 2>/dev/null || true
sleep 1

# App
kubectl port-forward -n ctt-dev svc/crypto-tracker-app 8081:8080 > /dev/null 2>&1 &
echo "App:        http://localhost:8081"

# PostgreSQL
kubectl port-forward -n ctt-dev svc/postgres 5432:5432 > /dev/null 2>&1 &
echo "PostgreSQL: localhost:5432"

# Redis
kubectl port-forward -n ctt-dev svc/redis 6379:6379 > /dev/null 2>&1 &
echo "Redis:      localhost:6379"

# Kafka
kubectl port-forward -n ctt-dev svc/kafka 9092:9092 > /dev/null 2>&1 &
echo "Kafka:      localhost:9092"

# Prometheus
kubectl port-forward -n ctt-dev svc/prometheus 9090:9090 > /dev/null 2>&1 &
echo "Prometheus: http://localhost:9090"

# Grafana
kubectl port-forward -n ctt-dev svc/grafana 3000:3000 > /dev/null 2>&1 &
echo "Grafana:    http://localhost:3000"

echo ""
echo "All services port-forwarded. Press Ctrl+C to stop."
wait

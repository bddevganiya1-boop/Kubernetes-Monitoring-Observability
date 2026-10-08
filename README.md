# 🚀 Kubernetes Monitoring & Observability Stack

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.29-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Kind](https://img.shields.io/badge/Kind-Multi--Node-blue?logo=docker&logoColor=white)](https://kind.sigs.k8s.io/)
[![Helm](https://img.shields.io/badge/Helm-v3-0F1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Operator-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-v10-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, end-to-end **Monitoring and Observability Stack** deployed on a local multi-node Kubernetes cluster using **Kind**, **Helm**, **Prometheus Operator (`kube-prometheus-stack`)**, and **Grafana**. 

This repository demonstrates modern cloud-native observability patterns: declarative cluster provisioning, automated metrics scraping with Custom Resource Definitions (`ServiceMonitor`), custom application instrumentation, proactive alert rules (`PrometheusRule`), automated Grafana dashboard provisioning via sidecars, and synthetic load generation.

---

## 📑 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Key Features](#-key-features)
- [Repository Structure](#-repository-structure)
- [Prerequisites](#-prerequisites)
- [Step-by-Step Deployment Workflow](#-step-by-step-deployment-workflow)
  - [Step 1: Provision Multi-Node Kind Cluster](#step-1-provision-multi-node-kind-cluster)
  - [Step 2: Deploy Monitoring Stack via Helm](#step-2-deploy-monitoring-stack-via-helm)
  - [Step 3: Deploy Instrumentated Application & Load Generator](#step-3-deploy-instrumentated-application--load-generator)
  - [Step 4: Configure ServiceMonitor & Alerting Rules](#step-4-configure-servicemonitor--alerting-rules)
  - [Step 5: Verify Dashboards & Metrics Ingestion](#step-5-verify-dashboards--metrics-ingestion)
- [Service Access & Port Matrix](#-service-access--port-matrix)
- [Key Metrics & PromQL Reference](#-key-metrics--promql-reference)
- [Simulating Alerts & Traffic](#-simulating-alerts--traffic)
- [Troubleshooting & Verification](#-troubleshooting--verification)
- [Teardown](#-teardown)

---

## 🏛️ Architecture Overview

```
                      ┌─────────────────────────────────────────────────────────┐
                      │                   Kind Kubernetes Cluster               │
                      │                                                         │
   [Localhost]        │  ┌───────────────────────┐   ┌────────────────────────┐ │
   :30000 ───────────┼─►│  Grafana Dashboard    │◄──│ Prometheus Server      │ │
                      │  │  (Custom JSON Models) │   │ (Scrapes Time Series)  │ │
   :30090 ───────────┼─►│                        │   │                        │ │
                      │  └───────────────────────┘   └───────────▲────────────┘ │
   :30093 ───────────┼─► Alertmanager                            │              │
                      │                                    Scrapes via          │
                      │                                  ServiceMonitor         │
                      │                                          │              │
                      │  ┌───────────────────────────────────────┴────────────┐ │
                      │  │                   Namespace: app                   │ │
   :30080 ───────────┼─►│  Frontend UI (Nginx) ──► Backend API (:8080)       │ │
   :30081 ───────────┼─►│                             └─► /metrics endpoint   │ │
                      │  │                                ▲                   │ │
                      │  │  Load Generator (cURL Job) ────┘                   │ │
                      │  └────────────────────────────────────────────────────┘ │
                      └─────────────────────────────────────────────────────────┘
```

### Observability Data Flow:
1. **Application Layer**: A multi-service application (Nginx Frontend + Python Flask API) serves traffic. The backend instrumented with `prometheus_client` exposes real-time runtime metrics on `/metrics`.
2. **Scraping Layer**: Prometheus Operator discovers the backend pods using a declarative `ServiceMonitor` Custom Resource.
3. **Storage & Evaluation**: Prometheus stores time-series data and evaluates `PrometheusRule` alerting thresholds (error rate > 5%, P95 latency > 500ms).
4. **Visualization Layer**: Grafana loads curated dashboards automatically through a Kubernetes ConfigMap sidecar watcher.
5. **Traffic Generation**: A synthetic load generator deployment simulates real-world user traffic patterns and latency variations.

---

## ✨ Key Features

- **Multi-Node Kind Topology**: 1 Control-plane node and 2 Worker nodes with pre-configured port mappings (`extraPortMappings`).
- **Production-Ready Helm Values**: Configured `kube-prometheus-stack` with open CRD discovery selectors across all namespaces.
- **Declarative Custom Resources**:
  - `ServiceMonitor`: Target discovery and endpoint scraping automation.
  - `PrometheusRule`: Multi-tier alerts (latency degradation, error spikes, pod restarts).
- **Zero-Manual-Import Grafana Provisioning**: Automated sidecar detection (`grafana_dashboard: "1"` label) for dashboard deployment.
- **Custom Application Metrics**:
  - `http_requests_total` (labeled by method, route, and HTTP status).
  - `http_request_duration_seconds` (latency histogram with percentile buckets).
  - `app_active_users` (gauge reflecting active connections).
  - `app_database_operation_duration_seconds` (simulated database latency).
- **Synthetic Load Generator**: Built-in background traffic generator creating 200 OKs, high latency, and 500 errors for real-time visualization.

---

## 📂 Repository Structure

```
Kubernetes-Monitoring-Observability/
├── .gitignore                                # Git ignore file
├── Makefile                                  # Automation targets for setup, testing, and teardown
├── README.md                                 # Project documentation
├── kind/
│   └── kind-cluster-config.yaml              # Kind 3-node cluster configuration with NodePorts
├── helm/
│   └── kube-prometheus-stack-values.yaml     # Custom values for Prometheus, Grafana & Alertmanager
├── manifests/
│   ├── app/
│   │   ├── 00-namespace.yaml                 # Dedicated 'app' namespace
│   │   ├── 01-backend.yaml                   # Backend API Deployment, Service, and ConfigMap
│   │   ├── 02-frontend.yaml                  # Frontend UI Deployment, Service, and ConfigMap
│   │   └── 03-load-generator.yaml            # Continuous synthetic traffic generator
│   └── monitoring/
│       ├── backend-service-monitor.yaml      # ServiceMonitor CRD for metric scraping
│       └── custom-alert-rules.yaml           # PrometheusRule CRD for alerting
├── dashboards/
│   ├── app-observability-dashboard.json      # Grafana dashboard model JSON
│   └── dashboard-configmap.yaml              # Auto-provisioned Grafana Dashboard ConfigMap
├── app-src/
│   ├── backend/
│   │   ├── app.py                            # Instrumented Python Flask microservice
│   │   ├── requirements.txt                  # Python dependencies
│   │   └── Dockerfile                        # Multi-stage Dockerfile
│   └── frontend/
│       ├── index.html                        # Sleek glassmorphic telemetry web UI
│       ├── nginx.conf                        # Reverse proxy configuration
│       └── Dockerfile                        # Nginx container definition
└── scripts/
    ├── setup-cluster.sh / .ps1               # Cluster provisioning script
    ├── install-monitoring.sh / .ps1          # Helm stack installation script
    ├── deploy-app.sh / .ps1                  # Application & monitor deployment script
    ├── port-forward.sh / .ps1                # Optional port forwarding script
    └── teardown.sh / .ps1                    # Cluster cleanup script
```

---

## 📋 Prerequisites

Before running the stack, ensure you have the following tools installed on your host system:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine (running)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (`>= v0.20.0`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (`>= v1.28.0`)
- [Helm](https://helm.sh/docs/intro/install/) (`>= v3.12.0`)
- [curl](https://curl.se/) & [jq](https://stedolan.github.io/jq/) (optional for testing)

---

## ⚡ Step-by-Step Deployment Workflow

You can execute the workflow using the provided **Makefile** or run the individual scripts/commands.

### Quick Start (Single Command)
```bash
make all
```

---

### Step 1: Provision Multi-Node Kind Cluster

Create a 3-node cluster (1 control-plane, 2 workers) with host port bindings:

```bash
# Using Makefile
make up

# Or using Bash
bash scripts/setup-cluster.sh

# Or using PowerShell (Windows)
.\scripts\setup-cluster.ps1
```

**Verify Cluster Nodes:**
```bash
kubectl get nodes -o wide
```

---

### Step 2: Deploy Monitoring Stack via Helm

Add the Prometheus Community repository and install `kube-prometheus-stack` with our tuned configuration:

```bash
# Using Makefile
make monitoring

# Or using Bash
bash scripts/install-monitoring.sh

# Or using PowerShell (Windows)
.\scripts\install-monitoring.ps1
```

**Verify Monitoring Pods:**
```bash
kubectl get pods -n monitoring
```
*Wait until all Prometheus, Grafana, Node-Exporter, and Operator pods are in `Running` state.*

---

### Step 3: Deploy Instrumentated Application & Load Generator

Deploy the `app` namespace, backend microservice with `/metrics`, frontend web UI, and the background synthetic traffic generator:

```bash
# Using Makefile
make app

# Or using Bash
bash scripts/deploy-app.sh

# Or using PowerShell (Windows)
.\scripts\deploy-app.ps1
```

**Verify Application Pods:**
```bash
kubectl get pods -n app
```

---

### Step 4: Configure ServiceMonitor & Alerting Rules

The deployment script automatically applies the CRDs in `manifests/monitoring/`. You can verify their status:

```bash
# Check custom ServiceMonitor
kubectl get servicemonitor -n app

# Check custom PrometheusRule
kubectl get prometheusrule -n app
```

---

### Step 5: Verify Dashboards & Metrics Ingestion

1. Open your browser and navigate to **Grafana**: [http://localhost:30000](http://localhost:30000)
   - **Username**: `admin`
   - **Password**: `admin`
2. Navigate to **Dashboards** ➔ **Application & Microservice Observability**.
3. You will see live real-time visualizations for request rates, latency percentiles, error rates, and resource utilization.

---

## 🌐 Service Access & Port Matrix

All core services are exposed via Kind port mappings directly on `localhost`:

| Service | Protocol | Host URL | Port Type | Credentials |
| :--- | :--- | :--- | :--- | :--- |
| **Grafana** | HTTP | [http://localhost:30000](http://localhost:30000) | NodePort | `admin` / `admin` |
| **Prometheus UI** | HTTP | [http://localhost:30090](http://localhost:30090) | NodePort | None |
| **Alertmanager UI** | HTTP | [http://localhost:30093](http://localhost:30093) | NodePort | None |
| **Frontend Web App** | HTTP | [http://localhost:30080](http://localhost:30080) | NodePort | None |
| **Backend API** | HTTP | [http://localhost:30081](http://localhost:30081) | NodePort | None |
| **Backend Metrics** | HTTP | [http://localhost:30081/metrics](http://localhost:30081/metrics) | NodePort | None |

---

## 🔍 Key Metrics & PromQL Reference

| Metric Purpose | PromQL Expression |
| :--- | :--- |
| **Total Request Throughput (RPS)** | `sum(rate(http_requests_total{namespace="app"}[1m]))` |
| **HTTP 5xx Error Rate (%)** | `(sum(rate(http_requests_total{namespace="app", http_status=~"5.."}[1m])) / sum(rate(http_requests_total{namespace="app"}[1m]))) * 100` |
| **P95 Latency (Seconds)** | `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace="app"}[1m])) by (le))` |
| **P99 Latency (Seconds)** | `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace="app"}[1m])) by (le))` |
| **Active Users (Gauge)** | `avg(app_active_users{namespace="app"})` |
| **Pod CPU Usage (Cores)** | `sum(rate(container_cpu_usage_seconds_total{namespace="app", container!=""}[1m])) by (pod)` |
| **Pod Memory Usage (Bytes)** | `sum(container_memory_working_set_bytes{namespace="app", container!=""}) by (pod)` |

---

## 🎯 Simulating Alerts & Traffic

You can trigger live HTTP events to observe alerting behavior and graph reactions:

### 1. Send High Latency Requests:
```bash
curl -i http://localhost:30080/api/slow
```
*Triggers the `BackendHighLatency` alert when P95 latency exceeds 500ms for > 1 minute.*

### 2. Send Error Requests (HTTP 500):
```bash
curl -i http://localhost:30080/api/error
```
*Triggers the `BackendHighErrorRate` alert when 5xx error rate exceeds 5%.*

### 3. Inspect Alerts:
- Visit **Prometheus Alerts**: [http://localhost:30090/alerts](http://localhost:30090/alerts)
- Visit **Alertmanager**: [http://localhost:30093](http://localhost:30093)

---

## 🛠️ Troubleshooting & Verification

### 1. Verify Prometheus Targets
Visit [http://localhost:30090/targets](http://localhost:30090/targets) and ensure `serviceMonitor/app/backend-service-monitor/0` is in the **UP (1/1)** state.

### 2. Verify Service Endpoints
```bash
kubectl get endpoints -n app backend-service
```
Ensure IP endpoints are listed.

### 3. Check Grafana Dashboard Sidecar Logs
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -c grafana-sc-dashboard --tail=50
```

---

## 🧹 Teardown

To cleanly delete the Kind cluster and release all local resources:

```bash
# Using Makefile
make down

# Or using Bash
bash scripts/teardown.sh

# Or using PowerShell (Windows)
.\scripts\teardown.ps1
```

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

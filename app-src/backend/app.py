import os
import time
import random
from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# ------------------------------------------------------------------------------
# Prometheus Metrics Definitions
# ------------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP Requests',
    ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP Request Duration in Seconds',
    ['endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
)

ACTIVE_USERS = Gauge(
    'app_active_users',
    'Current number of active users connected'
)

DATABASE_OPERATION_DURATION = Histogram(
    'app_database_operation_duration_seconds',
    'Simulated database latency in seconds',
    ['operation']
)

ERROR_COUNT = Counter(
    'app_errors_total',
    'Total application handled/unhandled errors',
    ['error_type']
)

# Initialize gauge with simulated active sessions
ACTIVE_USERS.set(random.randint(5, 25))

# ------------------------------------------------------------------------------
# Middleware / Hooks
# ------------------------------------------------------------------------------
@app.before_request
def before_request():
    request.start_time = time.time()
    # Fluctuate active user gauge slightly
    if random.random() < 0.3:
        ACTIVE_USERS.inc(random.randint(1, 3))
    elif random.random() < 0.3:
        ACTIVE_USERS.dec(max(1, random.randint(1, 3)))

@app.after_request
def after_request(response):
    if hasattr(request, 'start_time'):
        latency = time.time() - request.start_time
        endpoint = request.endpoint or 'unknown'
        REQUEST_LATENCY.labels(endpoint=endpoint).observe(latency)
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            http_status=response.status_code
        ).inc()
    return response

# ------------------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------------------
@app.route('/')
def root():
    return jsonify({
        "service": "backend-api",
        "status": "healthy",
        "version": "1.0.0",
        "endpoints": [
            "/api/data",
            "/api/slow",
            "/api/error",
            "/metrics",
            "/healthz"
        ]
    })

@app.route('/healthz')
def healthz():
    return jsonify({"status": "ok"}), 200

@app.route('/api/data')
def get_data():
    # Simulate database call with latency
    db_start = time.time()
    simulated_db_latency = random.uniform(0.01, 0.08)
    time.sleep(simulated_db_latency)
    DATABASE_OPERATION_DURATION.labels(operation='SELECT').observe(time.time() - db_start)

    # 5% chance of simulated downstream transient error
    if random.random() < 0.05:
        ERROR_COUNT.labels(error_type='database_timeout').inc()
        return jsonify({"error": "Database timeout simulated"}), 503

    return jsonify({
        "message": "Data retrieved successfully",
        "timestamp": time.time(),
        "cluster_node": os.getenv("NODE_NAME", "kind-worker"),
        "pod_name": os.getenv("POD_NAME", "backend-pod"),
        "items": [
            {"id": 1, "item": "Kubernetes Cluster Telemetry", "status": "active"},
            {"id": 2, "item": "Prometheus Time Series Engine", "status": "active"},
            {"id": 3, "item": "Grafana Dashboards & Alerts", "status": "active"}
        ]
    }), 200

@app.route('/api/slow')
def slow_request():
    """Simulates high latency endpoint for alerting verification."""
    sleep_time = random.uniform(0.8, 2.2)
    time.sleep(sleep_time)
    return jsonify({
        "message": f"Simulated slow response after {sleep_time:.2f}s",
        "latency_seconds": sleep_time
    }), 200

@app.route('/api/error')
def trigger_error():
    """Simulates 500 internal server error for alerting."""
    ERROR_COUNT.labels(error_type='internal_server_error').inc()
    return jsonify({
        "error": "Internal server error triggered for observability testing",
        "code": 500
    }), 500

@app.route('/metrics')
def metrics():
    """Prometheus scraping endpoint."""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8080))
    app.run(host='0.0.0.0', port=port)

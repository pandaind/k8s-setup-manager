#!/bin/bash

# Kubernetes Local Management Script for Ubuntu
# Author: Generated for local K8s management
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="local-k8s"
KUBECONFIG_PATH="$HOME/.kube/config"
MINIKUBE_DRIVER="docker"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install prerequisites
install_prerequisites() {
    log "Installing prerequisites..."
    
    # Update package list
    sudo apt update
    
    # Install Docker if not present
    if ! command_exists docker; then
        log "Installing Docker..."
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        warn "You may need to logout and login again for Docker group changes to take effect"
    fi
    
    # Install kubectl if not present
    if ! command_exists kubectl; then
        log "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # Install minikube if not present
    if ! command_exists minikube; then
        log "Installing minikube..."
        curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        chmod +x minikube
        sudo mv minikube /usr/local/bin/
    fi
    
    # Install helm if not present
    if ! command_exists helm; then
        log "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Install k9s for cluster monitoring (optional but very useful)
    if ! command_exists k9s; then
        log "Installing k9s (Kubernetes CLI manager)..."
        curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar xz -C /tmp
        sudo mv /tmp/k9s /usr/local/bin/
    fi
    
    log "Prerequisites installation completed!"
}

# Start Kubernetes cluster
start_cluster() {
    log "Starting Kubernetes cluster..."
    
    if minikube status >/dev/null 2>&1; then
        info "Minikube cluster is already running"
        return
    fi
    
    minikube start --driver=$MINIKUBE_DRIVER --cpus=2 --memory=2048
    
    # Wait for cluster to be ready
    log "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log "Kubernetes cluster started successfully!"
    show_status
}

# Stop Kubernetes cluster
stop_cluster() {
    log "Stopping Kubernetes cluster..."
    
    if ! minikube status >/dev/null 2>&1; then
        info "Minikube cluster is not running"
        return
    fi
    
    minikube stop
    log "Kubernetes cluster stopped successfully!"
}

# Delete/Destroy cluster
delete_cluster() {
    read -p "Are you sure you want to delete the entire cluster? This cannot be undone. (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Deleting Kubernetes cluster..."
        minikube delete
        log "Kubernetes cluster deleted successfully!"
    else
        info "Cluster deletion cancelled"
    fi
}

# Show cluster status
show_status() {
    log "Kubernetes Cluster Status:"
    echo
    
    # Minikube status
    info "Minikube Status:"
    minikube status || echo "Minikube not running"
    echo
    
    # Node status
    if kubectl cluster-info >/dev/null 2>&1; then
        info "Nodes:"
        kubectl get nodes -o wide
        echo
        
        info "Cluster Info:"
        kubectl cluster-info
        echo
        
        info "System Pods:"
        kubectl get pods -n kube-system
        echo
        
        info "All Namespaces:"
        kubectl get namespaces
        echo
    else
        warn "Cluster is not accessible"
    fi
}

# Create namespace
create_namespace() {
    if [ -z "$1" ]; then
        error "Please provide a namespace name"
    fi
    
    log "Creating namespace: $1"
    kubectl create namespace "$1" || warn "Namespace might already exist"
    log "Namespace $1 created successfully!"
}

# Delete namespace
delete_namespace() {
    if [ -z "$1" ]; then
        error "Please provide a namespace name"
    fi
    
    read -p "Are you sure you want to delete namespace '$1'? This will delete all resources in it. (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Deleting namespace: $1"
        kubectl delete namespace "$1"
        log "Namespace $1 deleted successfully!"
    else
        info "Namespace deletion cancelled"
    fi
}

# Deploy application from YAML
deploy_app() {
    if [ -z "$1" ]; then
        error "Please provide a YAML file path"
    fi
    
    if [ ! -f "$1" ]; then
        error "File $1 not found"
    fi
    
    log "Deploying application from $1"
    kubectl apply -f "$1"
    log "Application deployed successfully!"
}

# Delete application from YAML
delete_app() {
    if [ -z "$1" ]; then
        error "Please provide a YAML file path"
    fi
    
    if [ ! -f "$1" ]; then
        error "File $1 not found"
    fi
    
    log "Deleting application from $1"
    kubectl delete -f "$1"
    log "Application deleted successfully!"
}

# Get all resources
get_all_resources() {
    local namespace=${1:-"default"}
    log "Getting all resources in namespace: $namespace"
    kubectl get all -n "$namespace" -o wide
}

# Scale deployment
scale_deployment() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        error "Usage: scale_deployment <deployment-name> <replicas> [namespace]"
    fi
    
    local deployment=$1
    local replicas=$2
    local namespace=${3:-"default"}
    
    log "Scaling deployment $deployment to $replicas replicas in namespace $namespace"
    kubectl scale deployment "$deployment" --replicas="$replicas" -n "$namespace"
    log "Deployment scaled successfully!"
}

# Port forward
port_forward() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        error "Usage: port_forward <service-name> <local-port:service-port> [namespace]"
    fi
    
    local service=$1
    local ports=$2
    local namespace=${3:-"default"}
    
    log "Port forwarding $service ($ports) in namespace $namespace"
    log "Press Ctrl+C to stop port forwarding"
    kubectl port-forward service/"$service" "$ports" -n "$namespace"
}

# Get logs
get_logs() {
    if [ -z "$1" ]; then
        error "Usage: get_logs <pod-name> [namespace] [follow]"
    fi
    
    local pod=$1
    local namespace=${2:-"default"}
    local follow_flag=""
    
    if [ "$3" = "follow" ] || [ "$3" = "-f" ]; then
        follow_flag="-f"
    fi
    
    log "Getting logs for pod $pod in namespace $namespace"
    kubectl logs "$pod" -n "$namespace" $follow_flag
}

# Execute command in pod
exec_pod() {
    if [ -z "$1" ]; then
        error "Usage: exec_pod <pod-name> [namespace] [command]"
    fi
    
    local pod=$1
    local namespace=${2:-"default"}
    local command=${3:-"/bin/bash"}
    
    log "Executing command in pod $pod"
    kubectl exec -it "$pod" -n "$namespace" -- $command
}

# Individual monitoring components
deploy_prometheus() {
    log "Installing Prometheus..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring || warn "Monitoring namespace might already exist"
    
    # Install Prometheus only
    helm upgrade --install prometheus prometheus-community/prometheus \
        --namespace monitoring \
        --set prometheus.prometheusSpec.retention=7d \
        --set grafana.enabled=false \
        --set alertmanager.enabled=false
    
    log "Prometheus installed successfully!"
    info "Access Prometheus: kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
}

deploy_grafana() {
    log "Installing Grafana..."
    
    # Add Grafana Helm repository
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring || warn "Monitoring namespace might already exist"
    
    # Install Grafana
    helm upgrade --install grafana grafana/grafana \
        --namespace monitoring \
        --set adminPassword=admin123 \
        --set service.type=ClusterIP
    
    log "Grafana installed successfully!"
    info "Username: admin, Password: admin123"
    info "Access Grafana: kubectl port-forward -n monitoring svc/grafana 3000:80"
}

deploy_kiali() {
    log "Installing Kiali for Istio observability..."
    
    # Create istio-system namespace if not exists
    kubectl create namespace istio-system || warn "istio-system namespace might already exist"
    
    # Install Kiali operator
    helm repo add kiali https://kiali.org/helm-charts
    helm repo update
    
    helm upgrade --install kiali-operator kiali/kiali-operator \
        --namespace kiali-operator \
        --create-namespace \
        --set cr.create=true \
        --set cr.namespace=istio-system
    
    log "Kiali installed successfully!"
    info "Access Kiali: kubectl port-forward -n istio-system svc/kiali 20001:20001"
}

deploy_jaeger() {
    log "Installing Jaeger for distributed tracing..."
    
    kubectl create namespace observability || warn "observability namespace might already exist"
    
    # Install Jaeger all-in-one
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.48
        env:
        - name: COLLECTOR_OTLP_ENABLED
          value: "true"
        ports:
        - containerPort: 16686
        - containerPort: 14268
        - containerPort: 6831
        - containerPort: 6832
        - containerPort: 5778
        - containerPort: 4317
        - containerPort: 4318
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger
  namespace: observability
spec:
  selector:
    app: jaeger
  ports:
  - name: query-http
    port: 16686
    targetPort: 16686
  - name: collector-http
    port: 14268
    targetPort: 14268
  - name: collector-grpc
    port: 4317
    targetPort: 4317
  - name: collector-http-thrift
    port: 4318
    targetPort: 4318
  type: ClusterIP
EOF
    
    log "Jaeger installed successfully!"
    info "Access Jaeger UI: kubectl port-forward -n observability svc/jaeger 16686:16686"
}

deploy_litmus() {
    log "Installing Litmus for chaos engineering..."
    
    # Add Litmus Helm repository
    helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/
    helm repo update
    
    # Create litmus namespace
    kubectl create namespace litmus || warn "litmus namespace might already exist"
    
    # Install Litmus
    helm upgrade --install litmus litmuschaos/litmus \
        --namespace litmus \
        --set portal.frontend.service.type=ClusterIP
    
    log "Litmus installed successfully!"
    info "Access Litmus Portal: kubectl port-forward -n litmus svc/litmusportal-frontend-service 9091:9091"
    info "Default credentials: admin/litmus"
}

# Enable monitoring (Prometheus & Grafana)
enable_monitoring() {
    log "Installing Prometheus and Grafana monitoring stack..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring || warn "Monitoring namespace might already exist"
    
    # Install Prometheus
    log "Installing Prometheus..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set grafana.adminPassword=admin123 \
        --set prometheus.prometheusSpec.retention=7d
    
    log "Monitoring stack installed successfully!"
    info "Grafana admin password: admin123"
    info "To access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    info "To access Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
}

# Enable Istio service mesh
enable_istio() {
    log "Installing Istio service mesh..."
    
    # Download Istio
    if [ ! -d "istio-*" ]; then
        curl -L https://istio.io/downloadIstio | sh -
    fi
    
    # Find Istio directory
    ISTIO_DIR=$(find . -name "istio-*" -type d | head -1)
    if [ -z "$ISTIO_DIR" ]; then
        error "Istio installation failed"
    fi
    
    # Add istioctl to PATH
    export PATH=$PWD/$ISTIO_DIR/bin:$PATH
    
    # Install Istio
    istioctl install --set values.defaultRevision=default -y
    
    # Enable automatic sidecar injection for default namespace
    kubectl label namespace default istio-injection=enabled --overwrite
    
    log "Istio installed successfully!"
    info "To access Kiali dashboard: kubectl port-forward -n istio-system svc/kiali 20001:20001"
}

# Setup local Docker registry
setup_registry() {
    log "Setting up local Docker registry..."
    
    # Create registry namespace
    kubectl create namespace registry || warn "Registry namespace might already exist"
    
    # Create registry deployment
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        env:
        - name: REGISTRY_STORAGE_DELETE_ENABLED
          value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry
spec:
  selector:
    app: registry
  ports:
  - port: 5000
    targetPort: 5000
  type: NodePort
EOF
    
    log "Local Docker registry setup completed!"
    info "Registry will be available at: minikube ip:$(kubectl get svc -n registry registry -o jsonpath='{.spec.ports[0].nodePort}')"
}

# Individual component deployment functions
deploy_redis() {
    local namespace=${1:-"development"}
    log "Deploying Redis to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $namespace
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
EOF
    
    log "Redis deployed successfully!"
    info "Connection: redis.$namespace.svc.cluster.local:6379"
}

deploy_minio() {
    local namespace=${1:-"development"}
    log "Deploying MinIO to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /data
        - --console-address
        - ":9001"
        env:
        - name: MINIO_ROOT_USER
          value: admin
        - name: MINIO_ROOT_PASSWORD
          value: password123
        ports:
        - containerPort: 9000
        - containerPort: 9001
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: $namespace
spec:
  selector:
    app: minio
  ports:
  - name: api
    port: 9000
    targetPort: 9000
  - name: console
    port: 9001
    targetPort: 9001
  type: ClusterIP
EOF
    
    log "MinIO deployed successfully!"
    info "API: minio.$namespace.svc.cluster.local:9000 (admin/password123)"
    info "Console: kubectl port-forward -n $namespace svc/minio 9001:9001"
}

deploy_postgresql() {
    local namespace=${1:-"development"}
    log "Deploying PostgreSQL to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: devdb
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: password123
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: $namespace
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
    
    log "PostgreSQL deployed successfully!"
    info "Connection: postgresql.$namespace.svc.cluster.local:5432"
    info "Database: devdb, User: admin, Password: password123"
}

deploy_mongodb() {
    local namespace=${1:-"development"}
    log "Deploying MongoDB to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: admin
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: password123
        ports:
        - containerPort: 27017
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: $namespace
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
EOF
    
    log "MongoDB deployed successfully!"
    info "Connection: mongodb.$namespace.svc.cluster.local:27017"
    info "User: admin, Password: password123"
}

deploy_mysql() {
    local namespace=${1:-"development"}
    log "Deploying MySQL to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password123
        - name: MYSQL_DATABASE
          value: devdb
        - name: MYSQL_USER
          value: admin
        - name: MYSQL_PASSWORD
          value: password123
        ports:
        - containerPort: 3306
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: $namespace
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
EOF
    
    log "MySQL deployed successfully!"
    info "Connection: mysql.$namespace.svc.cluster.local:3306"
    info "Database: devdb, User: admin/root, Password: password123"
}

deploy_cassandra() {
    local namespace=${1:-"development"}
    log "Deploying Cassandra to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
  namespace: $namespace
spec:
  serviceName: cassandra
  replicas: 1
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: cassandra
        image: cassandra:4
        env:
        - name: CASSANDRA_CLUSTER_NAME
          value: "DevCluster"
        - name: CASSANDRA_DC
          value: "datacenter1"
        - name: CASSANDRA_RACK
          value: "rack1"
        ports:
        - containerPort: 9042
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: cassandra
  namespace: $namespace
spec:
  clusterIP: None
  selector:
    app: cassandra
  ports:
  - port: 9042
    targetPort: 9042
EOF
    
    log "Cassandra deployed successfully!"
    info "Connection: cassandra.$namespace.svc.cluster.local:9042"
    warn "Cassandra may take several minutes to fully initialize"
}

deploy_kafka() {
    local namespace=${1:-"development"}
    log "Deploying Kafka with Zookeeper to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    # Deploy Zookeeper first
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zookeeper
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      containers:
      - name: zookeeper
        image: confluentinc/cp-zookeeper:7.4.0
        env:
        - name: ZOOKEEPER_CLIENT_PORT
          value: "2181"
        - name: ZOOKEEPER_TICK_TIME
          value: "2000"
        ports:
        - containerPort: 2181
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper
  namespace: $namespace
spec:
  selector:
    app: zookeeper
  ports:
  - port: 2181
    targetPort: 2181
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.4.0
        env:
        - name: KAFKA_BROKER_ID
          value: "1"
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper:2181"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: "PLAINTEXT://kafka:9092"
        - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
          value: "1"
        - name: KAFKA_AUTO_CREATE_TOPICS_ENABLE
          value: "true"
        ports:
        - containerPort: 9092
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: $namespace
spec:
  selector:
    app: kafka
  ports:
  - port: 9092
    targetPort: 9092
EOF
    
    log "Kafka with Zookeeper deployed successfully!"
    info "Kafka: kafka.$namespace.svc.cluster.local:9092"
    info "Zookeeper: zookeeper.$namespace.svc.cluster.local:2181"
}

deploy_rabbitmq() {
    local namespace=${1:-"development"}
    log "Deploying RabbitMQ to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3-management
        env:
        - name: RABBITMQ_DEFAULT_USER
          value: admin
        - name: RABBITMQ_DEFAULT_PASS
          value: password123
        ports:
        - containerPort: 5672
        - containerPort: 15672
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: $namespace
spec:
  selector:
    app: rabbitmq
  ports:
  - name: amqp
    port: 5672
    targetPort: 5672
  - name: management
    port: 15672
    targetPort: 15672
EOF
    
    log "RabbitMQ deployed successfully!"
    info "AMQP: rabbitmq.$namespace.svc.cluster.local:5672 (admin/password123)"
    info "Management UI: kubectl port-forward -n $namespace svc/rabbitmq 15672:15672"
}

deploy_zookeeper() {
    local namespace=${1:-"development"}
    log "Deploying standalone Zookeeper to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zookeeper-standalone
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper-standalone
  template:
    metadata:
      labels:
        app: zookeeper-standalone
    spec:
      containers:
      - name: zookeeper
        image: confluentinc/cp-zookeeper:7.4.0
        env:
        - name: ZOOKEEPER_CLIENT_PORT
          value: "2181"
        - name: ZOOKEEPER_TICK_TIME
          value: "2000"
        - name: ZOOKEEPER_SERVER_ID
          value: "1"
        ports:
        - containerPort: 2181
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper-standalone
  namespace: $namespace
spec:
  selector:
    app: zookeeper-standalone
  ports:
  - port: 2181
    targetPort: 2181
EOF
    
    log "Standalone Zookeeper deployed successfully!"
    info "Connection: zookeeper-standalone.$namespace.svc.cluster.local:2181"
}

deploy_weaviate() {
    local namespace=${1:-"development"}
    log "Deploying Weaviate to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weaviate
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: weaviate
  template:
    metadata:
      labels:
        app: weaviate
    spec:
      containers:
      - name: weaviate
        image: semitechnologies/weaviate:1.21.2
        env:
        - name: QUERY_DEFAULTS_LIMIT
          value: "25"
        - name: AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED
          value: "true"
        - name: PERSISTENCE_DATA_PATH
          value: "/var/lib/weaviate"
        - name: DEFAULT_VECTORIZER_MODULE
          value: "none"
        - name: CLUSTER_HOSTNAME
          value: "node1"
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: weaviate
  namespace: $namespace
spec:
  selector:
    app: weaviate
  ports:
  - port: 8080
    targetPort: 8080
EOF
    
    log "Weaviate deployed successfully!"
    info "API: weaviate.$namespace.svc.cluster.local:8080"
    info "GraphQL endpoint: http://weaviate.$namespace.svc.cluster.local:8080/v1/graphql"
}

deploy_qdrant() {
    local namespace=${1:-"development"}
    log "Deploying Qdrant to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qdrant
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qdrant
  template:
    metadata:
      labels:
        app: qdrant
    spec:
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        ports:
        - containerPort: 6333
        - containerPort: 6334
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: $namespace
spec:
  selector:
    app: qdrant
  ports:
  - name: http
    port: 6333
    targetPort: 6333
  - name: grpc
    port: 6334
    targetPort: 6334
EOF
    
    log "Qdrant deployed successfully!"
    info "HTTP API: qdrant.$namespace.svc.cluster.local:6333"
    info "gRPC API: qdrant.$namespace.svc.cluster.local:6334"
}

deploy_elasticsearch() {
    local namespace=${1:-"development"}
    log "Deploying Elasticsearch to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.9.0
        env:
        - name: discovery.type
          value: single-node
        - name: xpack.security.enabled
          value: "false"
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        - name: cluster.name
          value: "dev-cluster"
        - name: node.name
          value: "dev-node"
        ports:
        - containerPort: 9200
        - containerPort: 9300
        resources:
          requests:
            memory: "1Gi"
            cpu: "200m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: $namespace
spec:
  selector:
    app: elasticsearch
  ports:
  - name: http
    port: 9200
    targetPort: 9200
  - name: transport
    port: 9300
    targetPort: 9300
EOF
    
    log "Elasticsearch deployed successfully!"
    info "HTTP API: elasticsearch.$namespace.svc.cluster.local:9200"
    info "Transport: elasticsearch.$namespace.svc.cluster.local:9300"
    warn "Elasticsearch may take several minutes to fully initialize"
}

deploy_memcached() {
    local namespace=${1:-"development"}
    log "Deploying Memcached to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memcached
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memcached
  template:
    metadata:
      labels:
        app: memcached
    spec:
      containers:
      - name: memcached
        image: memcached:1.6-alpine
        ports:
        - containerPort: 11211
        args:
        - -m 128
        - -p 11211
        - -v
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: memcached
  namespace: $namespace
spec:
  selector:
    app: memcached
  ports:
  - port: 11211
    targetPort: 11211
  type: ClusterIP
EOF
    
    log "Memcached deployed successfully!"
    info "Connection: memcached.$namespace.svc.cluster.local:11211"
}

deploy_hazelcast() {
    local namespace=${1:-"development"}
    log "Deploying Hazelcast to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hazelcast
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hazelcast
  template:
    metadata:
      labels:
        app: hazelcast
    spec:
      containers:
      - name: hazelcast
        image: hazelcast/hazelcast:5.3
        env:
        - name: HZ_CLUSTERNAME
          value: "dev-cluster"
        - name: JAVA_OPTS
          value: "-Xmx512m -Xms512m"
        ports:
        - containerPort: 5701
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: hazelcast
  namespace: $namespace
spec:
  selector:
    app: hazelcast
  ports:
  - port: 5701
    targetPort: 5701
  type: ClusterIP
EOF
    
    log "Hazelcast deployed successfully!"
    info "Connection: hazelcast.$namespace.svc.cluster.local:5701"
    info "Management Center: kubectl port-forward -n $namespace svc/hazelcast 8080:5701"
}

deploy_influxdb() {
    local namespace=${1:-"development"}
    log "Deploying InfluxDB to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: influxdb
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: influxdb
  template:
    metadata:
      labels:
        app: influxdb
    spec:
      containers:
      - name: influxdb
        image: influxdb:2.7-alpine
        env:
        - name: DOCKER_INFLUXDB_INIT_MODE
          value: setup
        - name: DOCKER_INFLUXDB_INIT_USERNAME
          value: admin
        - name: DOCKER_INFLUXDB_INIT_PASSWORD
          value: password123
        - name: DOCKER_INFLUXDB_INIT_ORG
          value: myorg
        - name: DOCKER_INFLUXDB_INIT_BUCKET
          value: mybucket
        - name: DOCKER_INFLUXDB_INIT_ADMIN_TOKEN
          value: mytoken123
        ports:
        - containerPort: 8086
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: influxdb
  namespace: $namespace
spec:
  selector:
    app: influxdb
  ports:
  - port: 8086
    targetPort: 8086
  type: ClusterIP
EOF
    
    log "InfluxDB deployed successfully!"
    info "HTTP API: influxdb.$namespace.svc.cluster.local:8086"
    info "Username: admin, Password: password123"
    info "Organization: myorg, Bucket: mybucket, Token: mytoken123"
}

deploy_artemis() {
    local namespace=${1:-"development"}
    log "Deploying ActiveMQ Artemis to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: artemis
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: artemis
  template:
    metadata:
      labels:
        app: artemis
    spec:
      containers:
      - name: artemis
        image: apache/activemq-artemis:2.31.2
        env:
        - name: ARTEMIS_USER
          value: admin
        - name: ARTEMIS_PASSWORD
          value: password123
        - name: ANONYMOUS_LOGIN
          value: "false"
        - name: EXTRA_ARGS
          value: "--http-host 0.0.0.0 --relax-jolokia"
        ports:
        - containerPort: 61616  # Core protocol
        - containerPort: 5672   # AMQP
        - containerPort: 1883   # MQTT
        - containerPort: 61613  # STOMP
        - containerPort: 8161   # Web console
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: artemis
  namespace: $namespace
spec:
  selector:
    app: artemis
  ports:
  - name: core
    port: 61616
    targetPort: 61616
  - name: amqp
    port: 5672
    targetPort: 5672
  - name: mqtt
    port: 1883
    targetPort: 1883
  - name: stomp
    port: 61613
    targetPort: 61613
  - name: console
    port: 8161
    targetPort: 8161
  type: ClusterIP
EOF
    
    log "ActiveMQ Artemis deployed successfully!"
    info "Core protocol: artemis.$namespace.svc.cluster.local:61616"
    info "AMQP: artemis.$namespace.svc.cluster.local:5672"
    info "MQTT: artemis.$namespace.svc.cluster.local:1883"
    info "STOMP: artemis.$namespace.svc.cluster.local:61613"
    info "Web Console: kubectl port-forward -n $namespace svc/artemis 8161:8161"
    info "Username: admin, Password: password123"
}

deploy_pulsar() {
    local namespace=${1:-"development"}
    log "Deploying Apache Pulsar to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pulsar
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pulsar
  template:
    metadata:
      labels:
        app: pulsar
    spec:
      containers:
      - name: pulsar
        image: apachepulsar/pulsar:3.1.0
        command:
        - /bin/bash
        - -c
        - |
          bin/apply-config-from-env.py conf/standalone.conf &&
          bin/pulsar standalone --no-functions-worker --no-stream-storage
        env:
        - name: PULSAR_MEM
          value: "-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m"
        ports:
        - containerPort: 6650  # Pulsar protocol
        - containerPort: 8080  # HTTP
        resources:
          requests:
            memory: "1Gi"
            cpu: "200m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: pulsar
  namespace: $namespace
spec:
  selector:
    app: pulsar
  ports:
  - name: pulsar
    port: 6650
    targetPort: 6650
  - name: http
    port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    
    log "Apache Pulsar deployed successfully!"
    info "Pulsar protocol: pulsar.$namespace.svc.cluster.local:6650"
    info "HTTP API: pulsar.$namespace.svc.cluster.local:8080"
    warn "Pulsar may take several minutes to fully initialize"
}

deploy_opensearch() {
    local namespace=${1:-"development"}
    log "Deploying OpenSearch to namespace: $namespace"
    
    kubectl create namespace "$namespace" 2>/dev/null || warn "Namespace might already exist"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensearch
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opensearch
  template:
    metadata:
      labels:
        app: opensearch
    spec:
      containers:
      - name: opensearch
        image: opensearchproject/opensearch:2.11.0
        env:
        - name: discovery.type
          value: single-node
        - name: plugins.security.disabled
          value: "true"
        - name: OPENSEARCH_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        - name: cluster.name
          value: "dev-cluster"
        - name: node.name
          value: "dev-node"
        ports:
        - containerPort: 9200
        - containerPort: 9300
        resources:
          requests:
            memory: "1Gi"
            cpu: "200m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: opensearch
  namespace: $namespace
spec:
  selector:
    app: opensearch
  ports:
  - name: http
    port: 9200
    targetPort: 9200
  - name: transport
    port: 9300
    targetPort: 9300
EOF
    
    log "OpenSearch deployed successfully!"
    info "HTTP API: opensearch.$namespace.svc.cluster.local:9200"
    info "Transport: opensearch.$namespace.svc.cluster.local:9300"
    warn "OpenSearch may take several minutes to fully initialize"
}

# Create development environment
create_dev_env() {
    local namespace=${1:-"development"}
    log "Creating development environment in namespace: $namespace"
    
    # Create namespace
    kubectl create namespace "$namespace" || warn "Namespace might already exist"
    
    # Redis
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $namespace
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
EOF
    
    # PostgreSQL
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: devdb
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: password123
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: $namespace
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
EOF
    
    # MinIO (S3-compatible storage)
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /data
        - --console-address
        - ":9001"
        env:
        - name: MINIO_ROOT_USER
          value: admin
        - name: MINIO_ROOT_PASSWORD
          value: password123
        ports:
        - containerPort: 9000
        - containerPort: 9001
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: $namespace
spec:
  selector:
    app: minio
  ports:
  - name: api
    port: 9000
    targetPort: 9000
  - name: console
    port: 9001
    targetPort: 9001
EOF
    
    log "Development environment created successfully!"
    info "Redis: redis.$namespace.svc.cluster.local:6379"
    info "PostgreSQL: postgres.$namespace.svc.cluster.local:5432 (user: admin, password: password123)"
    info "MinIO API: minio.$namespace.svc.cluster.local:9000 (admin/password123)"
    info "MinIO Console: kubectl port-forward -n $namespace svc/minio 9001:9001"
}

# Create database environment
create_database_env() {
    local namespace=${1:-"databases"}
    log "Creating extended database environment in namespace: $namespace"
    
    # Create namespace
    kubectl create namespace "$namespace" || warn "Namespace might already exist"
    
    # MongoDB
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: admin
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: password123
        ports:
        - containerPort: 27017
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: $namespace
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
EOF
    
    # MySQL
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password123
        - name: MYSQL_DATABASE
          value: testdb
        ports:
        - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: $namespace
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF
    
    # Cassandra
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
  namespace: $namespace
spec:
  serviceName: cassandra
  replicas: 1
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: cassandra
        image: cassandra:4
        env:
        - name: CASSANDRA_CLUSTER_NAME
          value: "DevCluster"
        ports:
        - containerPort: 9042
---
apiVersion: v1
kind: Service
metadata:
  name: cassandra
  namespace: $namespace
spec:
  clusterIP: None
  selector:
    app: cassandra
  ports:
  - port: 9042
    targetPort: 9042
EOF
    
    log "Database environment created successfully!"
    info "MongoDB: mongodb.$namespace.svc.cluster.local:27017 (admin/password123)"
    info "MySQL: mysql.$namespace.svc.cluster.local:3306 (root/password123)"
    info "Cassandra: cassandra.$namespace.svc.cluster.local:9042"
}

# Create messaging environment
create_messaging_env() {
    local namespace=${1:-"messaging"}
    log "Creating messaging environment in namespace: $namespace"
    
    # Create namespace
    kubectl create namespace "$namespace" || warn "Namespace might already exist"
    
    # Apache Kafka with Zookeeper
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zookeeper
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      containers:
      - name: zookeeper
        image: confluentinc/cp-zookeeper:7.4.0
        env:
        - name: ZOOKEEPER_CLIENT_PORT
          value: "2181"
        - name: ZOOKEEPER_TICK_TIME
          value: "2000"
        ports:
        - containerPort: 2181
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper
  namespace: $namespace
spec:
  selector:
    app: zookeeper
  ports:
  - port: 2181
    targetPort: 2181
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.4.0
        env:
        - name: KAFKA_BROKER_ID
          value: "1"
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper:2181"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: "PLAINTEXT://kafka:9092"
        - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
          value: "1"
        ports:
        - containerPort: 9092
---
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: $namespace
spec:
  selector:
    app: kafka
  ports:
  - port: 9092
    targetPort: 9092
EOF
    
    # RabbitMQ
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3-management
        env:
        - name: RABBITMQ_DEFAULT_USER
          value: admin
        - name: RABBITMQ_DEFAULT_PASS
          value: password123
        ports:
        - containerPort: 5672
        - containerPort: 15672
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: $namespace
spec:
  selector:
    app: rabbitmq
  ports:
  - name: amqp
    port: 5672
    targetPort: 5672
  - name: management
    port: 15672
    targetPort: 15672
EOF
    
    log "Messaging environment created successfully!"
    info "Kafka: kafka.$namespace.svc.cluster.local:9092"
    info "Zookeeper: zookeeper.$namespace.svc.cluster.local:2181"
    info "RabbitMQ: rabbitmq.$namespace.svc.cluster.local:5672 (admin/password123)"
    info "RabbitMQ Management: kubectl port-forward -n $namespace svc/rabbitmq 15672:15672"
}

# Create vector database environment
create_vector_env() {
    local namespace=${1:-"vectordb"}
    log "Creating vector database environment in namespace: $namespace"
    
    # Create namespace
    kubectl create namespace "$namespace" || warn "Namespace might already exist"
    
    # Weaviate
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weaviate
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: weaviate
  template:
    metadata:
      labels:
        app: weaviate
    spec:
      containers:
      - name: weaviate
        image: semitechnologies/weaviate:1.21.2
        env:
        - name: QUERY_DEFAULTS_LIMIT
          value: "25"
        - name: AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED
          value: "true"
        - name: PERSISTENCE_DATA_PATH
          value: "/var/lib/weaviate"
        - name: DEFAULT_VECTORIZER_MODULE
          value: "none"
        - name: CLUSTER_HOSTNAME
          value: "node1"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: weaviate
  namespace: $namespace
spec:
  selector:
    app: weaviate
  ports:
  - port: 8080
    targetPort: 8080
EOF
    
    # Qdrant
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qdrant
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qdrant
  template:
    metadata:
      labels:
        app: qdrant
    spec:
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        ports:
        - containerPort: 6333
        - containerPort: 6334
---
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: $namespace
spec:
  selector:
    app: qdrant
  ports:
  - name: http
    port: 6333
    targetPort: 6333
  - name: grpc
    port: 6334
    targetPort: 6334
EOF
    
    # Elasticsearch
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.9.0
        env:
        - name: discovery.type
          value: single-node
        - name: xpack.security.enabled
          value: "false"
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        ports:
        - containerPort: 9200
        - containerPort: 9300
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: $namespace
spec:
  selector:
    app: elasticsearch
  ports:
  - name: http
    port: 9200
    targetPort: 9200
  - name: transport
    port: 9300
    targetPort: 9300
EOF
    
    log "Vector database environment created successfully!"
    info "Weaviate: weaviate.$namespace.svc.cluster.local:8080"
    info "Qdrant HTTP: qdrant.$namespace.svc.cluster.local:6333"
    info "Qdrant gRPC: qdrant.$namespace.svc.cluster.local:6334"
    info "Elasticsearch: elasticsearch.$namespace.svc.cluster.local:9200"
}

# Load testing function
load_test() {
    if [ -z "$1" ]; then
        error "Usage: load_test <url> [requests] [concurrency]"
    fi
    
    local url=$1
    local requests=${2:-1000}
    local concurrency=${3:-10}
    
    log "Running load test against $url"
    log "Requests: $requests, Concurrency: $concurrency"
    
    # Install apache2-utils if not present
    if ! command_exists ab; then
        log "Installing apache-bench..."
        sudo apt update && sudo apt install -y apache2-utils
    fi
    
    ab -n "$requests" -c "$concurrency" "$url"
}

# Monitor resources
monitor_resources() {
    local namespace=${1:-"default"}
    log "Monitoring resources in namespace: $namespace"
    
    while true; do
        clear
        echo -e "${BLUE}=== Resource Monitoring - Namespace: $namespace ===${NC}"
        echo -e "${GREEN}$(date)${NC}"
        echo
        
        echo -e "${YELLOW}Pods:${NC}"
        kubectl top pods -n "$namespace" 2>/dev/null || echo "Metrics server not available"
        echo
        
        echo -e "${YELLOW}Nodes:${NC}"
        kubectl top nodes 2>/dev/null || echo "Metrics server not available"
        echo
        
        echo -e "${YELLOW}Pod Status:${NC}"
        kubectl get pods -n "$namespace" --no-headers | awk '{print $1, $3}' | sort
        echo
        
        sleep 5
    done
}

# Enable Chaos Engineering
enable_chaos() {
    log "Installing Chaos Mesh for chaos engineering..."
    
    # Add Chaos Mesh Helm repository
    helm repo add chaos-mesh https://charts.chaos-mesh.org
    helm repo update
    
    # Create chaos-testing namespace
    kubectl create namespace chaos-testing || warn "Chaos-testing namespace might already exist"
    
    # Install Chaos Mesh
    helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
        --namespace chaos-testing \
        --set chaosDaemon.runtime=containerd \
        --set chaosDaemon.socketPath=/run/containerd/containerd.sock
    
    log "Chaos Mesh installed successfully!"
    info "Access Chaos Dashboard: kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333"
}

# Create network policies
create_network_policies() {
    local namespace=${1:-"default"}
    log "Creating sample network policies in namespace: $namespace"
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: $namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: $namespace
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF
    
    log "Network policies created successfully!"
    warn "All pods in $namespace namespace now have restricted network access"
}

# Generate sample manifests
generate_manifests() {
    local app_name=${1:-"sample-app"}
    local namespace=${2:-"default"}
    local manifest_dir="manifests-$app_name"
    
    log "Generating Kubernetes manifests for $app_name in $manifest_dir/"
    
    mkdir -p "$manifest_dir"
    
    # Deployment
    cat > "$manifest_dir/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app_name
  namespace: $namespace
  labels:
    app: $app_name
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $app_name
  template:
    metadata:
      labels:
        app: $app_name
    spec:
      containers:
      - name: $app_name
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
    
    # Service
    cat > "$manifest_dir/service.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $app_name-service
  namespace: $namespace
spec:
  selector:
    app: $app_name
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF
    
    # ConfigMap
    cat > "$manifest_dir/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $app_name-config
  namespace: $namespace
data:
  app.properties: |
    server.port=80
    app.name=$app_name
    app.environment=development
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
EOF
    
    # Secret
    cat > "$manifest_dir/secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $app_name-secret
  namespace: $namespace
type: Opaque
data:
  username: $(echo -n 'admin' | base64)
  password: $(echo -n 'password123' | base64)
EOF
    
    # HPA
    cat > "$manifest_dir/hpa.yaml" <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $app_name-hpa
  namespace: $namespace
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $app_name
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
    
    # PVC
    cat > "$manifest_dir/pvc.yaml" <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $app_name-pvc
  namespace: $namespace
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
    
    # Ingress
    cat > "$manifest_dir/ingress.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $app_name-ingress
  namespace: $namespace
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: $app_name.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $app_name-service
            port:
              number: 80
EOF
    
    log "Manifests generated in $manifest_dir/"
    info "Files created:"
    ls -la "$manifest_dir/"
}

# Backup namespace
backup_namespace() {
    if [ -z "$1" ]; then
        error "Please provide a namespace name"
    fi
    
    local namespace=$1
    local backup_dir="$HOME/k8s-backups/namespace-$namespace-$(date +%Y%m%d_%H%M%S)"
    
    log "Backing up namespace $namespace to $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup all resources
    kubectl get all -n "$namespace" -o yaml > "$backup_dir/all-resources.yaml"
    kubectl get secrets -n "$namespace" -o yaml > "$backup_dir/secrets.yaml"
    kubectl get configmaps -n "$namespace" -o yaml > "$backup_dir/configmaps.yaml"
    kubectl get pvc -n "$namespace" -o yaml > "$backup_dir/pvcs.yaml"
    kubectl get ingress -n "$namespace" -o yaml > "$backup_dir/ingress.yaml" 2>/dev/null || true
    
    log "Namespace $namespace backed up successfully!"
    info "Backup location: $backup_dir"
}

# Enable Ingress Controller
enable_ingress() {
    log "Enabling NGINX Ingress Controller..."
    
    # Enable ingress addon in minikube
    minikube addons enable ingress
    
    # Wait for ingress controller to be ready
    log "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    log "NGINX Ingress Controller enabled successfully!"
    info "Ingress controller is ready to handle ingress resources"
}

# Disable Ingress Controller
disable_ingress() {
    log "Disabling NGINX Ingress Controller..."
    minikube addons disable ingress
    log "NGINX Ingress Controller disabled successfully!"
}

# Create Ingress Resource
create_ingress() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        error "Usage: create_ingress <name> <host> <service:port> [namespace] [path]"
    fi
    
    local name=$1
    local host=$2
    local service_port=$3
    local namespace=${4:-"default"}
    local path=${5:-"/"}
    
    # Parse service and port
    IFS=':' read -r service port <<< "$service_port"
    
    log "Creating ingress $name for host $host -> $service:$port in namespace $namespace"
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $name
  namespace: $namespace
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: $host
    http:
      paths:
      - path: $path
        pathType: Prefix
        backend:
          service:
            name: $service
            port:
              number: $port
EOF
    
    log "Ingress $name created successfully!"
    info "Add '$host' to your /etc/hosts file pointing to minikube IP"
    info "Get minikube IP: minikube ip"
}

# Create TLS Ingress
create_tls_ingress() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        error "Usage: create_tls_ingress <name> <host> <service:port> [namespace]"
    fi
    
    local name=$1
    local host=$2
    local service_port=$3
    local namespace=${4:-"default"}
    
    # Parse service and port
    IFS=':' read -r service port <<< "$service_port"
    
    log "Creating TLS ingress $name for host $host -> $service:$port in namespace $namespace"
    
    # Create self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /tmp/tls.key -out /tmp/tls.crt \
        -subj "/CN=$host/O=$host"
    
    # Create TLS secret
    kubectl create secret tls "$name-tls" \
        --key /tmp/tls.key \
        --cert /tmp/tls.crt \
        -n "$namespace" || warn "TLS secret might already exist"
    
    # Create ingress with TLS
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $name
  namespace: $namespace
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - $host
    secretName: $name-tls
  rules:
  - host: $host
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $service
            port:
              number: $port
EOF
    
    # Clean up temporary files
    rm -f /tmp/tls.key /tmp/tls.crt
    
    log "TLS Ingress $name created successfully!"
    info "Access via: https://$host"
    info "Add '$host' to your /etc/hosts file pointing to minikube IP"
}

# Delete Ingress
delete_ingress() {
    if [ -z "$1" ]; then
        error "Usage: delete_ingress <name> [namespace]"
    fi
    
    local name=$1
    local namespace=${2:-"default"}
    
    log "Deleting ingress $name from namespace $namespace"
    kubectl delete ingress "$name" -n "$namespace"
    
    # Also delete associated TLS secret if exists
    kubectl delete secret "$name-tls" -n "$namespace" 2>/dev/null || true
    
    log "Ingress $name deleted successfully!"
}

# List Ingress resources
list_ingress() {
    local namespace=${1:-"--all-namespaces"}
    log "Listing ingress resources"
    
    if [ "$namespace" = "--all-namespaces" ]; then
        kubectl get ingress --all-namespaces -o wide
    else
        kubectl get ingress -n "$namespace" -o wide
    fi
}

# Describe Ingress
describe_ingress() {
    if [ -z "$1" ]; then
        error "Usage: describe_ingress <name> [namespace]"
    fi
    
    local name=$1
    local namespace=${2:-"default"}
    
    log "Describing ingress $name in namespace $namespace"
    kubectl describe ingress "$name" -n "$namespace"
}

# Test Ingress connectivity
test_ingress() {
    if [ -z "$1" ]; then
        error "Usage: test_ingress <host> [path] [port]"
    fi
    
    local host=$1
    local path=${2:-"/"}
    local port=${3:-80}
    local minikube_ip=$(minikube ip)
    
    log "Testing ingress connectivity for $host$path"
    info "Using minikube IP: $minikube_ip"
    
    # Test HTTP
    if [ "$port" = "80" ]; then
        curl -H "Host: $host" "http://$minikube_ip$path" -v
    # Test HTTPS
    elif [ "$port" = "443" ]; then
        curl -H "Host: $host" "https://$minikube_ip$path" -v -k
    else
        curl -H "Host: $host" "http://$minikube_ip:$port$path" -v
    fi
}

# Backup cluster configuration
backup_config() {
    local backup_dir="$HOME/k8s-backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log "Backing up cluster configuration to $backup_dir"
    
    # Backup kubeconfig
    cp "$KUBECONFIG_PATH" "$backup_dir/kubeconfig"
    
    # Backup all resources
    kubectl get all --all-namespaces -o yaml > "$backup_dir/all-resources.yaml"
    
    # Backup namespaces
    kubectl get namespaces -o yaml > "$backup_dir/namespaces.yaml"
    
    # Backup persistent volumes
    kubectl get pv -o yaml > "$backup_dir/persistent-volumes.yaml"
    
    # Backup storage classes
    kubectl get storageclass -o yaml > "$backup_dir/storage-classes.yaml"
    
    log "Backup completed in $backup_dir"
}

# Dashboard
enable_dashboard() {
    log "Enabling Kubernetes Dashboard..."
    minikube addons enable dashboard
    minikube addons enable metrics-server
    log "Dashboard enabled! Use 'k8s dashboard' to access it"
}

open_dashboard() {
    log "Opening Kubernetes Dashboard..."
    minikube dashboard
}

# Interactive menu system
show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Kubernetes Local Manager                    ║${NC}"
    echo -e "${BLUE}║                         Version 2.0                           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Select a category:${NC}"
    echo
    echo -e "${YELLOW}1)${NC} Cluster Management"
    echo -e "${YELLOW}2)${NC} Development Environments"
    echo -e "${YELLOW}3)${NC} Application Management"
    echo -e "${YELLOW}4)${NC} Networking & Ingress"
    echo -e "${YELLOW}5)${NC} Monitoring & Debugging"
    echo -e "${YELLOW}6)${NC} Utilities & Tools"
    echo -e "${YELLOW}7)${NC} Quick Setup Wizard"
    echo -e "${YELLOW}8)${NC} Command Line Mode"
    echo -e "${YELLOW}q)${NC} Quit"
    echo
}

show_cluster_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     Cluster Management                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Available Options:${NC}"
    echo
    echo -e "${YELLOW}1)${NC} Install Prerequisites (Docker, kubectl, minikube, helm)"
    echo -e "${YELLOW}2)${NC} Start Cluster"
    echo -e "${YELLOW}3)${NC} Stop Cluster"
    echo -e "${YELLOW}4)${NC} Restart Cluster"
    echo -e "${YELLOW}5)${NC} Delete Cluster"
    echo -e "${YELLOW}6)${NC} Show Cluster Status"
    echo -e "${YELLOW}7)${NC} Enable Dashboard"
    echo -e "${YELLOW}8)${NC} Open Dashboard"
    echo -e "${YELLOW}9)${NC} Backup Cluster Configuration"
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

show_dev_env_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                  Development Environments                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Select Individual Components:${NC}"
    echo
    echo -e "${YELLOW}Storage & Caching:${NC}"
    echo -e "${YELLOW}1)${NC} Redis (In-memory cache)"
    echo -e "${YELLOW}2)${NC} MinIO (S3-compatible storage)"
    echo -e "${YELLOW}3)${NC} Memcached (High-performance caching)"
    echo -e "${YELLOW}4)${NC} Hazelcast (In-memory data grid)"
    echo
    echo -e "${YELLOW}Databases:${NC}"
    echo -e "${YELLOW}5)${NC} PostgreSQL (Relational DB)"
    echo -e "${YELLOW}6)${NC} MongoDB (Document DB)"
    echo -e "${YELLOW}7)${NC} MySQL (Relational DB)"
    echo -e "${YELLOW}8)${NC} Cassandra (Wide-column DB)"
    echo -e "${YELLOW}9)${NC} InfluxDB (Time-series DB)"
    echo
    echo -e "${YELLOW}Messaging:${NC}"
    echo -e "${YELLOW}10)${NC} Apache Kafka (Event streaming)"
    echo -e "${YELLOW}11)${NC} RabbitMQ (Message broker)"
    echo -e "${YELLOW}12)${NC} ActiveMQ Artemis (Message broker)"
    echo -e "${YELLOW}13)${NC} Apache Pulsar (Pub-sub messaging)"
    echo -e "${YELLOW}14)${NC} Zookeeper (Coordination service)"
    echo
    echo -e "${YELLOW}Vector & Search:${NC}"
    echo -e "${YELLOW}15)${NC} Weaviate (Vector database)"
    echo -e "${YELLOW}16)${NC} Qdrant (Vector search)"
    echo -e "${YELLOW}17)${NC} Elasticsearch (Search & analytics)"
    echo -e "${YELLOW}18)${NC} OpenSearch (Search & analytics)"
    echo
    echo -e "${YELLOW}Infrastructure:${NC}"
    echo -e "${YELLOW}19)${NC} Local Docker Registry"
    echo -e "${YELLOW}20)${NC} Create Custom Namespace"
    echo -e "${YELLOW}21)${NC} Delete Namespace"
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

show_app_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   Application Management                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Available Options:${NC}"
    echo
    echo -e "${YELLOW}1)${NC} Deploy Application from YAML"
    echo -e "${YELLOW}2)${NC} Delete Application from YAML"
    echo -e "${YELLOW}3)${NC} Generate Sample Manifests"
    echo -e "${YELLOW}4)${NC} Scale Deployment"
    echo -e "${YELLOW}5)${NC} Get All Resources"
    echo -e "${YELLOW}6)${NC} Get Pod Logs"
    echo -e "${YELLOW}7)${NC} Execute Command in Pod"
    echo -e "${YELLOW}8)${NC} Port Forward to Service"
    echo -e "${YELLOW}9)${NC} Backup Namespace"
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

show_networking_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Networking & Ingress                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Available Options:${NC}"
    echo
    echo -e "${YELLOW}1)${NC} Enable Ingress Controller"
    echo -e "${YELLOW}2)${NC} Disable Ingress Controller"
    echo -e "${YELLOW}3)${NC} Create Ingress Resource"
    echo -e "${YELLOW}4)${NC} Create TLS Ingress Resource"
    echo -e "${YELLOW}5)${NC} Delete Ingress Resource"
    echo -e "${YELLOW}6)${NC} List Ingress Resources"
    echo -e "${YELLOW}7)${NC} Describe Ingress Resource"
    echo -e "${YELLOW}8)${NC} Test Ingress Connectivity"
    echo -e "${YELLOW}9)${NC} Create Network Policies"
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

show_monitoring_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   Monitoring & Debugging                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Monitoring Components:${NC}"
    echo
    echo -e "${YELLOW}Core Monitoring:${NC}"
    echo -e "${YELLOW}1)${NC} Prometheus (Metrics collection)"
    echo -e "${YELLOW}2)${NC} Grafana (Visualization dashboard)"
    echo -e "${YELLOW}3)${NC} Complete Monitoring Stack (Prometheus + Grafana)"
    echo
    echo -e "${YELLOW}Service Mesh & Advanced:${NC}"
    echo -e "${YELLOW}4)${NC} Istio Service Mesh"
    echo -e "${YELLOW}5)${NC} Kiali (Service mesh observability)"
    echo -e "${YELLOW}6)${NC} Jaeger (Distributed tracing)"
    echo
    echo -e "${YELLOW}Chaos Engineering:${NC}"
    echo -e "${YELLOW}7)${NC} Chaos Mesh (Chaos engineering platform)"
    echo -e "${YELLOW}8)${NC} Litmus (Cloud-native chaos engineering)"
    echo
    echo -e "${YELLOW}Real-time Monitoring:${NC}"
    echo -e "${YELLOW}9)${NC} Monitor Resources (Real-time view)"
    echo -e "${YELLOW}10)${NC} View Cluster Status"
    echo -e "${YELLOW}11)${NC} Load Test Application"
    echo
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

show_utilities_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                      Utilities & Tools                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Available Options:${NC}"
    echo
    echo -e "${YELLOW}1)${NC} Generate Kubernetes Manifests"
    echo -e "${YELLOW}2)${NC} Backup Namespace"
    echo -e "${YELLOW}3)${NC} Backup Cluster Configuration"
    echo -e "${YELLOW}4)${NC} Create Network Policies"
    echo -e "${YELLOW}5)${NC} Setup Local Docker Registry"
    echo -e "${YELLOW}6)${NC} Show Cluster Information"
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

show_wizard_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                      Quick Setup Wizard                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Quick Setup Options:${NC}"
    echo
    echo -e "${YELLOW}1)${NC} Complete Local Development Setup"
    echo -e "${YELLOW}2)${NC} Microservices Development Setup"
    echo -e "${YELLOW}3)${NC} Data Engineering Setup"
    echo -e "${YELLOW}4)${NC} AI/ML Development Setup"
    echo -e "${YELLOW}5)${NC} Web Application Setup"
    echo -e "${YELLOW}b)${NC} Back to Main Menu"
    echo
}

# Wizard functions
wizard_complete_dev_setup() {
    log "Starting Complete Local Development Setup..."
    
    # Install prerequisites if needed
    if ! command_exists kubectl || ! command_exists minikube; then
        info "Installing prerequisites first..."
        install_prerequisites
    fi
    
    # Start cluster
    start_cluster
    
    # Enable essential addons
    enable_dashboard
    enable_ingress
    
    # Create development environment
    create_dev_env "development"
    
    # Create basic database environment
    create_database_env "databases"
    
    # Setup monitoring
    enable_monitoring
    
    # Generate sample manifests
    generate_manifests "sample-app" "development"
    
    log "Complete development setup finished!"
    info "Access points:"
    info "- Dashboard: minikube dashboard"
    info "- Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    info "- Dev services available in 'development' namespace"
    info "- Database services available in 'databases' namespace"
    info "- Sample manifests generated in './manifests-sample-app/' directory"
}

wizard_microservices_setup() {
    log "Starting Microservices Development Setup..."
    
    start_cluster
    enable_ingress
    enable_istio
    setup_registry
    create_dev_env "microservices"
    create_messaging_env "messaging"
    enable_monitoring
    
    log "Microservices setup completed!"
    info "Features enabled: Istio, Local Registry, Messaging, Monitoring"
}

wizard_data_engineering_setup() {
    log "Starting Data Engineering Setup..."
    
    start_cluster
    create_database_env "databases"
    create_messaging_env "messaging"
    create_vector_env "vectordb"
    enable_monitoring
    
    log "Data engineering setup completed!"
    info "Available: MongoDB, MySQL, Cassandra, Kafka, RabbitMQ, Vector DBs"
}

wizard_aiml_setup() {
    log "Starting AI/ML Development Setup..."
    
    start_cluster
    enable_dashboard
    create_vector_env "vectordb"
    create_dev_env "aiml"
    enable_monitoring
    
    # Create AI/ML specific namespace with GPU support simulation
    kubectl create namespace aiml-training || warn "Namespace might already exist"
    
    log "AI/ML setup completed!"
    info "Vector databases and development environment ready for AI/ML workloads"
}

wizard_webapp_setup() {
    log "Starting Web Application Setup..."
    
    start_cluster
    enable_ingress
    enable_dashboard
    create_dev_env "webapp"
    setup_registry
    enable_monitoring
    
    # Generate web app manifests
    generate_manifests "web-app" "webapp"
    
    log "Web application setup completed!"
    info "Ready for web application development with ingress and monitoring"
}

# Interactive menu handlers
handle_cluster_menu() {
    while true; do
        show_cluster_menu
        read -p "Select option: " choice
        
        case $choice in
            1) install_prerequisites ;;
            2) start_cluster ;;
            3) stop_cluster ;;
            4) stop_cluster && sleep 2 && start_cluster ;;
            5) delete_cluster ;;
            6) show_status ;;
            7) enable_dashboard ;;
            8) open_dashboard ;;
            9) backup_config ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

handle_dev_env_menu() {
    while true; do
        show_dev_env_menu
        read -p "Select option: " choice
        
        case $choice in
            1) 
                read -p "Enter namespace name (default: development): " ns
                deploy_redis "${ns:-development}"
                ;;
            2) 
                read -p "Enter namespace name (default: development): " ns
                deploy_minio "${ns:-development}"
                ;;
            3) 
                read -p "Enter namespace name (default: development): " ns
                deploy_memcached "${ns:-development}"
                ;;
            4) 
                read -p "Enter namespace name (default: development): " ns
                deploy_hazelcast "${ns:-development}"
                ;;
            5) 
                read -p "Enter namespace name (default: development): " ns
                deploy_postgresql "${ns:-development}"
                ;;
            6) 
                read -p "Enter namespace name (default: development): " ns
                deploy_mongodb "${ns:-development}"
                ;;
            7) 
                read -p "Enter namespace name (default: development): " ns
                deploy_mysql "${ns:-development}"
                ;;
            8) 
                read -p "Enter namespace name (default: development): " ns
                deploy_cassandra "${ns:-development}"
                ;;
            9) 
                read -p "Enter namespace name (default: development): " ns
                deploy_influxdb "${ns:-development}"
                ;;
            10) 
                read -p "Enter namespace name (default: development): " ns
                deploy_kafka "${ns:-development}"
                ;;
            11) 
                read -p "Enter namespace name (default: development): " ns
                deploy_rabbitmq "${ns:-development}"
                ;;
            12) 
                read -p "Enter namespace name (default: development): " ns
                deploy_artemis "${ns:-development}"
                ;;
            13) 
                read -p "Enter namespace name (default: development): " ns
                deploy_pulsar "${ns:-development}"
                ;;
            14) 
                read -p "Enter namespace name (default: development): " ns
                deploy_zookeeper "${ns:-development}"
                ;;
            15) 
                read -p "Enter namespace name (default: development): " ns
                deploy_weaviate "${ns:-development}"
                ;;
            16) 
                read -p "Enter namespace name (default: development): " ns
                deploy_qdrant "${ns:-development}"
                ;;
            17) 
                read -p "Enter namespace name (default: development): " ns
                deploy_elasticsearch "${ns:-development}"
                ;;
            18) 
                read -p "Enter namespace name (default: development): " ns
                deploy_opensearch "${ns:-development}"
                ;;
            19) setup_registry ;;
            20) 
                read -p "Enter namespace name: " ns
                create_namespace "$ns"
                ;;
            21) 
                read -p "Enter namespace name to delete: " ns
                delete_namespace "$ns"
                ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

handle_app_menu() {
    while true; do
        show_app_menu
        read -p "Select option: " choice
        
        case $choice in
            1) 
                read -p "Enter YAML file path: " yaml_file
                deploy_app "$yaml_file"
                ;;
            2) 
                read -p "Enter YAML file path: " yaml_file
                delete_app "$yaml_file"
                ;;
            3) 
                read -p "Enter app name (default: sample-app): " app_name
                read -p "Enter namespace (default: default): " ns
                generate_manifests "${app_name:-sample-app}" "${ns:-default}"
                ;;
            4) 
                read -p "Enter deployment name: " deployment
                read -p "Enter replica count: " replicas
                read -p "Enter namespace (default: default): " ns
                scale_deployment "$deployment" "$replicas" "${ns:-default}"
                ;;
            5) 
                read -p "Enter namespace (default: default): " ns
                get_all_resources "${ns:-default}"
                ;;
            6) 
                read -p "Enter pod name: " pod
                read -p "Enter namespace (default: default): " ns
                read -p "Follow logs? (y/n): " follow
                [[ $follow =~ ^[Yy]$ ]] && follow_flag="follow" || follow_flag=""
                get_logs "$pod" "${ns:-default}" "$follow_flag"
                ;;
            7) 
                read -p "Enter pod name: " pod
                read -p "Enter namespace (default: default): " ns
                read -p "Enter command (default: /bin/bash): " cmd
                exec_pod "$pod" "${ns:-default}" "${cmd:-/bin/bash}"
                ;;
            8) 
                read -p "Enter service name: " service
                read -p "Enter port mapping (e.g., 8080:80): " ports
                read -p "Enter namespace (default: default): " ns
                port_forward "$service" "$ports" "${ns:-default}"
                ;;
            9) 
                read -p "Enter namespace to backup: " ns
                backup_namespace "$ns"
                ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

handle_networking_menu() {
    while true; do
        show_networking_menu
        read -p "Select option: " choice
        
        case $choice in
            1) enable_ingress ;;
            2) disable_ingress ;;
            3) 
                read -p "Enter ingress name: " name
                read -p "Enter host (e.g., app.local): " host
                read -p "Enter service:port (e.g., my-service:80): " service_port
                read -p "Enter namespace (default: default): " ns
                read -p "Enter path (default: /): " path
                create_ingress "$name" "$host" "$service_port" "${ns:-default}" "${path:-/}"
                ;;
            4) 
                read -p "Enter ingress name: " name
                read -p "Enter host (e.g., app.local): " host
                read -p "Enter service:port (e.g., my-service:80): " service_port
                read -p "Enter namespace (default: default): " ns
                create_tls_ingress "$name" "$host" "$service_port" "${ns:-default}"
                ;;
            5) 
                read -p "Enter ingress name: " name
                read -p "Enter namespace (default: default): " ns
                delete_ingress "$name" "${ns:-default}"
                ;;
            6) 
                read -p "Enter namespace (default: all): " ns
                [[ -z "$ns" ]] && ns="--all-namespaces"
                list_ingress "$ns"
                ;;
            7) 
                read -p "Enter ingress name: " name
                read -p "Enter namespace (default: default): " ns
                describe_ingress "$name" "${ns:-default}"
                ;;
            8) 
                read -p "Enter host to test: " host
                read -p "Enter path (default: /): " path
                read -p "Enter port (default: 80): " port
                test_ingress "$host" "${path:-/}" "${port:-80}"
                ;;
            9) 
                read -p "Enter namespace (default: default): " ns
                create_network_policies "${ns:-default}"
                ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

handle_monitoring_menu() {
    while true; do
        show_monitoring_menu
        read -p "Select option: " choice
        
        case $choice in
            1) deploy_prometheus ;;
            2) deploy_grafana ;;
            3) enable_monitoring ;;
            4) enable_istio ;;
            5) deploy_kiali ;;
            6) deploy_jaeger ;;
            7) enable_chaos ;;
            8) deploy_litmus ;;
            9) 
                read -p "Enter namespace to monitor (default: default): " ns
                monitor_resources "${ns:-default}"
                ;;
            10) show_status ;;
            11) 
                read -p "Enter URL to test: " url
                read -p "Enter number of requests (default: 1000): " requests
                read -p "Enter concurrency (default: 10): " concurrency
                load_test "$url" "${requests:-1000}" "${concurrency:-10}"
                ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

handle_utilities_menu() {
    while true; do
        show_utilities_menu
        read -p "Select option: " choice
        
        case $choice in
            1) 
                read -p "Enter app name (default: sample-app): " app_name
                read -p "Enter namespace (default: default): " ns
                generate_manifests "${app_name:-sample-app}" "${ns:-default}"
                ;;
            2) 
                read -p "Enter namespace to backup: " ns
                backup_namespace "$ns"
                ;;
            3) backup_config ;;
            4) 
                read -p "Enter namespace (default: default): " ns
                create_network_policies "${ns:-default}"
                ;;
            5) setup_registry ;;
            6) show_status ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

handle_wizard_menu() {
    while true; do
        show_wizard_menu
        read -p "Select option: " choice
        
        case $choice in
            1) wizard_complete_dev_setup ;;
            2) wizard_microservices_setup ;;
            3) wizard_data_engineering_setup ;;
            4) wizard_aiml_setup ;;
            5) wizard_webapp_setup ;;
            b) break ;;
            *) warn "Invalid option. Please try again." ;;
        esac
        
        if [[ $choice != "b" ]]; then
            read -p "Press Enter to continue..."
        fi
    done
}

# Interactive mode
interactive_mode() {
    while true; do
        show_menu
        read -p "Select option: " choice
        
        case $choice in
            1) handle_cluster_menu ;;
            2) handle_dev_env_menu ;;
            3) handle_app_menu ;;
            4) handle_networking_menu ;;
            5) handle_monitoring_menu ;;
            6) handle_utilities_menu ;;
            7) handle_wizard_menu ;;
            8) 
                echo -e "${GREEN}Switching to command line mode...${NC}"
                show_help
                exit 0
                ;;
            q|Q) 
                echo -e "${GREEN}Thank you for using Kubernetes Local Manager!${NC}"
                exit 0
                ;;
            *) 
                warn "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Show help
show_help() {
    echo -e "${BLUE}Kubernetes Local Management Script${NC}"
    echo
    echo "Usage: $0 <command> [arguments]"
    echo "       $0 --interactive (for interactive mode)"
    echo
    echo -e "${GREEN}Cluster Management:${NC}"
    echo "  install               Install prerequisites (Docker, kubectl, minikube, helm)"
    echo "  start                 Start the Kubernetes cluster"
    echo "  stop                  Stop the Kubernetes cluster"
    echo "  delete                Delete the entire cluster"
    echo "  status                Show cluster status"
    echo "  restart               Restart the cluster (stop + start)"
    echo
    echo -e "${GREEN}Namespace Management:${NC}"
    echo "  create-ns <name>      Create a new namespace"
    echo "  delete-ns <name>      Delete a namespace"
    echo
    echo -e "${GREEN}Application Management:${NC}"
    echo "  deploy <yaml-file>    Deploy application from YAML file"
    echo "  delete-app <yaml-file> Delete application from YAML file"
    echo "  get-all [namespace]   Get all resources (default: default namespace)"
    echo "  scale <deployment> <replicas> [namespace] Scale deployment"
    echo
    echo -e "${GREEN}Debugging & Utilities:${NC}"
    echo "  logs <pod> [namespace] [follow] Get pod logs"
    echo "  exec <pod> [namespace] [command] Execute command in pod"
    echo "  port-forward <service> <local:service-port> [namespace] Port forward to service"
    echo
    echo -e "${GREEN}Development & Testing Tools:${NC}"
    echo "  enable-monitoring     Install Prometheus, Grafana monitoring stack"
    echo "  enable-istio         Install Istio service mesh"
    echo "  setup-registry       Setup local Docker registry"
    echo "  create-dev-env [ns]  Create basic development environment (Redis, PostgreSQL, MinIO)"
    echo "  create-database-env [ns] Extended databases (MongoDB, MySQL, Cassandra)"
    echo "  create-messaging-env [ns] Messaging systems (Kafka, RabbitMQ)"
    echo "  create-vector-env [ns] Vector & search DBs (Weaviate, Qdrant, Elasticsearch)"
    echo
    echo -e "${GREEN}Individual Component Deployment:${NC}"
    echo "  deploy-redis [ns]        Deploy Redis cache"
    echo "  deploy-minio [ns]        Deploy MinIO object storage"
    echo "  deploy-memcached [ns]    Deploy Memcached high-performance cache"
    echo "  deploy-hazelcast [ns]    Deploy Hazelcast in-memory data grid"
    echo "  deploy-postgresql [ns]   Deploy PostgreSQL database"
    echo "  deploy-mongodb [ns]      Deploy MongoDB database"
    echo "  deploy-mysql [ns]        Deploy MySQL database"
    echo "  deploy-cassandra [ns]    Deploy Cassandra database"
    echo "  deploy-influxdb [ns]     Deploy InfluxDB time-series database"
    echo "  deploy-kafka [ns]        Deploy Kafka with Zookeeper"
    echo "  deploy-rabbitmq [ns]     Deploy RabbitMQ message broker"
    echo "  deploy-artemis [ns]      Deploy ActiveMQ Artemis message broker"
    echo "  deploy-pulsar [ns]       Deploy Apache Pulsar pub-sub messaging"
    echo "  deploy-zookeeper [ns]    Deploy standalone Zookeeper"
    echo "  deploy-weaviate [ns]     Deploy Weaviate vector database"
    echo "  deploy-qdrant [ns]       Deploy Qdrant vector search"
    echo "  deploy-elasticsearch [ns] Deploy Elasticsearch"
    echo "  deploy-opensearch [ns]   Deploy OpenSearch"
    echo
    echo -e "${GREEN}Individual Monitoring Components:${NC}"
    echo "  deploy-prometheus        Deploy Prometheus monitoring"
    echo "  deploy-grafana          Deploy Grafana dashboards"
    echo "  deploy-kiali            Deploy Kiali (Istio observability)"
    echo "  deploy-jaeger           Deploy Jaeger tracing"
    echo "  deploy-litmus           Deploy Litmus chaos engineering"
    echo
    echo "  load-test <url> [req] [conc] Run load tests against URL"
    echo "  monitor-resources [ns] Monitor resource usage in real-time"
    echo "  enable-chaos         Install Chaos Mesh for chaos engineering"
    echo
    echo -e "${GREEN}Security & Network:${NC}"
    echo "  create-network-policies [ns] Create sample network policies"
    echo
    echo -e "${GREEN}Utilities & Generators:${NC}"
    echo "  generate-manifests [name] [ns] Generate sample K8s manifests"
    echo "  backup-namespace <ns> Backup entire namespace"
    echo
    echo -e "${GREEN}Ingress Management:${NC}"
    echo "  enable-ingress        Enable NGINX ingress controller"
    echo "  disable-ingress       Disable ingress controller"
    echo "  create-ingress <name> <host> <service:port> [namespace] [path]"
    echo "                        Create ingress resource"
    echo "  create-tls-ingress <name> <host> <service:port> [namespace]"
    echo "                        Create TLS ingress with self-signed cert"
    echo "  delete-ingress <name> [namespace] Delete ingress resource"
    echo "  list-ingress [namespace] List ingress resources"
    echo "  describe-ingress <name> [namespace] Describe ingress details"
    echo "  test-ingress <host> [path] [port] Test ingress connectivity"
    echo
    echo -e "${GREEN}Dashboard & Monitoring:${NC}"
    echo "  enable-dashboard      Enable Kubernetes dashboard"
    echo "  dashboard            Open dashboard in browser"
    echo
    echo -e "${GREEN}Backup & Maintenance:${NC}"
    echo "  backup               Backup cluster configuration"
    echo
    echo -e "${GREEN}Quick Setup Wizards:${NC}"
    echo "  wizard-complete-dev   Complete development environment setup"
    echo "  wizard-microservices  Microservices development setup"
    echo "  wizard-data-eng      Data engineering setup"
    echo "  wizard-aiml          AI/ML development setup"
    echo "  wizard-webapp        Web application setup"
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0 --interactive"
    echo "  $0 wizard-complete-dev"
    echo "  $0 start"
    echo "  $0 create-ns my-app"
    echo "  $0 create-dev-env development"
    echo "  $0 create-database-env databases"
    echo "  $0 create-messaging-env messaging"
    echo "  $0 create-vector-env vectordb"
    echo "  $0 enable-monitoring"
    echo "  $0 generate-manifests webapp development"
    echo "  $0 deploy app.yaml"
    echo "  $0 enable-ingress"
    echo "  $0 create-ingress my-ingress app.local my-service:80 default"
    echo "  $0 load-test http://app.local 1000 50"
    echo "  $0 scale my-deployment 3 my-namespace"
    echo "  $0 monitor-resources development"
    echo "  $0 backup-namespace production"
}

# Main function
main() {
    # Check if no arguments provided, start interactive mode
    if [ $# -eq 0 ]; then
        interactive_mode
        return
    fi

    case "${1}" in
        --interactive|-i)
            interactive_mode
            ;;
        install)
            install_prerequisites
            ;;
        start)
            start_cluster
            ;;
        stop)
            stop_cluster
            ;;
        delete)
            delete_cluster
            ;;
        restart)
            stop_cluster
            sleep 2
            start_cluster
            ;;
        status)
            show_status
            ;;
        create-ns)
            create_namespace "$2"
            ;;
        delete-ns)
            delete_namespace "$2"
            ;;
        deploy)
            deploy_app "$2"
            ;;
        delete-app)
            delete_app "$2"
            ;;
        get-all)
            get_all_resources "$2"
            ;;
        scale)
            scale_deployment "$2" "$3" "$4"
            ;;
        logs)
            get_logs "$2" "$3" "$4"
            ;;
        exec)
            exec_pod "$2" "$3" "$4"
            ;;
        port-forward)
            port_forward "$2" "$3" "$4"
            ;;
        enable-monitoring)
            enable_monitoring
            ;;
        enable-istio)
            enable_istio
            ;;
        setup-registry)
            setup_registry
            ;;
        create-dev-env)
            create_dev_env "$2"
            ;;
        create-database-env)
            create_database_env "$2"
            ;;
        create-messaging-env)
            create_messaging_env "$2"
            ;;
        create-vector-env)
            create_vector_env "$2"
            ;;
        deploy-redis)
            deploy_redis "$2"
            ;;
        deploy-minio)
            deploy_minio "$2"
            ;;
        deploy-postgresql)
            deploy_postgresql "$2"
            ;;
        deploy-mongodb)
            deploy_mongodb "$2"
            ;;
        deploy-mysql)
            deploy_mysql "$2"
            ;;
        deploy-cassandra)
            deploy_cassandra "$2"
            ;;
        deploy-kafka)
            deploy_kafka "$2"
            ;;
        deploy-rabbitmq)
            deploy_rabbitmq "$2"
            ;;
        deploy-zookeeper)
            deploy_zookeeper "$2"
            ;;
        deploy-weaviate)
            deploy_weaviate "$2"
            ;;
        deploy-qdrant)
            deploy_qdrant "$2"
            ;;
        deploy-elasticsearch)
            deploy_elasticsearch "$2"
            ;;
        deploy-memcached)
            deploy_memcached "$2"
            ;;
        deploy-hazelcast)
            deploy_hazelcast "$2"
            ;;
        deploy-influxdb)
            deploy_influxdb "$2"
            ;;
        deploy-artemis)
            deploy_artemis "$2"
            ;;
        deploy-pulsar)
            deploy_pulsar "$2"
            ;;
        deploy-opensearch)
            deploy_opensearch "$2"
            ;;
        deploy-prometheus)
            deploy_prometheus
            ;;
        deploy-grafana)
            deploy_grafana
            ;;
        deploy-kiali)
            deploy_kiali
            ;;
        deploy-jaeger)
            deploy_jaeger
            ;;
        deploy-litmus)
            deploy_litmus
            ;;
        load-test)
            load_test "$2" "$3" "$4"
            ;;
        monitor-resources)
            monitor_resources "$2"
            ;;
        enable-chaos)
            enable_chaos
            ;;
        create-network-policies)
            create_network_policies "$2"
            ;;
        generate-manifests)
            generate_manifests "$2" "$3"
            ;;
        backup-namespace)
            backup_namespace "$2"
            ;;
        enable-ingress)
            enable_ingress
            ;;
        disable-ingress)
            disable_ingress
            ;;
        create-ingress)
            create_ingress "$2" "$3" "$4" "$5" "$6"
            ;;
        create-tls-ingress)
            create_tls_ingress "$2" "$3" "$4" "$5"
            ;;
        delete-ingress)
            delete_ingress "$2" "$3"
            ;;
        list-ingress)
            list_ingress "$2"
            ;;
        describe-ingress)
            describe_ingress "$2" "$3"
            ;;
        test-ingress)
            test_ingress "$2" "$3" "$4"
            ;;
        enable-dashboard)
            enable_dashboard
            ;;
        dashboard)
            open_dashboard
            ;;
        backup)
            backup_config
            ;;
        wizard-complete-dev)
            wizard_complete_dev_setup
            ;;
        wizard-microservices)
            wizard_microservices_setup
            ;;
        wizard-data-eng)
            wizard_data_engineering_setup
            ;;
        wizard-aiml)
            wizard_aiml_setup
            ;;
        wizard-webapp)
            wizard_webapp_setup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1. Use '$0 help' for usage information or run without arguments for interactive mode."
            ;;
    esac
}

# Run main function with all arguments
main "$@"

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

# Show help
show_help() {
    echo -e "${BLUE}Kubernetes Local Management Script${NC}"
    echo
    echo "Usage: $0 <command> [arguments]"
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
    echo "  create-database-env [ns] Extended databases (MongoDB, MySQL, Cassandra, Neo4j)"
    echo "  create-messaging-env [ns] Messaging systems (Kafka, RabbitMQ, ActiveMQ)"
    echo "  create-vector-env [ns] Vector & search DBs (Weaviate, Chroma, Qdrant, Elasticsearch)"
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
    echo -e "${GREEN}Examples:${NC}"
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
    case "${1:-help}" in
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
        enable-dashboard)
            enable_dashboard
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
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1. Use '$0 help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"

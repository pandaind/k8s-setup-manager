# Kubernetes Local Manager

A comprehensive bash script for managing local Kubernetes clusters on Ubuntu Linux systems. This tool provides a complete production-grade local development environment with monitoring, service mesh, security, testing, and chaos engineering capabilities.

## 🚀 Features

### **Core Cluster Management**
- **One-click setup**: Automatically installs Docker, kubectl, minikube, Helm, and k9s
- **Cluster lifecycle management**: Start, stop, restart, and delete clusters with simple commands
- **Application deployment**: Deploy and manage applications using YAML files
- **Namespace management**: Create and delete namespaces easily

### **Development & Testing Environment**
- **Complete dev stack**: Redis, PostgreSQL, MinIO (S3-compatible storage)
- **Local container registry**: Push and pull custom images locally
- **Manifest generation**: Auto-generate production-ready Kubernetes manifests
- **Load testing**: Built-in performance testing with configurable parameters

### **Monitoring & Observability**
- **Full monitoring stack**: Prometheus + Grafana + AlertManager
- **Real-time monitoring**: Live resource usage tracking
- **Service mesh observability**: Istio with Kiali, Jaeger tracing
- **Dashboard access**: Kubernetes dashboard with metrics

### **Networking & Security**
- **Ingress management**: HTTP/HTTPS ingress with automatic SSL certificates
- **Network policies**: Security policies for network isolation
- **Service mesh**: Istio for advanced traffic management and security

### **Advanced Testing**
- **Chaos engineering**: Chaos Mesh for failure injection testing
- **Performance testing**: Comprehensive load testing capabilities
- **Auto-scaling**: HPA (Horizontal Pod Autoscaler) configurations

### **Backup & Recovery**
- **Namespace backup**: Complete backup with automated restore scripts
- **Cluster configuration backup**: Full cluster state preservation
- **Disaster recovery**: Quick restoration capabilities

## 📋 Prerequisites

- Ubuntu Linux (18.04 or later)
- Internet connection for downloading components
- Sudo privileges for installation
- At least 4GB RAM and 2 CPU cores recommended

## 🔧 Installation

1. **Clone or download the script**:
   ```bash
   wget https://raw.githubusercontent.com/pandaind/oneclick-k8s-local/main/k8s_manager.sh
   # OR
   curl -O https://raw.githubusercontent.com/pandaind/oneclick-k8s-local/main/k8s_manager.sh
   ```

2. **Make it executable and install globally**:
   ```bash
   chmod +x k8s_manager.sh
   sudo cp k8s_manager.sh /usr/local/bin/k8s
   ```

3. **Install prerequisites**:
   ```bash
   k8s install
   ```
   > **Note**: You may need to logout and login again after installation for Docker group changes to take effect.

## 📖 Usage

### Cluster Management

```bash
# Start the Kubernetes cluster
k8s start

# Check cluster status
k8s status

# Stop the cluster
k8s stop

# Restart the cluster
k8s restart

# Delete the entire cluster (with confirmation)
k8s delete
```

### Development Environment Setup

```bash
# Create complete development environment
k8s create-dev-env development

# Setup local Docker registry
k8s setup-registry

# Enable monitoring stack (Prometheus + Grafana)
k8s enable-monitoring

# Enable service mesh (Istio)
k8s enable-istio

# Enable ingress controller
k8s enable-ingress
```

### Application Development

```bash
# Generate sample Kubernetes manifests
k8s generate-manifests webapp development

# Deploy application from YAML file
k8s deploy app.yaml

# Scale applications
k8s scale my-deployment 5 development

# Create ingress for external access
k8s create-ingress webapp-ingress webapp.local webapp-service:80 development

# Create TLS ingress with self-signed certificate
k8s create-tls-ingress secure-app secure.local webapp-service:80 development
```

### Testing & Performance

```bash
# Run load tests
k8s load-test http://webapp.local 1000 50

# Monitor resources in real-time
k8s monitor-resources development

# Enable chaos engineering
k8s enable-chaos

# Test ingress connectivity
k8s test-ingress webapp.local
```

### Debugging & Troubleshooting

```bash
# View pod logs
k8s logs webapp-pod-123 development

# Follow logs in real-time
k8s logs webapp-pod-123 development follow

# Execute commands in pods
k8s exec webapp-pod-123 development bash

# Port forward services
k8s port-forward webapp-service 8080:80 development
```

### Security & Network Management

```bash
# Create network policies for security
k8s create-network-policies development

# List and manage ingress resources
k8s list-ingress development
k8s describe-ingress webapp-ingress development
k8s delete-ingress webapp-ingress development
```

### Backup & Recovery

```bash
# Backup entire namespace
k8s backup-namespace development

# Backup cluster configuration
k8s backup
```

## 🎯 Complete Development Workflow

Here's a comprehensive example from setup to production-ready testing:

```bash
# 1. Initial setup
k8s install
k8s start

# 2. Enable advanced features
k8s enable-monitoring
k8s enable-istio
k8s enable-ingress
k8s setup-registry

# 3. Create development environment
k8s create-dev-env development

# 4. Generate and customize application manifests
k8s generate-manifests webapp development
cd k8s-manifests-webapp
# Edit manifests as needed
./deploy.sh

# 5. Setup external access
k8s create-ingress webapp-ingress webapp.local webapp-service:80 development

# 6. Performance and chaos testing
k8s load-test http://webapp.local 2000 100
k8s enable-chaos

# 7. Monitor and debug
k8s monitor-resources development
k8s logs webapp-pod-xyz development follow

# 8. Security testing
k8s create-network-policies development

# 9. Backup before changes
k8s backup-namespace development
```

## 🏗️ Development Environment Components

When you run `k8s create-dev-env`, you get:

### **Database Services**

- **PostgreSQL**: Full-featured database
  - Host: `postgres:5432`
  - Database: `devdb`
  - User: `devuser`
  - Password: `devpass`

### **Caching & Storage**

- **Redis**: In-memory cache and session store
  - Host: `redis:6379`
- **MinIO**: S3-compatible object storage
  - API: `minio:9000`
  - Console: `http://$(minikube ip):32001`
  - Credentials: `minioadmin:minioadmin`

------

## 🆕 Extended Messaging & Vector/AI Database Environments

### **Messaging Systems**

✅ **RabbitMQ** with Management Console

- **AMQP**: `rabbitmq:5672`
- **Management UI**: `http://$(minikube ip):32672`
- **User**: `admin`
- **Password**: `password123`

✅ **ActiveMQ** with Web Console

- **OpenWire**: `activemq:61616`
- **Web Console**: `http://$(minikube ip):32161`
- **User**: `admin`
- **Password**: `password123`

------

### **Vector & Advanced Databases for AI/ML**

Command:

```bash
k8s create-vector-env [namespace]
```

Deploys a complete **AI/ML-ready vector database stack**:

✅ **Weaviate** – Vector database for AI applications

- Host: `weaviate:8080`
- Web UI: `http://$(minikube ip):32080`
- Features: `text2vec`, transformers support

✅ **Chroma** – Embedding database

- Host: `chroma:8000`
- Persistent storage enabled

✅ **Qdrant** – High-performance vector database

- HTTP API: `qdrant:6333`
- gRPC: `qdrant:6334`
- Web UI: `http://$(minikube ip):32333`

✅ **Elasticsearch** – Search & analytics engine

- Host: `elasticsearch:9200`
- Web Interface: `http://$(minikube ip):32200`
- Security disabled for development

------

### 📊 **Environment Setup Commands**

```bash
# Basic development stack
k8s create-dev-env development        # Redis, PostgreSQL, MinIO

# Extended database stack
k8s create-database-env databases     # MongoDB, MySQL, Cassandra, Neo4j

# Messaging systems
k8s create-messaging-env messaging    # Kafka, RabbitMQ, ActiveMQ

# AI/ML vector database stack
k8s create-vector-env vectordb        # Weaviate, Chroma, Qdrant, Elasticsearch
```

------

## 📊 Monitoring & Observability

### **Prometheus + Grafana Stack**
```bash
k8s enable-monitoring

# Access points:
# Grafana: http://$(minikube ip):[NodePort]
# Username: admin, Password: admin123
# Prometheus: http://$(minikube ip):[NodePort]
```

### **Istio Service Mesh**
```bash
k8s enable-istio

# Access Kiali dashboard:
istioctl dashboard kiali

# Features included:
# - Traffic management
# - Security policies
# - Distributed tracing (Jaeger)
# - Service mesh visualization
```

## 🧪 Testing Capabilities

### **Load Testing**
```bash
# Basic load test
k8s load-test http://webapp.local

# Advanced load test
k8s load-test http://webapp.local 5000 200

# Parameters: URL, total requests, concurrent requests
```

### **Chaos Engineering**
```bash
k8s enable-chaos

# Access Chaos Dashboard:
kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333
# Then visit: http://localhost:2333
```

## 📁 Generated Manifest Examples

The `k8s generate-manifests` command creates:

### **Deployment with Best Practices**
- Resource limits and requests
- Liveness and readiness probes
- Rolling update strategy
- Security context

### **Complete Service Stack**
- ClusterIP service
- Ingress with SSL/TLS support
- ConfigMap for configuration
- Secret for sensitive data
- HPA for auto-scaling

### **Ready-to-Use Scripts**
- `deploy.sh` - One-click deployment
- `restore.sh` - Automated backup restoration

## 🛡️ Security Features

### **Network Policies**
```bash
k8s create-network-policies development

# Creates policies for:
# - Default deny ingress traffic
# - Allow same-namespace communication
# - Allow ingress controller access
```

### **TLS/SSL Support**
```bash
# Create HTTPS ingress with self-signed certificate
k8s create-tls-ingress secure-app secure.local webapp-service:80 development
```

## 📊 Commands *Reference*

| Category        | Command                               | Description                                                  | Example                                       |
| --------------- | ------------------------------------- | ------------------------------------------------------------ | --------------------------------------------- |
| **Setup**       | `install`                             | Install all prerequisites                                    | `k8s install`                                 |
|                 | `start`                               | Start cluster                                                | `k8s start`                                   |
|                 | `stop`                                | Stop cluster                                                 | `k8s stop`                                    |
|                 | `status`                              | Show cluster status                                          | `k8s status`                                  |
| **Development** | `create-dev-env <ns>`                 | Create dev environment                                       | `k8s create-dev-env dev`                      |
|                 | `create-database-env <ns>`            | Create extended database env                                 | `k8s create-database-env databases`           |
|                 | `create-messaging-env <ns>`           | Create messaging env (Kafka, RabbitMQ, ActiveMQ)             | `k8s create-messaging-env messaging`          |
|                 | `create-vector-env <ns>`              | Create AI/ML vector DB env (Weaviate, Chroma, Qdrant, Elasticsearch) | `k8s create-vector-env vectordb`              |
|                 | `setup-registry`                      | Local Docker registry                                        | `k8s setup-registry`                          |
|                 | `generate-manifests <n> <ns>`         | Generate K8s manifests                                       | `k8s generate-manifests app dev`              |
| **Monitoring**  | `enable-monitoring`                   | Install monitoring stack                                     | `k8s enable-monitoring`                       |
|                 | `monitor-resources <ns>`              | Real-time monitoring                                         | `k8s monitor-resources dev`                   |
|                 | `enable-istio`                        | Install service mesh                                         | `k8s enable-istio`                            |
| **Testing**     | `load-test <url> <req> <conc>`        | Performance testing                                          | `k8s load-test http://app.local 1000 50`      |
|                 | `enable-chaos`                        | Chaos engineering                                            | `k8s enable-chaos`                            |
| **Ingress**     | `enable-ingress`                      | Enable ingress controller                                    | `k8s enable-ingress`                          |
|                 | `create-ingress <n> <host> <svc>`     | Create ingress                                               | `k8s create-ingress app app.local svc:80`     |
|                 | `create-tls-ingress <n> <host> <svc>` | Create HTTPS ingress                                         | `k8s create-tls-ingress app app.local svc:80` |
|                 | `test-ingress <host>`                 | Test connectivity                                            | `k8s test-ingress app.local`                  |
| **Apps**        | `deploy <file>`                       | Deploy from YAML                                             | `k8s deploy app.yaml`                         |
|                 | `scale <dep> <n> <ns>`                | Scale deployment                                             | `k8s scale web 5 dev`                         |
|                 | `get-all <ns>`                        | List all resources                                           | `k8s get-all dev`                             |
| **Debug**       | `logs <pod> <ns> [follow]`            | View logs                                                    | `k8s logs web-123 dev follow`                 |
|                 | `exec <pod> <ns> [cmd]`               | Execute in pod                                               | `k8s exec web-123 dev bash`                   |
|                 | `port-forward <svc> <ports> <ns>`     | Port forward                                                 | `k8s port-forward web 8080:80 dev`            |
| **Security**    | `create-network-policies <ns>`        | Create network policies                                      | `k8s create-network-policies dev`             |
| **Backup**      | `backup-namespace <ns>`               | Backup namespace                                             | `k8s backup-namespace prod`                   |
|                 | `backup`                              | Backup cluster                                               | `k8s backup`                                  |

------

## 📡 Service Access URLs

| Service                                                                                         | Host / API                         | Web UI / Console                                   | Credentials               | 🧪 Test Command                                                                                        |
| ----------------------------------------------------------------------------------------------- | ---------------------------------- | -------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------ |
| [**PostgreSQL**](https://www.postgresql.org/docs/)                                              | `postgres:5432`                    | –                                                  | `devuser / devpass`       | `kubectl exec -it deploy/postgres -- psql -U devuser -c '\l'`                                          |
| [**Redis**](https://redis.io/docs/)                                                             | `redis:6379`                       | –                                                  | –                         | `kubectl exec -it deploy/redis -- redis-cli PING`                                                      |
| [**MinIO**](https://min.io/docs/minio/linux/index.html)                                         | `minio:9000`                       | [Web Console](http://$%28minikube%20ip%29:32001)   | `minioadmin / minioadmin` | `kubectl exec -it deploy/minio -- mc alias set local http://localhost:9000 minioadmin minioadmin`      |
| [**MongoDB**](https://www.mongodb.com/docs/)                                                    | `mongodb:27017`                    | –                                                  | `admin / password123`     | `kubectl exec -it deploy/mongodb -- mongosh -u admin -p password123 --eval 'db.stats()'`               |
| [**MySQL**](https://dev.mysql.com/doc/)                                                         | `mysql:3306`                       | –                                                  | `devuser / devpass123`    | `kubectl exec -it deploy/mysql -- mysql -u devuser -pdevpass123 -e "SHOW DATABASES;"`                  |
| [**Cassandra**](https://cassandra.apache.org/doc/latest/)                                       | `cassandra:9042`                   | –                                                  | –                         | `kubectl exec -it deploy/cassandra -- cqlsh -e "DESCRIBE KEYSPACES;"`                                  |
| [**Neo4j**](https://neo4j.com/docs/)                                                            | `neo4j:7687`                       | [Browser](http://$%28minikube%20ip%29:32474)       | `neo4j / password123`     | `kubectl exec -it deploy/neo4j -- cypher-shell -u neo4j -p password123 "MATCH (n) RETURN count(n);"`   |
| [**Kafka**](https://kafka.apache.org/documentation/)                                            | `kafka:9092`                       | –                                                  | –                         | `kubectl exec -it deploy/kafka -- kafka-topics.sh --bootstrap-server localhost:9092 --list`            |
| [**RabbitMQ**](https://www.rabbitmq.com/docs)                                                   | `rabbitmq:5672`                    | [Management UI](http://$%28minikube%20ip%29:32672) | `admin / password123`     | `kubectl exec -it deploy/rabbitmq -- rabbitmqctl list_queues`                                          |
| [**ActiveMQ**](https://activemq.apache.org/components/classic/documentation)                    | `activemq:61616`                   | [Web Console](http://$%28minikube%20ip%29:32161)   | `admin / password123`     | `kubectl exec -it deploy/activemq -- curl -u admin:password123 http://localhost:8161/admin/queues.jsp` |
| [**Weaviate**](https://weaviate.io/developers/weaviate)                                         | `weaviate:8080`                    | [Web UI](http://$%28minikube%20ip%29:32080)        | –                         | `kubectl exec -it deploy/weaviate -- curl http://localhost:8080/v1/meta`                               |
| [**Chroma**](https://docs.trychroma.com/)                                                       | `chroma:8000`                      | –                                                  | –                         | `kubectl exec -it deploy/chroma -- curl http://localhost:8000/api/v1/collections`                      |
| [**Qdrant**](https://qdrant.tech/documentation/)                                                | `qdrant:6333 (HTTP) / 6334 (gRPC)` | [Web UI](http://$%28minikube%20ip%29:32333)        | –                         | `kubectl exec -it deploy/qdrant -- curl http://localhost:6333/collections`                             |
| [**Elasticsearch**](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html) | `elasticsearch:9200`               | [Web UI](http://$%28minikube%20ip%29:32200)        | –                         | `kubectl exec -it deploy/elasticsearch -- curl http://localhost:9200/_cluster/health?pretty`           |

---

## 🔍 Troubleshooting

### Common Issues

1. **Docker permission denied**:
   ```bash
   sudo usermod -aG docker $USER
   # Then logout and login again
   ```

2. **Minikube won't start**:
   ```bash
   k8s delete  # Delete existing cluster
   k8s start   # Start fresh
   ```

3. **Resource constraints**:
   ```bash
   # Increase minikube resources
   minikube config set memory 4096
   minikube config set cpus 2
   k8s restart
   ```

4. **Ingress not accessible**:
   ```bash
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   
   # Test connectivity
   k8s test-ingress your-host.local
   
   # Verify /etc/hosts entry
   echo "$(minikube ip) your-host.local" | sudo tee -a /etc/hosts
   ```

5. **Monitoring not working**:
   ```bash
   # Check monitoring namespace
   kubectl get pods -n monitoring
   
   # Reinstall if needed
   helm uninstall prometheus -n monitoring
   k8s enable-monitoring
   ```

### Performance Optimization

- **Increase minikube resources** for better performance:
  ```bash
  minikube config set memory 8192
  minikube config set cpus 4
  ```

- **Use SSD storage** for better I/O performance

- **Enable feature gates** for advanced Kubernetes features:
  ```bash
  minikube start --feature-gates="EphemeralContainers=true"
  ```

## 🎨 Advanced Usage Examples

### **Microservices Testing Setup**
```bash
# Setup complete microservices environment
k8s start
k8s enable-istio
k8s enable-monitoring
k8s create-dev-env microservices

# Generate multiple services
k8s generate-manifests user-service microservices
k8s generate-manifests order-service microservices
k8s generate-manifests payment-service microservices

# Deploy with ingress
k8s create-ingress api-gateway api.local user-service:80 microservices
```

### **CI/CD Pipeline Testing**
```bash
# Setup registry and dev environment
k8s setup-registry
k8s create-dev-env ci-cd

# Build and push custom image
docker build -t $(minikube ip):32000/myapp:v1.0 .
docker push $(minikube ip):32000/myapp:v1.0

# Deploy and test
k8s deploy myapp.yaml
k8s load-test http://myapp.local 1000 20
```

### **Security Testing**
```bash
# Setup secure environment
k8s create-network-policies production
k8s create-tls-ingress secure-app secure.local webapp-service:443 production

# Test security policies
kubectl run test-pod --rm -it --image=busybox -- wget -qO- webapp-service
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly with different scenarios
5. Submit a pull request

### Testing Your Changes

```bash
# Test basic functionality
k8s install
k8s start
k8s create-dev-env test
k8s generate-manifests test-app test
k8s enable-monitoring

# Test advanced features
k8s enable-istio
k8s load-test http://test-app.local
k8s backup-namespace test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Minikube](https://minikube.sigs.k8s.io/) - Local Kubernetes development
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) - Kubernetes command-line tool
- [Docker](https://www.docker.com/) - Container platform
- [Helm](https://helm.sh/) - Package manager for Kubernetes
- [Prometheus](https://prometheus.io/) - Monitoring and alerting toolkit
- [Grafana](https://grafana.com/) - Visualization and analytics platform
- [Istio](https://istio.io/) - Service mesh platform
- [Chaos Mesh](https://chaos-mesh.org/) - Chaos engineering platform
- [k9s](https://k9scli.io/) - Kubernetes CLI manager

## 📞 Support

If you encounter any issues or have questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Review the [commands reference](#-commands-reference)
3. Open an issue in the repository
4. Check individual tool documentation:
   - [Kubernetes Documentation](https://kubernetes.io/docs/)
   - [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
   - [Istio Documentation](https://istio.io/latest/docs/)

## 🚀 Roadmap

Future enhancements planned:
- ArgoCD for GitOps workflows
- Tekton for CI/CD pipelines  
- OPA (Open Policy Agent) for advanced policies
- Linkerd as alternative service mesh
- Multi-cluster support
- Cloud provider integration

---

**Happy Kubernetes development! 🎉**

> This tool transforms your local machine into a production-grade Kubernetes development environment with enterprise-level capabilities.

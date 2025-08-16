# Kubernetes Local Manager 2.0

A comprehensive, modular Kubernetes local development environment manager that provides both interactive menu-driven interface and command-line functionality.

## 🚀 Features

### Interactive Menu System
- **User-friendly interface**: Navigate through organized categories
- **Guided workflows**: Step-by-step prompts for all operations  
- **Quick setup wizards**: Pre-configured environments for different use cases

### Modular Architecture
- **21 Pre-built Components**: Storage, databases, messaging, search, monitoring
- **Quick Setup Wizards**: Complete environments in one command
- **Individual Deployment**: Deploy any component independently
- **Advanced Features**: Service mesh, monitoring, chaos engineering

### Component Categories
- **Storage & Caching** (4): Redis, Memcached, Hazelcast, MinIO
- **Databases** (5): PostgreSQL, MongoDB, MySQL, Cassandra, InfluxDB
- **Messaging** (5): Kafka, RabbitMQ, ActiveMQ Artemis, Apache Pulsar, Zookeeper
- **Vector & Search** (4): Weaviate, Qdrant, Elasticsearch, OpenSearch
- **Monitoring** (3): Prometheus, Grafana, Istio

## 📋 Prerequisites

The script automatically installs:
- Docker
- kubectl  
- minikube
- Helm
- k9s (Kubernetes CLI manager)

**System Requirements:**
- Ubuntu Linux (18.04+)
- 4GB RAM, 2 CPU cores (minimum)
- Internet connection

## 🎯 Quick Start

### 1. Installation
```bash
# Download and setup
wget https://raw.githubusercontent.com/pandaind/k8s-setup-manager/main/k8s_manager.sh
chmod +x k8s_manager.sh

# Install prerequisites and start
./k8s_manager.sh install
./k8s_manager.sh start
```

### 2. Interactive Mode (Recommended)
```bash
./k8s_manager.sh
```

### 3. Quick Wizards
```bash
./k8s_manager.sh wizard-complete-dev    # Complete development setup
./k8s_manager.sh wizard-microservices   # Microservices environment  
./k8s_manager.sh wizard-data-eng        # Data engineering stack
./k8s_manager.sh wizard-aiml            # AI/ML development
./k8s_manager.sh wizard-webapp          # Web application setup
```

## 📦 Available Components

### Storage & Caching
| Component | Command | Description | Access |
|-----------|---------|-------------|--------|
| **Redis** | `deploy-redis` | In-memory cache & session store | `redis:6379` |
| **Memcached** | `deploy-memcached` | High-performance caching system | `memcached:11211` |
| **Hazelcast** | `deploy-hazelcast` | In-memory data grid | `hazelcast:5701` |
| **MinIO** | `deploy-minio` | S3-compatible object storage | `minio:9000` |

### Databases  
| Component | Command | Description | Access |
|-----------|---------|-------------|--------|
| **PostgreSQL** | `deploy-postgresql` | Advanced relational database | `postgres:5432` |
| **MongoDB** | `deploy-mongodb` | Document database | `mongodb:27017` |
| **MySQL** | `deploy-mysql` | Popular relational database | `mysql:3306` |
| **Cassandra** | `deploy-cassandra` | Wide-column NoSQL database | `cassandra:9042` |
| **InfluxDB** | `deploy-influxdb` | Time-series database | `influxdb:8086` |

### Messaging Systems
| Component | Command | Description | Access |
|-----------|---------|-------------|--------|
| **Apache Kafka** | `deploy-kafka` | Event streaming platform | `kafka:9092` |
| **RabbitMQ** | `deploy-rabbitmq` | Feature-rich message broker | `rabbitmq:5672` |
| **ActiveMQ Artemis** | `deploy-artemis` | Enterprise messaging | `artemis:61616` |
| **Apache Pulsar** | `deploy-pulsar` | Cloud-native pub-sub | `pulsar:6650` |
| **Zookeeper** | `deploy-zookeeper` | Distributed coordination | `zookeeper:2181` |

### Vector & Search Engines
| Component | Command | Description | Access |
|-----------|---------|-------------|--------|
| **Weaviate** | `deploy-weaviate` | AI-native vector database | `weaviate:8080` |
| **Qdrant** | `deploy-qdrant` | High-performance vector search | `qdrant:6333` |
| **Elasticsearch** | `deploy-elasticsearch` | Search and analytics engine | `elasticsearch:9200` |
| **OpenSearch** | `deploy-opensearch` | Open-source search platform | `opensearch:9200` |

### Monitoring & Infrastructure
| Component | Command | Description | Access |
|-----------|---------|-------------|--------|
| **Prometheus** | `deploy-prometheus` | Metrics collection system | Multiple ports |
| **Grafana** | `deploy-grafana` | Visualization dashboards | Web UI |
| **Istio** | `enable-istio` | Service mesh platform | Multiple components |

## 🛠️ Usage Examples

### Cluster Management
```bash
# Basic cluster operations
./k8s_manager.sh start
./k8s_manager.sh status
./k8s_manager.sh stop
./k8s_manager.sh restart
```

### Individual Component Deployment
```bash
# Deploy individual components
./k8s_manager.sh deploy-redis development
./k8s_manager.sh deploy-postgresql databases
./k8s_manager.sh deploy-artemis messaging
./k8s_manager.sh deploy-weaviate vectordb
```

### Pre-configured Environments
```bash
# Basic development (Redis, PostgreSQL, MinIO)
./k8s_manager.sh create-dev-env development

# Extended databases (MongoDB, MySQL, Cassandra, InfluxDB)
./k8s_manager.sh create-database-env databases

# Messaging systems (Kafka, RabbitMQ, Artemis, Pulsar, Zookeeper)
./k8s_manager.sh create-messaging-env messaging

# Vector & search engines (Weaviate, Qdrant, Elasticsearch, OpenSearch)
./k8s_manager.sh create-vector-env vectordb
```

### Application Management
```bash
# Generate Kubernetes manifests
./k8s_manager.sh generate-manifests myapp development

# Deploy from YAML
./k8s_manager.sh deploy ./manifests-myapp/

# Scale applications
./k8s_manager.sh scale my-deployment 5 development
```

### Networking & Ingress
```bash
# Enable ingress controller
./k8s_manager.sh enable-ingress

# Create ingress rules
./k8s_manager.sh create-ingress myapp app.local myapp-service:80
./k8s_manager.sh create-tls-ingress secure-app secure.local myapp-service:80
```

### Monitoring & Advanced Features
```bash
# Enable monitoring stack (Prometheus + Grafana)
./k8s_manager.sh enable-monitoring

# Service mesh (Istio)
./k8s_manager.sh enable-istio

# Load testing
./k8s_manager.sh load-test http://app.local 1000 50

# Chaos engineering
./k8s_manager.sh enable-chaos
```

## 🎬 Complete Workflow Example

Here's a complete development workflow from setup to production-ready testing:

```bash
# 1. Initial setup
./k8s_manager.sh install
./k8s_manager.sh start

# 2. Enable advanced features
./k8s_manager.sh enable-monitoring
./k8s_manager.sh enable-ingress

# 3. Create complete development environment
./k8s_manager.sh wizard-complete-dev

# 4. Deploy your application
./k8s_manager.sh generate-manifests webapp development
cd manifests-webapp
./deploy.sh

# 5. Setup external access
./k8s_manager.sh create-ingress webapp-ingress webapp.local webapp-service:80

# 6. Performance testing
./k8s_manager.sh load-test http://webapp.local 1000 50

# 7. Monitor and debug
./k8s_manager.sh monitor-resources development
./k8s_manager.sh logs webapp-pod-xyz development
```

## 🎛️ Interactive Menu Navigation

When you run `./k8s_manager.sh` without arguments, you get an organized menu system:

```
1. Cluster Management
   - Start/stop/restart cluster
   - Status and health checks
   - Prerequisites installation

2. Development Environments  
   - Individual components (18 deployable components)
   - Pre-configured environments (4 options)
   - Quick setup wizards (5 options)

3. Application Management
   - Deploy applications
   - Generate manifests
   - Scale and manage

4. Networking & Ingress
   - Ingress management
   - Network policies
   - TLS certificates

5. Monitoring & Debugging
   - Resource monitoring (3 monitoring tools)
   - Service mesh
   - Load testing

6. Utilities & Tools
   - Backups
   - Security policies
   - Troubleshooting
```

## 🔧 Service Access Information

After deployment, services are accessible via:

### Internal Cluster Access
All services use their service names (e.g., `redis:6379`, `postgres:5432`)

### External Access (via NodePort)
- **MinIO Console**: `http://$(minikube ip):32001`
- **RabbitMQ Management**: `http://$(minikube ip):32672` 
- **Artemis Console**: `http://$(minikube ip):32161`
- **Weaviate UI**: `http://$(minikube ip):32080`
- **Qdrant UI**: `http://$(minikube ip):32333`

### Default Credentials
| Service | Username | Password |
|---------|----------|----------|
| MinIO | `minioadmin` | `minioadmin` |
| PostgreSQL | `devuser` | `devpass` |
| MongoDB | `admin` | `password123` |
| MySQL | `devuser` | `devpass123` |
| RabbitMQ | `admin` | `password123` |
| Artemis | `admin` | `password123` |

## 🛡️ Security Features

- **Network Policies**: Pod isolation and security
- **TLS Ingress**: Automatic SSL certificate generation
- **Namespace Isolation**: Resource separation
- **RBAC Ready**: Role-based access control configurations

## 🧪 Testing & Debugging

### Built-in Testing Tools
```bash
# Load testing with Apache Bench
./k8s_manager.sh load-test http://app.local 2000 100

# Chaos engineering
./k8s_manager.sh enable-chaos

# Real-time monitoring
./k8s_manager.sh monitor-resources development
```

### Debugging Commands
```bash
# View logs
./k8s_manager.sh logs pod-name development

# Execute in pods
./k8s_manager.sh exec pod-name development bash

# Port forwarding
./k8s_manager.sh port-forward service-name 8080:80 development
```

## 🔄 Backup & Recovery

```bash
# Backup namespace
./k8s_manager.sh backup-namespace development

# Backup entire cluster
./k8s_manager.sh backup
```

Backups are stored in `~/k8s-backups/` with automated restore scripts.

## 🆘 Troubleshooting

### Common Issues

1. **Docker Permission Denied**
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

2. **Minikube Won't Start**
   ```bash
   ./k8s_manager.sh delete
   ./k8s_manager.sh start
   ```

3. **Resource Constraints**
   ```bash
   minikube config set memory 8192
   minikube config set cpus 4
   ./k8s_manager.sh restart
   ```

4. **Ingress Not Accessible**
   ```bash
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   
   # Add to /etc/hosts
   echo "$(minikube ip) app.local" | sudo tee -a /etc/hosts
   ```

### Getting Help

```bash
# Check cluster status
./k8s_manager.sh status

# View all available commands
./k8s_manager.sh help

# Access Kubernetes dashboard
./k8s_manager.sh dashboard
```

## 📊 Commands Reference

### Core Commands
| Command | Description | Example |
|---------|-------------|---------|
| `install` | Install prerequisites | `./k8s_manager.sh install` |
| `start` | Start cluster | `./k8s_manager.sh start` |
| `stop` | Stop cluster | `./k8s_manager.sh stop` |
| `status` | Cluster status | `./k8s_manager.sh status` |

### Environment Setup
| Command | Description | Example |
|---------|-------------|---------|
| `create-dev-env [ns]` | Basic dev environment | `./k8s_manager.sh create-dev-env dev` |
| `create-database-env [ns]` | Extended databases | `./k8s_manager.sh create-database-env db` |
| `create-messaging-env [ns]` | Messaging systems | `./k8s_manager.sh create-messaging-env msg` |
| `create-vector-env [ns]` | Vector & search DBs | `./k8s_manager.sh create-vector-env ai` |

### Individual Components
| Command | Description | Example |
|---------|-------------|---------|
| `deploy-redis [ns]` | Deploy Redis cache | `./k8s_manager.sh deploy-redis cache` |
| `deploy-postgresql [ns]` | Deploy PostgreSQL | `./k8s_manager.sh deploy-postgresql db` |
| `deploy-kafka [ns]` | Deploy Kafka | `./k8s_manager.sh deploy-kafka messaging` |
| `deploy-weaviate [ns]` | Deploy Weaviate | `./k8s_manager.sh deploy-weaviate ai` |

### Wizards
| Command | Description | Example |
|---------|-------------|---------|
| `wizard-complete-dev` | Complete development | `./k8s_manager.sh wizard-complete-dev` |
| `wizard-microservices` | Microservices setup | `./k8s_manager.sh wizard-microservices` |
| `wizard-data-eng` | Data engineering | `./k8s_manager.sh wizard-data-eng` |
| `wizard-aiml` | AI/ML development | `./k8s_manager.sh wizard-aiml` |
| `wizard-webapp` | Web application | `./k8s_manager.sh wizard-webapp` |

### Advanced Features
| Command | Description | Example |
|---------|-------------|---------|
| `enable-monitoring` | Prometheus + Grafana | `./k8s_manager.sh enable-monitoring` |
| `enable-istio` | Service mesh | `./k8s_manager.sh enable-istio` |
| `enable-ingress` | Ingress controller | `./k8s_manager.sh enable-ingress` |
| `load-test [url] [req] [conc]` | Performance testing | `./k8s_manager.sh load-test http://app.local 1000 50` |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Test your changes thoroughly
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Kubernetes](https://kubernetes.io/) - Container orchestration
- [Minikube](https://minikube.sigs.k8s.io/) - Local Kubernetes
- [Docker](https://www.docker.com/) - Container platform  
- [Helm](https://helm.sh/) - Package manager for Kubernetes

---

**Transform your local machine into a production-grade Kubernetes development environment! 🚀**

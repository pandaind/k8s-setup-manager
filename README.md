# Kubernetes Local Manager

A comprehensive bash script for managing local Kubernetes clusters on Ubuntu Linux systems. This tool simplifies the entire lifecycle of local Kubernetes development - from installation to deployment and management.

## 🚀 Features

- **One-click setup**: Automatically installs Docker, kubectl, minikube, and Helm
- **Cluster lifecycle management**: Start, stop, restart, and delete clusters with simple commands
- **Application deployment**: Deploy and manage applications using YAML files
- **Namespace management**: Create and delete namespaces easily
- **Debugging tools**: Access logs, execute commands in pods, and port forwarding
- **Built-in dashboard**: Enable and access Kubernetes dashboard
- **Backup functionality**: Backup cluster configurations and resources
- **Safety features**: Confirmation prompts for destructive operations
- **Colored output**: Easy-to-read console output with color coding

## 📋 Prerequisites

- Ubuntu Linux (18.04 or later)
- Internet connection for downloading components
- Sudo privileges for installation

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

### Namespace Operations

```bash
# Create a new namespace
k8s create-ns my-application

# Delete a namespace (with confirmation)
k8s delete-ns my-application
```

### Application Management

```bash
# Deploy application from YAML file
k8s deploy app.yaml

# Remove deployed application
k8s delete-app app.yaml

# Get all resources in default namespace
k8s get-all

# Get all resources in specific namespace
k8s get-all my-namespace

# Scale a deployment
k8s scale my-deployment 3 my-namespace
```

### Debugging and Development

```bash
# View pod logs
k8s logs my-pod-name my-namespace

# Follow pod logs in real-time
k8s logs my-pod-name my-namespace follow

# Execute command in a pod
k8s exec my-pod-name my-namespace

# Execute specific command in a pod
k8s exec my-pod-name my-namespace "ls -la"

# Port forward to access services locally
k8s port-forward my-service 8080:80 my-namespace
```

### Dashboard and Monitoring

```bash
# Enable Kubernetes dashboard
k8s enable-dashboard

# Open dashboard in browser
k8s dashboard
```

### Backup and Maintenance

```bash
# Backup cluster configuration and resources
k8s backup
```

## 🎯 Quick Start Example

Here's a complete workflow from setup to deployment:

```bash
# 1. Install everything
k8s install

# 2. Start cluster
k8s start

# 3. Create a namespace for your application
k8s create-ns webapp

# 4. Deploy your application (assuming you have app.yaml)
k8s deploy app.yaml

# 5. Check if everything is running
k8s get-all webapp

# 6. Scale your deployment if needed
k8s scale webapp-deployment 3 webapp

# 7. Access your application
k8s port-forward webapp-service 8080:80 webapp

# 8. Check logs if there are issues
k8s logs webapp-pod-xyz webapp follow

# 9. Access pod for debugging
k8s exec webapp-pod-xyz webapp
```

## 📁 Example YAML Files

### Simple Nginx Deployment

Create `nginx-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: webapp
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

Deploy it:
```bash
k8s create-ns webapp
k8s deploy nginx-app.yaml
k8s port-forward nginx-service 8080:80 webapp
```

## 🛠️ Configuration

The script uses these default configurations:

- **Cluster Name**: `local-k8s`
- **Minikube Driver**: `docker`
- **Default CPU**: 2 cores
- **Default Memory**: 2GB
- **Kubeconfig Path**: `~/.kube/config`
- **Backup Location**: `~/k8s-backups/`

## 📊 Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `install` | Install prerequisites | `k8s install` |
| `start` | Start cluster | `k8s start` |
| `stop` | Stop cluster | `k8s stop` |
| `restart` | Restart cluster | `k8s restart` |
| `delete` | Delete cluster | `k8s delete` |
| `status` | Show cluster status | `k8s status` |
| `create-ns <name>` | Create namespace | `k8s create-ns myapp` |
| `delete-ns <name>` | Delete namespace | `k8s delete-ns myapp` |
| `deploy <file>` | Deploy from YAML | `k8s deploy app.yaml` |
| `delete-app <file>` | Delete from YAML | `k8s delete-app app.yaml` |
| `get-all [namespace]` | List resources | `k8s get-all myapp` |
| `scale <deploy> <count> [ns]` | Scale deployment | `k8s scale web 3 myapp` |
| `logs <pod> [ns] [follow]` | View logs | `k8s logs web-123 myapp follow` |
| `exec <pod> [ns] [cmd]` | Execute in pod | `k8s exec web-123 myapp bash` |
| `port-forward <svc> <ports> [ns]` | Port forward | `k8s port-forward web 8080:80 myapp` |
| `enable-dashboard` | Enable dashboard | `k8s enable-dashboard` |
| `dashboard` | Open dashboard | `k8s dashboard` |
| `backup` | Backup config | `k8s backup` |
| `help` | Show help | `k8s help` |

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

3. **kubectl command not found**:
   ```bash
   k8s install  # Reinstall prerequisites
   ```

4. **Port already in use**:
   ```bash
   # Kill process using the port
   sudo lsof -ti:8080 | xargs kill -9
   ```

### Logs and Debugging

- Check script logs: The script provides colored output for easy debugging
- Check minikube logs: `minikube logs`
- Check kubectl connectivity: `kubectl cluster-info`
- Verify Docker: `docker ps`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly with different scenarios
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Minikube](https://minikube.sigs.k8s.io/) - Local Kubernetes development
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) - Kubernetes command-line tool
- [Docker](https://www.docker.com/) - Container platform
- [Helm](https://helm.sh/) - Package manager for Kubernetes

## 📞 Support

If you encounter any issues or have questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Review the [commands reference](#-commands-reference)
3. Open an issue in the repository
4. Check Kubernetes and minikube documentation

---

**Happy Kubernetes development! 🎉**

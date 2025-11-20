# Swimlane DevOps Practical Helm Chart

This Helm chart deploys the Swimlane DevOps Practical application along with MongoDB as a StatefulSet with persistent storage. The chart is optimized for local development and production deployments.

## Chart Structure

```
helm-charts/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── templates/              # Kubernetes manifest templates
│   ├── _helpers.tpl       # Template helpers and functions
│   ├── app-deployment.yaml # Application deployment
│   ├── app-service.yaml   # Application service
│   ├── app-serviceaccount.yaml # Application service account
│   ├── app-hpa.yaml       # Horizontal Pod Autoscaler
│   ├── app-ingress.yaml   # Ingress configuration
│   ├── mongodb-statefulset.yaml # MongoDB StatefulSet
│   ├── mongodb-service.yaml # MongoDB service
│   ├── mongodb-serviceaccount.yaml # MongoDB service account
│   └── secret.yaml        # Secrets for MongoDB connection
└── README.md              # This file
```

## Features

- **Application Deployment**: Node.js Express application with optimized Docker image
- **MongoDB StatefulSet**: Persistent MongoDB database with PVC
- **Security**: Non-root user, security contexts, and least privilege
- **Resource Optimization**: Configurable resource limits and requests
- **Auto-scaling**: Optional HPA for application pods
- **Health Checks**: Liveness, readiness, and startup probes
- **Init Container**: Waits for MongoDB to be ready before starting app
- **Persistent Storage**: MongoDB data persists across pod restarts

## Prerequisites

1. Kubernetes cluster (1.19+)
2. kubectl configured to access your cluster
3. Helm 3.x installed
4. Storage class available for PVCs (for MongoDB)
5. Docker image built and available in your cluster

## Installation

### Quick Start

```bash
# Build the Docker image first
cd /path/to/devops-practical
docker build -t swimlane-devops-practical:latest .

# Install the chart
helm install swimlane-app ./helm-charts \
  --namespace devops-practical \
  --create-namespace
```

### Custom Installation

```bash
# Install with custom values
helm install swimlane-app ./helm-charts \
  --namespace devops-practical \
  --create-namespace \
  --set app.replicaCount=2 \
  --set mongodb.persistence.size=5Gi
```

### Using a Values File

```bash
# Create a custom values file
cat > my-values.yaml <<EOF
app:
  replicaCount: 2
  resources:
    limits:
      cpu: 500m
      memory: 512Mi

mongodb:
  persistence:
    size: 5Gi
EOF

# Install with custom values
helm install swimlane-app ./helm-charts \
  --namespace devops-practical \
  --create-namespace \
  -f my-values.yaml
```

## Configuration

### Application Configuration

The application can be configured through the `app` section in `values.yaml`:

```yaml
app:
  replicaCount: 1                    # Number of application replicas
  image:
    repository: swimlane-devops-practical
    pullPolicy: Never                # ImagePullPolicy
    tag: "latest"
  service:
    type: ClusterIP                  # Service type
    port: 3000                       # Service port
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 50m
      memory: 128Mi
  autoscaling:
    enabled: false                   # Enable HPA
    minReplicas: 1
    maxReplicas: 2
```

### MongoDB Configuration

MongoDB is configured through the `mongodb` section:

```yaml
mongodb:
  enabled: true                      # Enable/disable MongoDB
  replicaCount: 1                    # Number of MongoDB replicas
  image:
    repository: mongo
    tag: "latest"
  persistence:
    enabled: true                    # Enable persistent storage
    storageClass: ""                 # Storage class (empty = default)
    accessMode: ReadWriteOnce
    size: 2Gi                        # Storage size
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 50m
      memory: 128Mi
  database: "database"               # Database name
```

## Key Features Explained

### Init Container

The application deployment includes an init container that waits for MongoDB to be ready:

```yaml
initContainers:
  - name: wait-for-mongodb
    image: mongo:latest
    command:
      - sh
      - -c
      - |
        until mongosh --host swimlane-app-mongodb --port 27017 \
          --eval "db.adminCommand('ping')" --quiet; do
          sleep 3
        done
```

This ensures the application only starts after MongoDB is fully ready to accept connections.

### Persistent Storage

MongoDB uses a StatefulSet with a PersistentVolumeClaim:

- **Storage Class**: Uses default storage class if not specified
- **Access Mode**: ReadWriteOnce (single node access)
- **Size**: Configurable (default: 2Gi)
- **Persistence**: Data survives pod restarts and deletions

### Security

- **Non-root user**: Application runs as user ID 1001
- **Security contexts**: Pod and container security contexts configured
- **Capabilities**: All capabilities dropped
- **Secrets**: MongoDB connection string stored in Kubernetes secrets

### Health Checks

- **Startup Probe**: Gives app time to start and connect to MongoDB
- **Liveness Probe**: Ensures app is still running
- **Readiness Probe**: Ensures app is ready to serve traffic

## Upgrading

```bash
# Upgrade with new values
helm upgrade swimlane-app ./helm-charts \
  --namespace devops-practical \
  -f my-values.yaml

# Upgrade with inline values
helm upgrade swimlane-app ./helm-charts \
  --namespace devops-practical \
  --set app.replicaCount=3
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall swimlane-app --namespace devops-practical

# Note: PVCs are not deleted by default. To delete them:
kubectl delete pvc -n devops-practical -l app.kubernetes.io/instance=swimlane-app
```

## Verification

After installation, verify the deployment:

```bash
# Check pods
kubectl get pods -n devops-practical

# Check services
kubectl get svc -n devops-practical

# Check PVCs
kubectl get pvc -n devops-practical

# Check application logs
kubectl logs -n devops-practical -l app.kubernetes.io/component=app

# Check MongoDB logs
kubectl logs -n devops-practical -l app.kubernetes.io/component=mongodb

# Test application connectivity
kubectl port-forward -n devops-practical svc/swimlane-app-app 3000:3000
curl http://localhost:3000
```

## Troubleshooting

### Application Pods Not Starting

1. **Check init container logs**:
   ```bash
   kubectl logs -n devops-practical <pod-name> -c wait-for-mongodb
   ```

2. **Verify MongoDB is ready**:
   ```bash
   kubectl get pods -n devops-practical -l app.kubernetes.io/component=mongodb
   kubectl exec -n devops-practical <mongodb-pod> -- mongosh --eval "db.adminCommand('ping')"
   ```

3. **Check application logs**:
   ```bash
   kubectl logs -n devops-practical <pod-name> --tail=50
   ```

### MongoDB Connection Issues

1. **Verify secret exists**:
   ```bash
   kubectl get secret -n devops-practical swimlane-app-secret
   kubectl get secret -n devops-practical swimlane-app-secret -o jsonpath='{.data.MONGODB_URL}' | base64 -d
   ```

2. **Check service connectivity**:
   ```bash
   kubectl get svc -n devops-practical swimlane-app-mongodb
   kubectl exec -n devops-practical <app-pod> -- nslookup swimlane-app-mongodb
   ```

### PVC Issues

1. **Check PVC status**:
   ```bash
   kubectl get pvc -n devops-practical
   kubectl describe pvc -n devops-practical mongo-data-swimlane-app-mongodb-0
   ```

2. **Verify storage class**:
   ```bash
   kubectl get storageclass
   ```

### Resource Constraints

If pods are being evicted or not starting:

1. **Check node resources**:
   ```bash
   kubectl top nodes
   kubectl top pods -n devops-practical
   ```

2. **Adjust resource requests/limits** in `values.yaml`

## Configuration Reference

### All Available Values

See `values.yaml` for the complete list of configurable values. Key sections:

- `app.*` - Application configuration
- `mongodb.*` - MongoDB configuration
- `nameOverride` - Override chart name
- `fullnameOverride` - Override full name

## Best Practices

1. **Resource Limits**: Always set appropriate resource limits
2. **Storage**: Use appropriate storage class for your environment
3. **Backups**: Regularly backup MongoDB data
4. **Monitoring**: Set up monitoring and alerting
5. **Security**: Review security contexts and network policies
6. **Scaling**: Use HPA for automatic scaling based on metrics

## Local Development

For local development (e.g., Rancher Desktop, Minikube):

```yaml
# values-local.yaml
app:
  replicaCount: 1
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 50m
      memory: 128Mi
  image:
    pullPolicy: Never  # Use local image

mongodb:
  persistence:
    size: 2Gi
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 50m
      memory: 128Mi
```

Install with:
```bash
helm install swimlane-app ./helm-charts -f values-local.yaml -n devops-practical --create-namespace
```

## Production Considerations

1. **High Availability**: Increase replica counts
2. **Resource Sizing**: Adjust based on load testing
3. **Storage**: Use appropriate storage class
4. **Backups**: Implement regular MongoDB backups
5. **Monitoring**: Set up Prometheus/Grafana
6. **Logging**: Centralize logs with ELK or similar
7. **Security**: Enable network policies, use private registries
8. **Ingress**: Configure proper ingress with TLS

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [MongoDB on Kubernetes](https://www.mongodb.com/kubernetes)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review application and MongoDB logs
3. Verify Kubernetes resources are properly configured
4. Check Helm release status: `helm status swimlane-app -n devops-practical`


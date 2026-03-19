# SysML v2 Jupyter Helm Chart

A production-ready Helm chart for deploying SysML v2 Jupyter Notebook on Kubernetes and OpenShift.

## Features

- **OpenShift Compatible**: Fully compatible with OpenShift's restricted Security Context Constraints (SCC)
- **High Availability**: Pod Disruption Budgets and pod anti-affinity for reliable deployments
- **Security-First**: Non-root execution, read-only capabilities, RBAC, and network policies support
- **Health Checks**: Startup, liveness, and readiness probes with configurable thresholds
- **Persistent Storage**: Optional PVC for preserving notebooks and data across pod restarts
- **Scalability**: Horizontal Pod Autoscaler (HPA) support for dynamic scaling
- **OpenShift Routes**: Native OpenShift route support with TLS termination
- **Production Ready**: Resource requests/limits, pod disruption budgets, and graceful shutdown

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.6+
- Helm 3.0+
- For persistent storage, a StorageClass must be available in your cluster

## Quick Start

### Basic Installation

```bash
helm install sysml-jupyter ./helm
```

### Installation with Persistence

```bash
helm install sysml-jupyter ./helm \
  --set persistence.enabled=true \
  --set persistence.storageClassName=standard \
  --set persistence.size=20Gi
```

### Installation on OpenShift with Route and Persistence

```bash
helm install sysml-jupyter ./helm \
  --set route.enabled=true \
  --set route.host=sysml-jupyter.apps.example.com \
  --set persistence.enabled=true \
  --set persistence.storageClassName=fast \
  --set persistence.size=50Gi
```

### High Availability Deployment

```bash
helm install sysml-jupyter ./helm \
  --set replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10 \
  --set persistence.enabled=true
```

## Configuration

### Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `replicaCount` | int | `2` | Number of deployment replicas (min 2 for production) |
| `image.tag` | string | `latest` | Container image tag (use specific versions for production) |
| `image.pullPolicy` | string | `IfNotPresent` | Image pull policy (IfNotPresent, Always, or Never) |
| `service.type` | string | `ClusterIP` | Service type (ClusterIP, NodePort, or LoadBalancer) |
| `service.port` | int | `8888` | Service port |
| `resources.requests.cpu` | string | `500m` | CPU request per pod |
| `resources.requests.memory` | string | `512Mi` | Memory request per pod |
| `resources.limits.cpu` | string | `2000m` | CPU limit per pod |
| `resources.limits.memory` | string | `2Gi` | Memory limit per pod |
| `persistence.enabled` | bool | `false` | Enable persistent storage |
| `persistence.size` | string | `10Gi` | Persistent volume size |
| `autoscaling.enabled` | bool | `false` | Enable Horizontal Pod Autoscaler |
| `autoscaling.minReplicas` | int | `2` | Minimum replicas for HPA |
| `autoscaling.maxReplicas` | int | `5` | Maximum replicas for HPA |
| `podDisruptionBudget.enabled` | bool | `true` | Enable Pod Disruption Budget |
| `podDisruptionBudget.minAvailable` | int | `1` | Minimum available replicas during disruption |

For a complete list of parameters, see `values.yaml`.

## Production Recommendations

### Replica Count and Scalability

```yaml
# For HA deployments, use at least 3 replicas
replicaCount: 3

# Enable automatic scaling based on CPU usage
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Persistent Storage

```yaml
# Always enable persistence for production workloads
persistence:
  enabled: true
  storageClassName: fast-ssd  # Use your cluster's StorageClass
  size: 50Gi
  accessMode: ReadWriteOnce
```

### Resource Management

```yaml
# Adjust resource requests/limits based on your workload
resources:
  requests:
    cpu: 1000m        # Minimum CPU guarantee
    memory: 1Gi       # Minimum memory guarantee
  limits:
    cpu: 4000m        # Maximum CPU allowed
    memory: 4Gi       # Maximum memory allowed
```

### Node Affinity and Tolerations

```yaml
# Spread pods across different nodes
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - sysml-jupyter
          topologyKey: kubernetes.io/hostname

# Schedule on specific node types
nodeSelector:
  node.kubernetes.io/instance-type: "compute-optimized"

# Tolerate node taints
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "jupyter"
    effect: "NoSchedule"
```

## Security

### Default Security Settings

- **Non-root Execution**: Containers run as UID 1010, GID 100
- **Capability Dropping**: All Linux capabilities are dropped by default
- **Read-only Root**: Root filesystem remains writable for `/home/jovyan/work`
- **Security Context Constraints**: Compatible with OpenShift's restricted SCC
- **RBAC**: Minimal permissions through ServiceAccount and Role

### Secrets Management

For sensitive data (API keys, credentials), use Kubernetes Secrets:

```bash
# Create a secret
kubectl create secret generic jupyter-credentials \
  --from-literal=api-key=your-api-key \
  --from-literal=token=your-token

# Mount in deployment via values.yaml
env:
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: jupyter-credentials
        key: api-key
```

### Network Policies

For network isolation, implement NetworkPolicy (example):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sysml-jupyter-netpol
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: sysml-jupyter
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 8888
  egress:
    - to:
        - podSelector: {}
```

## Monitoring and Observability

### Health Checks

The chart includes three probes:

- **Startup Probe**: Waits up to 5 minutes for application initialization
- **Liveness Probe**: Checks every 10 seconds; restarts after 3 failures
- **Readiness Probe**: Checks every 5 seconds; removes from load balancer after 2 failures

### Logging

Access logs from running pods:

```bash
# View logs from a specific pod
kubectl logs -f <pod-name>

# View logs from all pods in the deployment
kubectl logs -f -l app.kubernetes.io/name=sysml-jupyter
```

### Prometheus Monitoring (Optional)

To scrape metrics from Jupyter:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sysml-jupyter-metrics
  labels:
    app: sysml-jupyter
spec:
  selector:
    app.kubernetes.io/name: sysml-jupyter
  ports:
    - name: metrics
      port: 8888
      targetPort: 8888
```

## Upgrade and Updates

### Helm Upgrade

```bash
# Upgrade the release with new values
helm upgrade sysml-jupyter ./helm \
  --set image.tag=v1.1.0 \
  --set persistence.size=50Gi
```

### Version Compatibility

- Chart Version 1.0.0 is compatible with SysML v2 1.0.0+
- Check `Chart.yaml` for the application version compatibility

### Backup Before Upgrades

If using persistent storage:

```bash
# Backup persistent data before upgrading
kubectl exec <pod-name> -- tar czf /tmp/backup.tar.gz /home/jovyan/work
kubectl cp <pod-name>:/tmp/backup.tar.gz ./backup.tar.gz
```

## Troubleshooting

### Pod Not Starting

1. Check pod status:
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name> --previous  # For crashed pods
   ```

2. Verify security context:
   ```bash
   # Check if pod is running as non-root
   kubectl exec <pod-name> -- id
   ```

3. Check resource constraints:
   ```bash
   kubectl describe nodes
   kubectl top pods
   ```

### Readiness/Liveness Probe Failures

```bash
# Test the probe endpoint manually
kubectl exec <pod-name> -- curl -v http://localhost:8888/lab

# Increase initial delay if application needs more startup time
helm upgrade sysml-jupyter ./helm \
  --set startupProbe.initialDelaySeconds=30 \
  --set startupProbe.failureThreshold=20
```

### Persistent Volume Not Mounting

```bash
# Check PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# Verify StorageClass exists
kubectl get storageclass
```

### OpenShift Route Not Accessible

```bash
# Check route status
oc get route
oc describe route sysml-jupyter

# Verify service endpoints
kubectl get endpoints
```

### Out of Memory Issues

Increase memory limits:

```bash
helm upgrade sysml-jupyter ./helm \
  --set resources.requests.memory=2Gi \
  --set resources.limits.memory=4Gi
```

### High CPU Usage

```bash
# Check CPU metrics
kubectl top pod <pod-name>

# Enable HPA and increase limits
helm upgrade sysml-jupyter ./helm \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=10 \
  --set resources.limits.cpu=4000m
```

## Uninstallation

```bash
# Delete the Helm release
helm uninstall sysml-jupyter

# Note: Persistent volumes are not automatically deleted
# Delete PVC manually if needed:
kubectl delete pvc sysml-jupyter
```

## Chart Validation

Use `helm lint` to validate the chart:

```bash
helm lint ./helm
helm template sysml-jupyter ./helm | kubeval
```

## Support and Contributing

For issues, feature requests, or contributions, please visit:
- GitHub: [OMG-SysML-v2/jupyter](https://github.com/OMG-SysML-v2/jupyter)
- Documentation: [SysML v2 Official Docs](https://www.omg.org/spec/SysML/2.0)

## License

See [LICENSE](../LICENSE) for details.

| `replicaCount` | 1 | Number of replicas |
| `image.registry` | quay.io | Container registry |
| `image.repository` | jupyter/minimal-notebook | Image repository |
| `image.tag` | latest | Image tag |
| `service.type` | ClusterIP | Kubernetes Service type |
| `service.port` | 8888 | Service port |
| `resources.requests.cpu` | 500m | Requested CPU |
| `resources.requests.memory` | 512Mi | Requested memory |
| `resources.limits.cpu` | 2000m | CPU limit |
| `resources.limits.memory` | 2Gi | Memory limit |
| `persistence.enabled` | false | Enable persistent storage |
| `persistence.size` | 10Gi | Storage size |
| `route.enabled` | false | Enable OpenShift route |

### Security Context

The chart is configured with the following security settings (OpenShift compatible):

- **Non-root user**: Runs as UID 1010, GID 0
- **Dropped capabilities**: All Linux capabilities dropped
- **Read-only filesystem**: Disabled by default (enable if needed)
- **No privilege escalation**: Disabled

### Full Values Example

```yaml
replicaCount: 1

image:
  registry: quay.io
  repository: jupyter/minimal-notebook
  tag: "latest"

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi

persistence:
  enabled: true
  storageClassName: standard
  size: 20Gi
  mountPath: /home/jovyan/work

route:
  enabled: true
  host: sysml-jupyter.apps.example.com
  tls:
    enabled: true
    termination: edge
```

## Usage

After installation, access the Jupyter Lab:

### On Kubernetes with Port Forward

```bash
kubectl port-forward svc/sysml-jupyter 8888:8888
# Then open http://localhost:8888
```

### On OpenShift with Route

The route created will be accessible at the configured host URL.

## Uninstallation

```bash
helm uninstall sysml-jupyter
```

## Troubleshooting

### Check pod status
```bash
kubectl get pods -l app.kubernetes.io/name=sysml-jupyter
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check if using OpenShift restricted SCC
```bash
oc describe pod <pod-name> | grep scc
```

### Verify security context
```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'
```

## Notes

- The chart uses the official Jupyter minimal-notebook image from Quay.io
- OpenShift will inject its own UID/GID values; the chart defaults are compatible with typical OpenShift configurations
- For persistent notebooks, ensure your storage class supports ReadWriteOnce access mode
- The health checks probe the `/lab` endpoint, which requires JupyterLab to be running

## License

Same as the parent project

# SysML v2 Jupyter Helm Chart

This Helm chart deploys the SysML v2 Jupyter Notebook on Kubernetes and OpenShift.

## Features

- **OpenShift Compatible**: Configured with security contexts suitable for OpenShift's restricted SCC
- **Resource Management**: Configurable CPU and memory limits
- **Persistent Storage**: Optional PVC for preserving notebooks and data
- **Health Checks**: Liveness and readiness probes configured
- **OpenShift Routes**: Support for OpenShift routes for easy access
- **Scalability**: Supports optional HPA (Horizontal Pod Autoscaler)

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.6+
- Helm 3.0+

## Installation

### Basic Installation (Kubernetes)

```bash
helm install sysml-jupyter ./helm
```

### Installation on OpenShift with Route

```bash
helm install sysml-jupyter ./helm \
  --set route.enabled=true \
  --set route.host=sysml-jupyter.apps.example.com
```

### Installation with Persistent Storage

```bash
helm install sysml-jupyter ./helm \
  --set persistence.enabled=true \
  --set persistence.storageClassName=standard \
  --set persistence.size=20Gi
```

## Configuration

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
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

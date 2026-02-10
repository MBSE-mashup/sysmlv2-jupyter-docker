# Quick Start Guide - SysML Jupyter Helm Chart

## Installation Commands

### 1. Basic Kubernetes Installation
```bash
cd helm/
helm install sysml-jupyter . --namespace default
```

### 2. OpenShift Installation (with external route)
```bash
helm install sysml-jupyter . \
  --namespace sysml-project \
  --set route.enabled=true \
  --set route.host=sysml-jupyter.apps.your-openshift.com
```

### 3. Production OpenShift (with persistence and TLS)
```bash
helm install sysml-jupyter . \
  --namespace sysml-project \
  -f examples/openshift-production.yaml \
  --set route.host=sysml-jupyter.apps.your-openshift.com
```

### 4. High Availability (with autoscaling)
```bash
helm install sysml-jupyter . \
  --namespace sysml-project \
  -f examples/ha-custom-image.yaml \
  --set route.host=sysml-jupyter.apps.your-openshift.com
```

## Verification Commands

### Check deployment status
```bash
kubectl get all -l app.kubernetes.io/name=sysml-jupyter
```

### Check logs
```bash
kubectl logs -l app.kubernetes.io/name=sysml-jupyter -f
```

### Port-forward to access locally (Kubernetes)
```bash
kubectl port-forward svc/sysml-jupyter 8888:8888
# Access at http://localhost:8888
```

### Get OpenShift route URL
```bash
oc get route sysml-jupyter -o jsonpath='{.spec.host}'
```

### Check pod security context (OpenShift)
```bash
oc describe pod <pod-name> | grep -A 5 "Security Context"
```

## Upgrade Commands

### Upgrade to new image version
```bash
helm upgrade sysml-jupyter . --set image.tag=2025-12
```

### Upgrade with persistence enabled
```bash
helm upgrade sysml-jupyter . --set persistence.enabled=true
```

## Uninstall

```bash
helm uninstall sysml-jupyter
```

## Troubleshooting

### View helm values currently deployed
```bash
helm get values sysml-jupyter
```

### View helm templates (what will be deployed)
```bash
helm template sysml-jupyter .
```

### Perform a dry-run to check for errors
```bash
helm install sysml-jupyter . --dry-run --debug
```

### Check if OpenShift is using restricted SCC
```bash
oc describe pod <pod-name> | grep openshift.io/scc
```

### Check PVC status (if using persistence)
```bash
kubectl get pvc
kubectl describe pvc sysml-jupyter
```

## Configuration Tips

### Use custom storage class
```bash
helm install sysml-jupyter . \
  --set persistence.enabled=true \
  --set persistence.storageClassName=my-storage-class
```

### Set resource limits for high memory usage
```bash
helm install sysml-jupyter . \
  --set resources.limits.memory=4Gi \
  --set resources.requests.memory=2Gi
```

### Enable read-only filesystem (most restrictive)
```bash
# Modify values.yaml or override:
--set securityContext.readOnlyRootFilesystem=true
```

## File Structure

```
helm/
├── Chart.yaml                          # Chart metadata
├── values.yaml                         # Default values
├── README.md                           # Full documentation
├── templates/
│   ├── _helpers.tpl                   # Template helpers
│   ├── deployment.yaml                # Main deployment
│   ├── service.yaml                   # Kubernetes service
│   ├── serviceaccount.yaml            # Service account
│   ├── pvc.yaml                       # Persistent volume claim
│   ├── route.yaml                     # OpenShift route
│   └── hpa.yaml                       # Horizontal pod autoscaler
└── examples/
    ├── kubernetes-basic.yaml          # Basic Kubernetes setup
    ├── openshift-production.yaml      # Production OpenShift config
    └── ha-custom-image.yaml           # High availability setup
```

## Security Notes

- Chart is configured for OpenShift's restricted SCC by default
- All containers run as non-root (UID 1010, GID 0)
- No Linux capabilities are granted
- Read-only root filesystem can be enabled in production
- SELinux contexts are handled automatically by OpenShift

## Support

For issues or questions:
1. Check the main README.md documentation
2. Review example configuration files
3. Run `helm lint helm/` to check for chart errors
4. Check pod logs with `kubectl logs <pod-name>`

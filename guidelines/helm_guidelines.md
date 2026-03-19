# Quality guideline for helm charts

## Health & Reliability

- include readyness and other probes
  - **Startup Probe**: Waits for app initialization; disables other probes until ready
  - **Liveness Probe**: Detects dead/hung containers; triggers restart
  - **Readiness Probe**: Indicates if pod can serve traffic; controls load balancing
- for deployments that rely on persistent storage, e.g. database or other application that stores data
  to a PVC, do not use RollingUpdate strategy, instead use Recreate
- for long and fragile initialization of applications, consider to use a startup or migration job instead of initialization by the actual deployment
- ensure the helm chart is clean according to `helm lint`
- implement pod disruption budgets (PDB) for high-availability deployments
- set appropriate terminationGracePeriodSeconds for graceful shutdowns

## Resource Management

- allow resource configurations for all services, not only for the main service, but e.g. also for the database
- define both `requests` and `limits` for CPU and memory on all containers
- use small default values (`requests`) and document how to adjust for production workloads
- configure resource quotas and namespace limits to prevent resource exhaustion
- use `securityContext` to enforce non-root users and drop unnecessary capabilities

## Configuration & Values

- create a `values.schema.json` to document and validate configuration parameters
- keep `values.yaml` as the single source of truth; derive schema and examples from it
- provide example values files in `examples/` directory for common deployment patterns
- add helpful comments and descriptions in `values.yaml`
- use consistent naming conventions (camelCase or snake_case) for all parameters
- avoid hardcoding values; expose all configurable items through `values.yaml`

## Security

- implement RBAC: create ServiceAccount, Role, and RoleBinding with minimal required permissions
- use network policies to restrict ingress/egress traffic between pods
- scan container images for vulnerabilities before deployment
- set `imagePullPolicy: IfNotPresent` to use cached images and reduce registry load
- use image digests (SHA256) in addition to tags for reproducibility
- encrypt sensitive data (use Kubernetes Secrets, not ConfigMaps)
- avoid running containers as root; use `securityContext.runAsNonRoot: true`

## High Availability & Scalability

- support horizontal pod autoscaling (HPA) through templates and documentation
- use anti-affinity rules to spread replicas across nodes: `podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution`
- set `replicaCount: >= 2` for production deployments
- implement proper shutdown hooks in application code; respect terminationGracePeriodSeconds
- avoid single points of failure (e.g., replicate databases, caches)

## Observability & Monitoring

- expose readiness/liveness probe endpoints as monitoring endpoints
- provide Prometheus scrape configurations if applicable
- document logging levels and how to configure them
- include examples of ServiceMonitor or PrometheusRule if monitoring is critical

## Updates & Upgrades

- document upgrade paths and any breaking changes between versions
- use pre-upgrade and pre-delete lifecycle hooks for data migrations if needed
- test upgrade paths thoroughly (before major version bumps)
- version the chart according to semantic versioning in `Chart.yaml`

## Testing & Validation

- lint chart with `helm lint` and fix all warnings
- validate generated manifests with `kubeval` or similar
- test with `helm template` to verify variable substitution
- provide test cases or test values that verify common configurations
- test on both Kubernetes and OpenShift (if targeting both)

## Documentation

- include detailed README.md with installation and configuration instructions
- document all non-obvious parameters and their effects
- provide examples for common scenarios (basic deployment, high-availability, with persistence, OpenShift-specific, etc.)
- document secrets and environment variables that the application requires
- include troubleshooting section for common issues

## Chart Structure & Organization

- organize templates logically: `templates/{deployment,service,configmap,etc}.yaml`
- use `_helpers.tpl` for common template functions and labels
- keep templates DRY by abstracting repeated patterns
- use `helm dependency update` if depending on other charts (maintain `Chart.lock`)
- document dependencies and their purpose

## OpenShift-Specific Best Practices

- ensure compatibility with restricted Security Context Constraints (SCC)
- test pod with `runAsNonRoot: true` and no root filesystem write access
- provide support for OpenShift Routes alongside Ingress resources
- document required RBAC permissions for OpenShift service accounts
- avoid `/root` and other root-owned directories in container filesystem
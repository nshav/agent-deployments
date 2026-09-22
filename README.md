# agent-deployments

GitOps source of truth for the rate-limiter **data plane**. Argo CD watches this
repository and deploys one rate-limiter agent per node folder into the cluster.
You normally don't edit it by hand — the admin panel (`admin-backend`) commits
here when a node is created or deleted.

```
admin panel ──(commit values.yaml)──▶ this repo ──(Argo CD ApplicationSet)──▶ cluster
```

## Layout

```
charts/
  agent/                       # the single, shared Helm chart for an agent
    Chart.yaml
    values.yaml                # defaults only (empty placeholders)
    templates/                 # Deployment, Service, ConfigMap, Secret, Ingress, Namespace
agents/
  <client>/<node>/values.yaml  # one file per node = one agent deployment
```

- `charts/agent/` is the only copy of the chart. Every node reuses it.
- `agents/<client>/<node>/values.yaml` holds just the per-node overrides.
  `<client>` is the account id, `<node>` is the node id — so the path is
  `agents/<accountID>/<nodeID>/values.yaml`.

## How Argo CD consumes it

An `ApplicationSet` (defined in the `infrastructure` repo, `modules/argo`) uses a
git **directory generator** with the glob `agents/*/*`. Each matching folder
becomes one Argo `Application`:

- **name / namespace**: `agent-<client>-<node>` (each node gets its own
  namespace, because the chart's resource names are fixed per release).
- **sources** (multi-source): the chart from `charts/agent`, with values pulled
  from `$values/agents/<client>/<node>/values.yaml`.
- **sync**: automated (prune + self-heal), `CreateNamespace=true`, and a
  `resources-finalizer` so removing a folder tears the node down.

Add a folder → a node is deployed. Remove a folder → the node is pruned.

## values.yaml

```yaml
agent:
  node_id: 'a1b2c3d4'                         # the panel's node id; the agent registers under it
  token: '...'                                # registration token for the admin panel
  upstream_hostname: 'httpbin.example.com'    # the service being protected
  downstream_hostname: 'httpbin-rl.example.com' # public entrypoint
  # upstream_ip: '1.2.3.4'                    # optional: pin the upstream host to this IP
```

`charts/agent/values.yaml` carries the same keys with empty defaults.

## Prerequisites

This is a **private** repo, so Argo CD needs read credentials for it
(`argocd repo add https://github.com/nshav/agent-deployments.git ...`). The
ApplicationSet references the repo by that exact URL so Argo matches the
credential.

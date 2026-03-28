# Percona PostgreSQL Cluster Helm Chart

This Helm chart deploys and manages a highly available PostgreSQL cluster using the Percona Operator for PostgreSQL v2. It includes built-in support for high availability (Patroni), automated backups (pgBackRest) to local PVCs and remote S3 compatible storage, and monitoring (PMM).

## Installation / Usage

To deploy the cluster using this Helm chart, use the `helm install` command. For example, to install a release named `dbtstyoav-prod` into the `dbaas-postgres` namespace from a local chart directory named `pg-cluster/`, run:

```bash
helm install dbtstyoav-prod pg-cluster/ -n dbaas-postgres
```

## Configuration

The chart is configured via the `values.yaml` file. Below are the primary configuration sections:

### 1. Cluster State & Deletion (Finalizers)
Control what happens when the Helm release (and resulting cluster) is deleted. You can instruct the operator to clean up PVCs, SSL objects, and backups.

```yaml
finalizers:
  - [percona.com/delete-pvc](https://percona.com/delete-pvc)
  - [percona.com/delete-ssl](https://percona.com/delete-ssl)
  - [percona.com/delete-backups](https://percona.com/delete-backups)

postgresVersion: "16.11-2" # The Postgres version to deploy
pause: false               # Set to true to pause operator reconciliation
unmanaged: false           # Set to true to stop operator management completely
```

### 2. Topology & Resources
Configure the high availability layout and compute/storage allocation. 
* **Single Node (`replicaCount: 1`):** Deploys a single instance, disables synchronous commit, and ignores HA logic.
* **High Availability (`replicaCount: 3`):** Distributes pods across `az-a`, `az-b`, and `az-c` with strict synchronous mode enabled.

```yaml
replicaCount: 3
dbStorage: "5Gi"
dbResources:
  requests:
    cpu: "1"
    memory: "2Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

### 3. Engine & High Availability (Patroni)
Tweak internal PostgreSQL settings and manage Patroni cluster parameters. You can easily inject `postgresql.conf` parameters and `pg_hba.conf` rules.

```yaml
postgresql:
  parameters:
    shared_buffers: "128MB"
  pg_hba:
    - "host all all 10.0.0.0/8 md5"
```

### 4. Users & Databases
Automatically provision databases and users upon deployment. The chart generates secure alphanumeric Kubernetes secrets for user passwords automatically.

```yaml
autoCreateUserSchema: true
users:
  - name: "app_user"
    databases: 
      - "app_db"
    password:
      type: "AlphaNumeric"
```

### 5. Backups (pgBackRest)
The chart relies on pgBackRest for backups. Local PVC backups are always configured when backups are enabled. Remote backups (S3/StorageGRID) can be toggled and configured with custom schedules.

```yaml
backups:
  enabled: true
  local:
    schedules:
      full: "0 10 * * *"
  s3:
    enabled: true
    user: "XXXX"
    secret: "YYYYY"
    endpoint: "storage.med.one"
    region: "US"
    schedules:
      full: "0 12 * * 0"
      differential: "0 12 * * 1-6"
```

### 6. Monitoring (Percona Monitoring and Management - PMM)
To enable PMM, simply provide your PMM server token. Leaving the token blank will automatically disable monitoring sidecars.

```yaml
pmm_server_token: "YOUR_TOKEN_HERE"
```

---

## Connecting to the Database

To connect to your database cluster securely using a temporary client pod, you can use the `kubectl run` command. 

Because you are using a custom registry (`registry.med.one`) and require an image pull secret (`quay-pull-secret`), standard `kubectl run` flags aren't enough on their own. You must pass an `--overrides` JSON string to inject the `imagePullSecrets` into the temporary pod's spec.

Run the following command, ensuring you have the `$URI` variable set (e.g., `postgres://user:password@host:5432/dbname`):

```bash
kubectl run -i --rm --tty percona-client \
  --image=registry.med.one/dbaas-postgres/percona/percona-distribution-postgresql:17.7-2 \
  --restart=Never \
  --overrides='{"spec": {"imagePullSecrets": [{"name": "quay-pull-secret"}]}}' \
  -- psql $URI
```

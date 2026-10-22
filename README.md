# Databunker Pro Setup

This repository contains Docker Compose projects and a Helm chart for deploying Databunker Pro — a privacy vault and tokenization service for personal data.

## Supported databases

| Database | Docker Compose | Helm chart |
| --- | --- | --- |
| PostgreSQL | ✅ [`docker-compose-pgsql`](docker-compose-pgsql) | ✅ internal & external |
| MySQL (Percona 8) | ✅ [`docker-compose-mysql`](docker-compose-mysql) | ✅ internal & external |
| Oracle Database | ✅ [`docker-compose-oracle`](docker-compose-oracle) | not yet |

## ⚠️ Important: Database Recommendations

**For production environments, we strongly recommend using dedicated database servers instead of running databases in Kubernetes or in a container.** This includes:

- **AWS RDS** (PostgreSQL/MySQL/Oracle)
- **Google Cloud SQL** (PostgreSQL/MySQL)
- **Azure Database** (PostgreSQL/MySQL)
- **Oracle Cloud Infrastructure** (Autonomous Database / Base Database Service)
- **Self-hosted database servers** with proper backup and monitoring

### Why Use Dedicated Database Servers?

- **Better Performance**: Dedicated resources and optimized configurations
- **Enhanced Security**: Managed security patches and compliance features
- **Reliability**: Built-in high availability, backup, and disaster recovery
- **Scalability**: Easier to scale without affecting application workloads
- **Maintenance**: Automated updates and maintenance windows
- **Monitoring**: Advanced monitoring and alerting capabilities

## Installation

### Get the code

The Docker Compose projects live in this repository, so clone it first:

```bash
git clone https://github.com/securitybunker/databunkerpro-setup.git
cd databunkerpro-setup
```

All `cd docker-compose-*` commands below are relative to this directory. The Kubernetes/Helm installation does not require a clone — the chart is pulled from the Helm repository.

### 🚀 Quick Start: Docker Compose with PostgreSQL

This is the fastest way to get Databunker Pro running. It starts PostgreSQL, Redis and Databunker Pro on your machine.

1. Navigate to the PostgreSQL Docker Compose directory:
```bash
cd docker-compose-pgsql
```

2. Generate the required environment files:
```bash
./generate-env-files.sh
```

3. Pull the latest images:
```bash
docker compose pull
```

4. Start the services:
```bash
docker compose up -d
```

5. Follow the Databunker Pro logs and copy the access code:
```bash
./logs.sh
```

On first start Databunker Pro switches to installation mode and prints a one-time **Access code** that you will need in the browser:

```
2026/07/30 06:32:06 Databunkerpro version: 0.14.21
2026/07/30 06:32:06 Loading configuration file: /databunker/conf/databunker.yaml
2026/07/30 06:32:06 Processing environment variables
2026/07/30 06:32:06 POSTGRESQL Databunker db name is: databunkerdb
2026/07/30 06:32:08 Connected to redis server: redis:6379
2026/07/30 06:32:08 Databunker tables are missing - switching to installation mode
2026/07/30 06:32:08 Open HTTP listener 0.0.0.0:3000
2026/07/30 06:32:08 Access code: 392629
```

Copy the access code, then press `Ctrl-C` to leave the log view — this stops following the logs only, the container keeps running.

6. Open ``http://localhost:3000`` in your browser, enter the access code and follow [Generate admin credentials](https://docs.databunker.org/pro/installation/generate-admin-credentials) to finish the setup process.

### Using Docker Compose with Percona MySQL 8

1. Navigate to the MySQL Docker Compose directory:
```bash
cd docker-compose-mysql
```

2. Generate the required environment files:
```bash
./generate-env-files.sh
```

3. Pull the latest images:
```bash
docker compose pull
```

4. Start the services:
```bash
docker compose up -d
```

5. Follow the logs and copy the one-time **Access code** printed on first start:
```bash
./logs.sh
```

Press `Ctrl-C` to leave the log view, then open ``http://localhost:3000``, enter the access code and follow [Generate admin credentials](https://docs.databunker.org/pro/installation/generate-admin-credentials) to finish the setup process.

### Using Docker Compose with Oracle Database

This stack runs Oracle Database 23ai Free using the [`gvenzl/oracle-free`](https://github.com/gvenzl/oci-oracle-free) image.

1. Navigate to the Oracle Docker Compose directory:
```bash
cd docker-compose-oracle
```

2. Generate the required environment files:
```bash
./generate-env-files.sh
```

3. Pull the latest images:
```bash
docker compose pull
```

4. Start the services:
```bash
docker compose up -d
```

5. Follow the logs and copy the one-time **Access code** printed on first start:
```bash
./logs.sh
```

Oracle needs a few minutes to initialize before Databunker Pro connects, so keep the log view open until the access code appears. Press `Ctrl-C` to leave it, then open ``http://localhost:3000``, enter the access code and follow [Generate admin credentials](https://docs.databunker.org/pro/installation/generate-admin-credentials) to finish the setup process.

Notes specific to Oracle:

* **First boot takes a few minutes** while Oracle initializes — longer on Apple Silicon, where the image runs emulated. Follow the progress with `./logs.sh`.
* The `gvenzl/oracle-free` image auto-creates the schema user from `APP_USER` / `APP_USER_PASSWORD` inside the `FREEPDB1` pluggable database with `CONNECT` + `RESOURCE` and unlimited quota. Unlike PostgreSQL, there is no separate schema-setup SQL: the app user *is* the namespace (`ORACLE_SERVICE=FREEPDB1`).
* Oracle limits passwords to 30 bytes and parses them as identifiers, so `generate-env-files.sh` produces a short, letter-initial, alphanumeric password.
* `./oracle.sh` opens a `sqlplus` session as the schema user.
* TLS (TCPS) is optional and requires an Oracle wallet — see [`docker-compose-oracle/README.md`](docker-compose-oracle/README.md) for the two-step setup.

The environment variables that point Databunker Pro at Oracle are written to `.env/databunker.env`:

| Variable | Value here | Notes |
| --- | --- | --- |
| `ORACLE_HOST` | `oracle` | selects the Oracle backend |
| `ORACLE_PORT` | `1521` | `2484` for TLS |
| `ORACLE_SERVICE` | `FREEPDB1` | the gvenzl PDB |
| `ORACLE_USER_NAME` | `bunkeruser` | = `APP_USER` |
| `ORACLE_USER_PASS` | *(generated)* | = `APP_USER_PASSWORD` |
| `ORACLE_SSL_MODE` | *(commented)* | `require` to use TLS |

### How Docker Compose deployment works

The `generate-env-files.sh` script will:
* Generate secure random passwords and the `DATABUNKER_WRAPPINGKEY`
* Create environment files for the database, Redis and Databunker Pro under `.env/`
* Generate self-signed SSL certificates for the database (PostgreSQL and MySQL only; for Oracle, TLS is opt-in via `./generate-env-files.sh ssl`)

Database data is stored in a Docker named volume managed automatically by Docker Compose.

To fully reset the database and start fresh, run:
```bash
docker compose down -v
```

The `-v` flag removes the named volumes, wiping all database data. Then run `docker compose up -d` to start again. Each project also ships helper scripts: `reload.sh` (restart, keep data), `hard-reset.sh` (wipe the volume and start fresh) and `logs.sh` (follow the Databunker Pro logs).

### Unattended Installation

The `generate-env-files.sh` scripts do not set a setup key. To enable unattended installation, add your own line to `.env/databunker.env` before the first start:

```bash
echo "DATABUNKER_SETUPKEY=$(< /dev/urandom LC_CTYPE=C tr -dc 'a-f0-9' | head -c32)" >> .env/databunker.env
```

When `DATABUNKER_SETUPKEY` is set in `databunker.env`, Databunker Pro exposes a `POST /autoinstall` endpoint that lets you complete first-time setup over the API — no browser required — for CI/CD, infrastructure-as-code, and reproducible deployments.

The flow is three HTTP calls: poll `GET /status` until ready, check `GET /dbstatus` (only `{"installed":false}` means setup is needed), then `POST /autoinstall` with your setup key to receive the vault credentials. On success the setup server shuts down and the container restarts in normal operational mode.

```bash
SETUPKEY=$(grep '^DATABUNKER_SETUPKEY=' .env/databunker.env | cut -d= -f2-)

curl -s -X POST http://localhost:3000/autoinstall \
  --data-urlencode "setupkey=$SETUPKEY" \
  --data-urlencode "licensekey=$LICENSEKEY"   # optional; omit for Trial mode
```

> **Note:** Use `--data-urlencode` (not `-d`): license keys are base64 and may contain `+` or `/`, which `-d` would corrupt. **Save the response — the credentials cannot be retrieved again.**

For the full guide — readiness polling, the "already installed" (404) handling, Python examples, and external-database notes — see [Unattended installation](https://docs.databunker.org/pro/installation/unattended-installation).

## 📋 Using an External Database

This applies to both deployment methods: point Databunker Pro at a managed or self-hosted database instead of running one alongside it. Databunker Pro creates its own tables and indexes on first start, so the user only needs the privileges to do that.

### PostgreSQL (AWS RDS, Cloud SQL, Azure, self-hosted)

On PostgreSQL, Databunker Pro uses two extra roles beyond the login user: `mtenant` (multi-tenancy) and `madmin` (used to generate PII reports across all tenants). MySQL and Oracle do not use them.

```sql
CREATE ROLE bunkeruser NOSUPERUSER LOGIN PASSWORD 'your-secure-password';
CREATE ROLE mtenant NOSUPERUSER NOLOGIN;
CREATE ROLE madmin BYPASSRLS NOSUPERUSER NOLOGIN;
GRANT mtenant TO bunkeruser;
GRANT madmin TO bunkeruser;
CREATE DATABASE databunkerdb OWNER bunkeruser;
```

### Neon (neondb)

Neon gives you the `neondb_owner` login user, so you do not create your own — grant the two roles to it instead:

```sql
CREATE ROLE mtenant NOSUPERUSER NOLOGIN;
CREATE ROLE madmin BYPASSRLS NOSUPERUSER NOLOGIN;
GRANT mtenant TO neondb_owner;
GRANT madmin TO neondb_owner;
CREATE DATABASE databunkerdb;
```

Neon requires TLS, so set `sslMode` / `PGSQL_SSL_MODE` to `require`. With Docker Compose, remove the `postgresql` service from `docker-compose.yml` and point `.env/databunker.env` at your Neon endpoint:

```bash
PGSQL_HOST=ep-xxxx-xxxx.region.aws.neon.tech
PGSQL_PORT=5432
PGSQL_USER_NAME=neondb_owner
PGSQL_USER_PASS=your-neon-password
PGSQL_SSL_MODE=require
```

With Helm, use the `database.external=true` flags shown under [Recommended: Using External Database](#-recommended-using-external-database).

### Oracle Database

Create a schema user that can create its own tables and indexes:

```sql
CREATE USER bunkeruser IDENTIFIED BY "your-secure-password";
GRANT CONNECT, RESOURCE TO bunkeruser;
ALTER USER bunkeruser QUOTA UNLIMITED ON USERS;  -- adjust the tablespace name
```

In Oracle the schema user *is* the namespace — there is no separate database to create. Point Databunker Pro at it with `ORACLE_USER_NAME` and `ORACLE_SERVICE`.

### Enable SSL/TLS (recommended for production)

- AWS RDS: SSL is enabled by default
- Google Cloud SQL: Enable SSL connections
- Azure Database: Enable SSL enforcement
- Neon: TLS is mandatory — `PGSQL_SSL_MODE=require`
- Oracle: set `ORACLE_SSL_MODE=require` and use the TCPS port (`2484` by default)

### Configure network access

- Ensure your Kubernetes cluster or Docker host can reach the database
- Configure security groups/firewall rules appropriately
- Use VPC peering or VPN for enhanced security

## Kubernetes Installation

### Using Helm Chart from GitHub Pages

The official Databunker Pro Helm chart is available through GitHub Pages. To install it:

```bash
# Add the Helm repository
helm repo add databunkerpro https://securitybunker.github.io/databunkerpro-setup

# Update your local Helm repository cache
helm repo update

# Install Databunker Pro
helm install databunkerpro databunkerpro/databunkerpro
```

After installing the databunkerpro Helm chart, you need to expose the Databunker Pro service to complete the installation:

```bash
kubectl port-forward service/databunkerpro 3000:3000
```

The access code needed for the setup process is printed in the pod logs:

```bash
kubectl logs -l app.kubernetes.io/component=databunkerpro | grep "Access code"
```

Then, open ``http://localhost:3000`` in your browser, enter the access code and follow [Generate admin credentials](https://docs.databunker.org/pro/installation/generate-admin-credentials) to finish the setup process.

> **Note:** The Helm chart currently supports PostgreSQL and MySQL. To run Databunker Pro on Kubernetes with Oracle Database, set the `ORACLE_*` variables listed above directly in the pod environment.

### 🚀 Recommended: Using External Database

#### Using AWS RDS PostgreSQL

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.external=true \
  --set database.type=postgresql \
  --set database.externalConfig.host=your-rds-postgresql-endpoint \
  --set database.externalConfig.user=your-db-user \
  --set database.externalConfig.password=your-db-password \
  --set database.externalConfig.sslMode=require
```

#### Using AWS RDS MySQL

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.external=true \
  --set database.type=mysql \
  --set database.externalConfig.host=your-rds-mysql-endpoint \
  --set database.externalConfig.user=your-db-user \
  --set database.externalConfig.password=your-db-password
```

#### Using Google Cloud SQL

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.external=true \
  --set database.type=postgresql \
  --set database.externalConfig.host=your-cloudsql-instance-ip \
  --set database.externalConfig.user=your-db-user \
  --set database.externalConfig.password=your-db-password \
  --set database.externalConfig.sslMode=require
```

### 🔧 Using Internal Databases

> ⚠️ **Warning**: Internal databases is not recomended for production.

#### Using Internal PostgreSQL

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.type=postgresql \
  --set database.internal.postgresql.enabled=true \
  --set database.internal.postgresql.ssl.enabled=true
```

#### Using Internal MySQL (Percona 8)

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.type=mysql \
  --set database.internal.mysql.enabled=true
```

### Using Existing Secrets for Database Passwords

Instead of auto-generating database passwords, you can generate your own password and store it as Kubernetes secret. The ```helm install``` can be configured to use this secret.

#### For PostgreSQL

1. **Create the secret with kubectl**:
   ```bash
   kubectl create secret generic my-postgresql-secret \
     --from-literal=password='your-secure-postgresql-password' \
     --namespace=your-namespace
   ```

2. **Install Databunker Pro with the existing secret**:
   ```bash
   helm install databunkerpro databunkerpro/databunkerpro \
     --set database.type=postgresql \
     --set database.internal.postgresql.enabled=true \
     --set database.existingSecret.name=my-postgresql-secret \
     --namespace=your-namespace
   ```

#### For MySQL

1. **Create the secret with kubectl** (MySQL requires both `password` and `root-password`):
   ```bash
   kubectl create secret generic my-mysql-secret \
     --from-literal=password='your-secure-mysql-password' \
     --from-literal=root-password='your-secure-mysql-root-password' \
     --namespace=your-namespace
   ```

2. **Install Databunker Pro with the existing secret**:
   ```bash
   helm install databunkerpro databunkerpro/databunkerpro \
     --set database.type=mysql \
     --set database.internal.mysql.enabled=true \
     --set database.existingSecret.name=my-mysql-secret \
     --namespace=your-namespace
   ```

#### Using a Values File

Alternatively, you can configure this in your values file:

```yaml
database:
  type: postgresql
  existingSecret:
    name: my-postgresql-secret
  internal:
    postgresql:
      enabled: true
```

Then install with:
```bash
helm install databunkerpro databunkerpro/databunkerpro -f my-values.yaml
```

**Note**: The secret must exist in the same namespace where you're deploying Databunker Pro. If the secret name is not provided, the chart will automatically generate passwords as before.

### 📋 Internal Databases (Development Only)

The internal database will be automatically created with the required schema. For external databases, see [Using an External Database](#-using-an-external-database) above.

### 🔐 SSL Certificate Management

#### For Internal PostgreSQL with Custom SSL Certificates

If you want to use your own SSL certificates instead of auto-generated ones:

1. **Generate SSL certificates** (if you don't have them):
   ```bash
   # Or generate manually
   openssl req -new -text -subj /CN=your-hostname \
     -out server.req -keyout server.key
   openssl req -x509 -in server.req -text \
     -key server.key -out server.crt
   ```

2. **Create Kubernetes secret**:
   ```bash
   kubectl create secret generic postgresql-ssl-certs \
     --from-file=server.crt=./server.crt \
     --from-file=server.key=./server.key
   ```

3. **Install with custom certificates**:
   ```bash
   helm install databunkerpro databunkerpro/databunkerpro \
     --set database.type=postgresql \
     --set database.internal.postgresql.enabled=true \
     --set database.internal.postgresql.ssl.enabled=true \
     --set database.internal.postgresql.ssl.generateSelfSigned=false \
     --set database.internal.postgresql.ssl.secretName=postgresql-ssl-certs
   ```

#### SSL Configuration Options

- **`generateSelfSigned: true`** (default): Automatically generates self-signed certificates
- **`generateSelfSigned: false`** + **`secretName`**: Uses certificates from Kubernetes secret

### 🌐 Exposing Databunker Pro via Ingress

To expose Databunker Pro via Ingress, set your custom host parameter:

```bash
  --set ingress.host=databunker.your-domain.com
```

Make sure to:
1. Replace `databunker.your-domain.com` with your actual domain
2. Have an Ingress controller (like NGINX Ingress Controller) installed
3. Have cert-manager installed if you want automatic SSL/TLS certificate management

#### Using Custom Values File

For more complex configurations, you can create your own values file based on the default configuration:

```bash
# Download the default values file
helm show values databunkerpro/databunkerpro > my-values.yaml

# Edit the values file to match your needs
# Then install or upgrade using your custom values
helm install databunkerpro databunkerpro/databunkerpro -f my-values.yaml
```

This approach is recommended when you need to:
* Configure multiple parameters
* Maintain consistent configuration across deployments
* Version control your configuration

## Configuration

You can customize the deployment by modifying the values in your Helm installation command or by creating a custom values file.

## ✅ Production Deployment Checklist

Before deploying to production, ensure you have:

### Database
- [ ] Using a dedicated database server (RDS, Cloud SQL, etc.)
- [ ] Database SSL/TLS enabled
- [ ] Proper backup and disaster recovery configured
- [ ] Database monitoring and alerting set up
- [ ] Network security configured (VPC, security groups, etc.)

## Troubleshooting
```
kubectl run postgres-test --rm -i --restart=Never --image=postgres:16 -n namespace -- bash
psql -h databunkerpro-postgresql -U bunkeruser -d databunkerdb

kubectl exec -ti databunkerpro_pod_name -n namespace -- sh
/bin/busybox env
/bin/busybox cat /file-location
/bin/busybox cat /var/run/secrets/kubernetes.io/serviceaccount/wrapping-key/wrapping-key
```

Reset user related tables:
```
TRUNCATE TABLE users RESTART IDENTITY;
TRUNCATE TABLE userversions RESTART IDENTITY;
TRUNCATE TABLE userapps RESTART IDENTITY;
TRUNCATE TABLE userappversions RESTART IDENTITY;
TRUNCATE TABLE sharedrecords RESTART IDENTITY;
TRUNCATE TABLE audit RESTART IDENTITY;
TRUNCATE TABLE requests RESTART IDENTITY;
TRUNCATE TABLE agreements RESTART IDENTITY;
TRUNCATE TABLE sessions RESTART IDENTITY;
TRUNCATE TABLE usergroups RESTART IDENTITY;
```

## Additional Resources

* [Databunker Pro Documentation](https://docs.databunker.org/)
* [Oracle Database backend](https://databunker.org/pro/installation/oracle-database)
* [Kubernetes Production Best Practices](https://kubernetes.io/docs/concepts/security/)
* [Database Security Best Practices](https://owasp.org/www-project-top-ten/)

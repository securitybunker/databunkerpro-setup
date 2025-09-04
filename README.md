# DatabunkerPro Setup

This repository contains a Helm chart and Docker Compose projects for deploying DatabunkerPro — a privacy vault and tokenization service for personal data.

## ⚠️ Important: Database Recommendations

**For production environments, we strongly recommend using dedicated database servers instead of running databases in Kubernetes.** This includes:

- **AWS RDS** (PostgreSQL/MySQL)
- **Google Cloud SQL** (PostgreSQL/MySQL)
- **Azure Database** (PostgreSQL/MySQL)
- **Self-hosted database servers** with proper backup and monitoring

### Why Use Dedicated Database Servers?

- **Better Performance**: Dedicated resources and optimized configurations
- **Enhanced Security**: Managed security patches and compliance features
- **Reliability**: Built-in high availability, backup, and disaster recovery
- **Scalability**: Easier to scale without affecting application workloads
- **Maintenance**: Automated updates and maintenance windows
- **Monitoring**: Advanced monitoring and alerting capabilities

## Installation

### Using Helm Chart from GitHub Pages

The official DatabunkerPro Helm chart is available through GitHub Pages. To install it:

```bash
# Add the Helm repository
helm repo add databunkerpro https://securitybunker.github.io/databunkerpro-setup

# Update your local Helm repository cache
helm repo update

# Install DatabunkerPro
helm install databunkerpro databunkerpro/databunkerpro
```

After installing the databunkerpro Helm chart, you need to expose the Databunker Pro service to complete the installation:

```bash
kubectl port-forward service/databunkerpro 3000:3000
```

Then, open ``http://localhost:3000`` in your browser to finish the setup process.

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

### 📋 Database Setup Requirements

#### For External Databases (Recommended)

1. **Create the database**:
   ```sql
   CREATE DATABASE databunkerdb;
   ```

2. **Create a dedicated user**:
   ```sql
   CREATE USER bunkeruser WITH PASSWORD 'your-secure-password';
   GRANT ALL PRIVILEGES ON DATABASE databunkerdb TO bunkeruser;
   ```

3. **Enable SSL/TLS** (recommended for production):
   - AWS RDS: SSL is enabled by default
   - Google Cloud SQL: Enable SSL connections
   - Azure Database: Enable SSL enforcement

4. **Configure network access**:
   - Ensure your Kubernetes cluster can reach the database
   - Configure security groups/firewall rules appropriately
   - Use VPC peering or VPN for enhanced security

#### For Internal Databases (Development Only)

The internal database will be automatically created with the required schema.

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

### 🌐 Exposing DatabunkerPro via Ingress

To expose DatabunkerPro via Ingress, set your custom host parameter:

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

### Using Docker Compose

DatabunkerPro can also be deployed using Docker Compose. We provide two options: Percona MySQL 8 and PostgreSQL.

#### Using Percona MySQL 8

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

#### Using PostgreSQL

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

#### How it works

The `generate-env-files.sh` script will:
* Create necessary directories
* Generate secure random passwords
* Create environment files for MySQL/PostgreSQL and DatabunkerPro
* Set up proper permissions

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

### Security
- [ ] SSL/TLS certificates configured for DatabunkerPro
- [ ] Proper RBAC and service accounts configured
- [ ] Secrets management in place (not hardcoded passwords)
- [ ] Network policies configured
- [ ] Regular security updates enabled

### Monitoring & Operations
- [ ] Logging and monitoring configured
- [ ] Health checks and readiness probes working
- [ ] Resource limits and requests configured
- [ ] Horizontal Pod Autoscaler (HPA) configured if needed
- [ ] Backup and restore procedures tested

### Network
- [ ] Ingress controller properly configured
- [ ] SSL/TLS termination configured
- [ ] Load balancer configured for high availability
- [ ] DNS and domain configuration complete

## Additional Resources

* [DatabunkerPro Documentation](https://databunker.org/databunker-pro-docs/api-and-sdk/)
* [Kubernetes Production Best Practices](https://kubernetes.io/docs/concepts/security/)
* [Database Security Best Practices](https://owasp.org/www-project-top-ten/)

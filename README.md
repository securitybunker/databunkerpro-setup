# DatabunkerPro Setup

This repository contains a Helm chart for deploying DatabunkerPro, a privacy vault for personal data.

## Installation

### Using Helm Chart from GitHub Packages

The official DatabunkerPro Helm chart is available through GitHub Packages. To install it:

```bash
# Add the GitHub Packages Helm repository
helm repo add databunkerpro oci://ghcr.io/securitybunker/helm-charts

# Update your local Helm repository cache
helm repo update

# Install DatabunkerPro
helm install databunkerpro databunkerpro/databunkerpro
```

#### Using Internal MySQL (Percona 8)

To install DatabunkerPro with an internal Percona MySQL 8 database:

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.type=mysql \
  --set database.internal.mysql.enabled=true
```

#### Using Internal PostgreSQL

To install DatabunkerPro with an internal PostgreSQL database:

```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.type=postgresql \
  --set database.internal.postgresql.enabled=true
```

#### Using Remote Database (RDS)

To install DatabunkerPro with a remote database (e.g., AWS RDS):

##### For PostgreSQL:
```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.external=true \
  --set database.type=postgresql \
  --set database.externalConfig.host=your-rds-host \
  --set database.externalConfig.user=your-user \
  --set database.externalConfig.password=your-password
```

##### For MySQL (Percona 8):
```bash
helm install databunkerpro databunkerpro/databunkerpro \
  --set database.external=true \
  --set database.type=mysql \
  --set database.externalConfig.host=your-rds-host \
  --set database.externalConfig.user=your-user \
  --set database.externalConfig.password=your-password
```

#### Exposing DatabunkerPro via Ingress

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

3. Start the services:
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

3. Start the services:
```bash
docker compose up -d
```

The `generate-env-files.sh` script will:
* Create necessary directories
* Generate secure random passwords
* Create environment files for MySQL/PostgreSQL and DatabunkerPro
* Set up proper permissions

## Configuration

You can customize the deployment by modifying the values in your Helm installation command or by creating a custom values file.

## Additional Resources

* [DatabunkerPro Documentation](https://databunker.org/doc/)
* [Helm Documentation](https://helm.sh/docs/)

## About

DatabunkerPro is a privacy vault for personal data that helps organizations comply with privacy regulations like GDPR, CCPA, and more.

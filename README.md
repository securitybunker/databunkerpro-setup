# DatabunkerPro Setup

This repository contains a Helm chart for deploying DatabunkerPro, a privacy vault for personal data.

## Installation

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
- Create necessary directories
- Generate secure random passwords
- Create environment files for MySQL/PostgreSQL and DatabunkerPro
- Set up proper permissions

### Using Helm Charts

#### Using Internal MySQL (Percona 8)

To install DatabunkerPro with an internal Percona MySQL 8 database:

```bash
helm install databunkerpro ./helm/databunkerpro \
  --set database.type=mysql \
  --set database.internal.mysql.enabled=true
```

#### Using Internal PostgreSQL

To install DatabunkerPro with an internal PostgreSQL database:

```bash
helm install databunkerpro ./helm/databunkerpro \
  --set database.type=postgresql \
  --set database.internal.postgresql.enabled=true
```

#### Using Remote Database (RDS)

To install DatabunkerPro with a remote database (e.g., AWS RDS):

##### For PostgreSQL:

```bash
helm install databunkerpro ./helm/databunkerpro \
  --set database.external=true \
  --set database.type=postgresql \
  --set database.externalConfig.host=your-rds-host \
  --set database.externalConfig.user=your-user \
  --set database.externalConfig.password=your-password
```

##### For MySQL (Percona 8):

```bash
helm install databunkerpro ./helm/databunkerpro \
  --set database.external=true \
  --set database.type=mysql \
  --set database.externalConfig.host=your-rds-host \
  --set database.externalConfig.user=your-user \
  --set database.externalConfig.password=your-password
```

## Configuration

You can customize the deployment by modifying the `values.yaml` file or by using the `--set` flag with `helm install`.

## Additional Resources

- [DatabunkerPro Documentation](https://databunker.org/docs)
- [Helm Documentation](https://helm.sh/docs)

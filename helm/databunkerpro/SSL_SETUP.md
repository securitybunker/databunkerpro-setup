# SSL Certificate Setup for DataBunkerPro

This guide provides step-by-step instructions for setting up SSL certificates for DataBunkerPro using the Helm chart, including automatic self-signed certificate generation and ingress-level SSL with cert-manager.

## Prerequisites

1. **Kubernetes cluster** with admin access
2. **Domain name** pointing to your cluster's ingress IP (for production)
3. **Ingress controller** (nginx-ingress recommended)
4. **cert-manager** installed (for automatic certificate generation with Let's Encrypt)

## SSL Configuration Options

### Option 1: Ingress-Level SSL with cert-manager (Recommended for Production)

SSL termination at the ingress controller level with automatic certificate generation using Let's Encrypt.

### Option 2: Application-Level SSL with External Certificates

SSL termination at the DataBunkerPro application level using existing certificates.

### Option 3: Application-Level SSL with Self-Signed Certificates

SSL termination at the DataBunkerPro application level with automatic self-signed certificate generation.

## Option 1: Ingress-Level SSL with cert-manager (Recommended)

### Step 1: Install Ingress Controller

```bash
# Add the nginx-ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install nginx-ingress
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Get the external IP
kubectl get service -n ingress-nginx nginx-ingress-ingress-nginx-controller
```

### Step 2: Install cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
```

### Step 3: Create ClusterIssuer for Let's Encrypt

```yaml
# Create letsencrypt-prod.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com  # Replace with your email
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
# Apply the ClusterIssuer
kubectl apply -f letsencrypt-prod.yaml

# Verify it's ready
kubectl get clusterissuer letsencrypt-prod
```

### Step 4: Configure DNS

Point your domain to the ingress controller's external IP:

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get service -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Point your domain to: $EXTERNAL_IP"
```

Add an A record in your DNS:
- **Name**: `databunker` (or your preferred subdomain)
- **Value**: `<EXTERNAL_IP>`
- **TTL**: 300 seconds

### Step 5: Configure and deploy DataBunkerPro

You can use the official ```values.yaml``` file from repository or create smaller one. Helm knows to merge the changes.

```bash
# Download the base values file
curl -O https://raw.githubusercontent.com/securitybunker/databunkerpro-setup/main/helm/databunkerpro/values.yaml
```

Enable ingress with cert-manager:

```yaml
# Modify these sections in values.yaml:

ingress:
  enabled: true
  className: nginx
  host: "databunker.yourdomain.com"  # Replace with your domain
  
  annotations:
    kubernetes.io/ingress.class: nginx
    # cert-manager configuration
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Use letsencrypt-staging for testing

  tls:
    enabled: true
    # Let cert-manager create the secret automatically
    secretName: "databunkerpro-tls"

```

```bash
# Deploy DataBunkerPro
helm install databunkerpro ./databunkerpro \
  --namespace databunkerpro \
  --create-namespace \
  -f values.yaml
```

### Step 6: Monitor Certificate Generation

```bash
# Check certificate status
kubectl get certificate -n databunkerpro

# Check certificate details
kubectl describe certificate databunkerpro-tls -n databunkerpro

# Check ingress status
kubectl get ingress -n databunkerpro

# Monitor cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f
```

### Step 7: Verify SSL Certificate

```bash
# Test HTTPS access
curl -I https://databunker.yourdomain.com

# Check certificate details
openssl s_client -connect databunker.yourdomain.com:443 -servername databunker.yourdomain.com < /dev/null | openssl x509 -text -noout
```

## Option 2: Application-Level SSL with External Certificates

### Step 1: Obtain SSL Certificates

You have several options to obtain SSL certificates:

#### Option A: Using Certbot (Recommended for Let's Encrypt)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot

# Obtain certificate for your domain
sudo certbot certonly --standalone -d databunker.yourdomain.com

# Certificates will be stored in:
# /etc/letsencrypt/live/databunker.yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/databunker.yourdomain.com/privkey.pem
```

#### Option B: Purchase from Certificate Authority

Purchase certificates from providers like:
- DigiCert
- GlobalSign
- Comodo
- Your hosting provider

### Step 2: Save SSL Certificate as Kubernetes Secret

```bash
# Create a secret with your certificates
kubectl create secret tls databunkerpro-tls \
  --cert=path/to/your/certificate.crt \
  --key=path/to/your/private.key \
  -n your-namespace
```

### Step 3: Configure and deploy

First, get the base values file from the official repository:

```bash
# Download the base values file
curl -O https://raw.githubusercontent.com/securitybunker/databunkerpro-setup/main/helm/databunkerpro/values.yaml
```

Then modify the `values.yaml` file to enable application-level SSL:

```yaml
# Modify these sections in values.yaml:

ssl:
  enabled: true
  certificate:
    secretName: "databunkerpro-tls"
    certFile: "tls.crt"
    keyFile: "tls.key"

  generateSelfSigned:
    enabled: false  # Set to true to generate self-signed certificates
```

```bash
helm install databunkerpro ./databunkerpro -f values.yaml
```

## Option 3: Application-Level SSL with Self-Signed Certificates

This option automatically generates self-signed certificates using a Kubernetes Job. Perfect for development, testing, or internal deployments.

### Step 1: Configure self-signed certificate generation

First, get the base values file from the official repository:

```bash
# Download the base values file
curl -O https://raw.githubusercontent.com/securitybunker/databunkerpro-setup/main/helm/databunkerpro/values.yaml
```

Then modify the `values.yaml` file to enable self-signed certificate generation:

```yaml
# Modify these sections in values.yaml:

ssl:
  enabled: true
  certificate:
    # Leave secretName empty to trigger self-signed generation
    secretName: ""
    
    # Self-signed certificate configuration
    generateSelfSigned:
      enabled: true
      duration: 365  # Certificate validity in days
      commonName: "databunkerpro.local"  # Common name for the certificate
      organization: "DataBunkerPro"  # Organization name
      country: "US"  # Country code
      state: "CA"  # State/Province
      locality: "San Francisco"  # City/Locality
      keySize: 2048  # RSA key size in bits
      algorithm: "sha256"  # Hash algorithm
```

### Step 2: Deploy with self-signed certificates

```bash
helm install databunkerpro ./databunkerpro -f values.yaml
```

### How the Self-Signed Certificate Generation Works

1. **Kubernetes Job**: When SSL is enabled and no `secretName` is provided, a Kubernetes Job runs before the deployment
2. **Helm Hooks**: The Job uses Helm hooks (`pre-install`, `pre-upgrade`) to ensure it runs before the main application
3. **Certificate Generation**: The Job generates a private key and self-signed certificate using OpenSSL
4. **Secret Creation**: Certificates are stored in a Kubernetes Secret named `{release-name}-tls`
5. **Application Startup**: DataBunkerPro deployment mounts the secret and starts with the generated certificates

### Self-Signed Certificate Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enabled` | `false` | Enable self-signed certificate generation |
| `duration` | `365` | Certificate validity in days |
| `commonName` | `databunkerpro.local` | Common name (CN) for the certificate |
| `organization` | `DataBunkerPro` | Organization name (O) |
| `country` | `US` | Country code (C) |
| `state` | `CA` | State/Province (ST) |
| `locality`

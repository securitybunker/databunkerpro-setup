# SSL Certificate Setup for DataBunkerPro

This guide provides step-by-step instructions for setting up SSL certificates for DataBunkerPro using the Helm chart, including automatic self-signed certificate generation and ingress-level SSL with cert-manager.


## SSL Configuration Options

### Option 1: Ingress-Level SSL with cert-manager (Recommended for Production)

SSL termination at the ingress controller level with automatic certificate generation using Let's Encrypt.

### Option 2: Application-Level SSL with External Certificates

SSL termination at the DataBunkerPro application level using existing certificates.

### Option 3: Application-Level SSL with Self-Signed Certificates

SSL termination at the DataBunkerPro application level with automatic self-signed certificate generation.


## Option 1: Ingress-Level SSL with cert-manager (Recommended for Production)

### Step 1: Configure DNS

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

### Step 2: Configure and deploy DataBunkerPro

```yaml
ingress:
  enabled: true
  host: "databunker.yourdomain.com"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    enabled: true
```

```bash
helm install databunkerpro ./databunkerpro -f values.yaml
```

## Option 2: Application-Level SSL with External Certificates

### Step 1: Obtain SSL Certificates

You need to obtain SSL certificates for your domain. Common options include:

- **Let's Encrypt** (free) - Use certbot or your hosting provider's Let's Encrypt integration
- **Certificate Authorities** - Purchase from providers like DigiCert, GlobalSign, Comodo
- **Your hosting provider** - Many providers offer free SSL certificates

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

### Step 2: Save SSL Certificate as Kubernetes Secret

```bash
# Create a secret with your certificates
kubectl create secret tls databunkerpro-tls \
  --cert=path/to/your/certificate.crt \
  --key=path/to/your/private.key \
  -n your-namespace
```

### Step 3: Configure and deploy

```yaml
ssl:
  enabled: true
  certificate:
    secretName: "databunkerpro-tls"

  generateSelfSigned:
    enabled: false
```

```bash
helm install databunkerpro ./databunkerpro -f values.yaml
```

## Option 3: Application-Level SSL with Self-Signed Certificates

This option automatically generates self-signed certificates using a Kubernetes Job. Perfect for development, testing, or internal deployments.

### Step 1: Configure self-signed certificate generation

```yaml
ssl:
  enabled: true
  certificate:
    secretName: ""  # Leave empty to trigger self-signed generation
  generateSelfSigned:
    enabled: true
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
5. **Application Startup**: DataBunkerPro deployment mounts the secret and uses the generated certificates
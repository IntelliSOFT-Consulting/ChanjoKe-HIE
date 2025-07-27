# Simplified HIE Deployment

This simplified deployment approach consolidates the entire Health Information Exchange (HIE) into a single `.env` configuration file and an automated deployment script.

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have the following installed:
- Docker (20.10+)
- Docker Compose (2.0+) or docker-compose (1.28+)
- `envsubst` (gettext package)

### 2. Configuration

Copy the environment template and configure your domains:

```bash
cp env-template .env
```

Edit `.env` and update the domain names for your deployment:

```bash
# Example configuration
HIE_DOMAIN=chanjo-provider.yourdomain.com
KEYCLOAK_DOMAIN=chanjo-auth.yourdomain.com
DATA_PIPES_DOMAIN=chanjo-reports.yourdomain.com
OPENHIM_API_DOMAIN=chanjoke.yourdomain.com

# SSL Certificate paths
SSL_CERT_PATH=./certs/star.yourdomain.com.crt
SSL_KEY_PATH=./certs/star.yourdomain.com.key
```

### 3. SSL Certificates

Place your SSL certificates in the specified paths:
- Certificate: `./certs/star.yourdomain.com.crt`
- Private Key: `./certs/star.yourdomain.com.key`

### 4. Deploy

Run the deployment script:

```bash
./deploy-hie.sh
```

The script will:
- ✅ Check dependencies
- ✅ Load and validate environment variables
- ✅ Generate all configuration files
- ✅ Create Docker networks
- ✅ Build and start all services
- ✅ Display service URLs and credentials

## 🌐 Service URLs

After deployment, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| **Provider App** | `https://yourdomain.com/provider/` | Healthcare provider interface |
| **Patient App** | `https://yourdomain.com/client/` | Patient portal |
| **OpenHIM Console** | `https://yourdomain.com/` | Default landing page |
| **HAPI FHIR** | `https://yourdomain.com/hapi/` | FHIR server API |
| **ChanjoKe Auth** | `https://yourdomain.com/auth/` | Authentication service |
| **Keycloak** | `https://chanjo-auth.yourdomain.com/` | Identity management |
| **Data Pipeline** | `https://chanjo-reports.yourdomain.com/` | Analytics and reports |
| **OpenHIM API** | `https://chanjoke.yourdomain.com/openhim-api/` | OpenHIM API endpoints |

## 🛠️ Management Commands

### Start/Stop Services

```bash
# Start HIE
./deploy-hie.sh

# Stop HIE
./deploy-hie.sh stop

# Restart HIE
./deploy-hie.sh restart
```

### Monitor Services

```bash
# Check service status
./deploy-hie.sh status

# View all logs
./deploy-hie.sh logs

# View specific service logs
./deploy-hie.sh logs nginx-proxy
./deploy-hie.sh logs hapi-fhir-jpa
./deploy-hie.sh logs keycloak
```

### Individual Service Management

```bash
# Using docker-compose directly
docker-compose -f docker-compose.unified.yml ps
docker-compose -f docker-compose.unified.yml logs -f [service-name]
docker-compose -f docker-compose.unified.yml restart [service-name]
```

## 🏗️ Architecture

The simplified deployment includes:

### Core Services
- **HAPI FHIR Server** - FHIR R4 compliant server
- **OpenHIM Core & Console** - Health information mediator
- **Keycloak** - Identity and access management
- **ChanjoKe Auth** - Custom authentication service

### Web Applications
- **Provider Web App** - Healthcare provider interface
- **Patient Web App** - Patient portal

### Data Pipeline
- **Pipeline Controller** - FHIR data transformation and analytics

### Infrastructure
- **Nginx Proxy** - Reverse proxy with SSL termination
- **PostgreSQL** - Databases for HAPI FHIR and Keycloak
- **MongoDB** - Database for OpenHIM

## 🔧 Configuration Details

### Environment Variables

The `.env` file contains all necessary configuration:

- **Domain Configuration**: All service domains
- **SSL Configuration**: Certificate paths
- **Database Credentials**: PostgreSQL, MongoDB credentials
- **Application Settings**: JWT secrets, API URLs
- **Data Pipeline Settings**: FHIR server URLs, resource lists

### Generated Configurations

The deployment script automatically generates:

- `generated-configs/nginx/nginx.conf` - Nginx reverse proxy configuration
- `generated-configs/openhim/default.json` - OpenHIM console configuration
- `generated-configs/hapi-fhir/application.yaml` - HAPI FHIR server configuration
- `generated-configs/data-pipes/application.yaml` - Data pipeline configuration

## 🔒 Security

### Default Credentials

**⚠️ Change these immediately after deployment:**

- **Keycloak Admin**: `admin` / `[KEYCLOAK_ADMIN_PASSWORD from .env]`
- **OpenHIM Admin**: `root@openhim.org` / `[set during first login]`

### SSL Configuration

- All external traffic is automatically redirected to HTTPS
- SSL certificates are mounted from your specified paths
- Modern TLS configuration (TLS 1.2/1.3)

## 🧪 Development vs Production

Set the `ENVIRONMENT` variable in `.env`:

```bash
# For development
ENVIRONMENT=development
NODE_ENV=development

# For production  
ENVIRONMENT=production
NODE_ENV=production
```

## 📊 Data Pipeline

The data pipeline automatically:
- Extracts data from HAPI FHIR server
- Transforms it into analytics-ready format
- Stores it in Parquet files for analysis
- Provides REST API for reports

Resources processed: `Patient, Encounter, Observation, Questionnaire, Condition, Practitioner, Location, Organization, Immunization, ServiceRequest, ImmunizationRecommendation`

## 🔍 Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   ```bash
   # Check certificate paths in .env
   ls -la ./certs/
   ```

2. **Service Not Starting**
   ```bash
   # Check logs for specific service
   ./deploy-hie.sh logs [service-name]
   ```

3. **Domain Not Resolving**
   - Ensure DNS records point to your server
   - Check domain configuration in `.env`

4. **Database Connection Issues**
   ```bash
   # Check database containers
   ./deploy-hie.sh logs hapi-fhir-postgres
   ./deploy-hie.sh logs keycloak-postgres
   ```

### Service Health Checks

```bash
# Check if all containers are running
docker ps

# Check specific service health
docker exec nginx-proxy nginx -t
docker exec hapi-fhir-jpa curl -f http://localhost:8080/fhir/metadata
```

## 📁 File Structure

```
.
├── .env                          # Main configuration file
├── env-template                  # Environment template
├── deploy-hie.sh                 # Main deployment script
├── docker-compose.unified.yml    # Unified Docker Compose file
├── templates/                    # Configuration templates
│   ├── nginx.conf.template
│   ├── openhim-default.json.template
│   └── data-pipes-config.yaml.template
├── generated-configs/            # Auto-generated configurations
│   ├── nginx/
│   ├── openhim/
│   ├── hapi-fhir/
│   └── data-pipes/
└── certs/                        # SSL certificates
    ├── star.yourdomain.com.crt
    └── star.yourdomain.com.key
```

## 🆚 Comparison with Previous Setup

### Before (Multiple Files)
- 3 separate docker-compose files
- Manual configuration editing
- Multiple .env files
- Complex startup sequence

### After (Simplified)
- ✅ Single `.env` file
- ✅ Automated configuration generation  
- ✅ One-command deployment
- ✅ Built-in health checks
- ✅ Easy management commands

## 🤝 Contributing

To extend this deployment:

1. Add new environment variables to `env-template`
2. Create configuration templates in `templates/`
3. Update `deploy-hie.sh` to handle new configurations
4. Add new services to `docker-compose.unified.yml`

## 📄 License

This deployment configuration inherits the licenses of the individual components it orchestrates. 
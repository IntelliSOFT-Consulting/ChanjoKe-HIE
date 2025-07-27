# HIE Deployment Troubleshooting Guide

## 🚨 Common Issues and Solutions

### 1. Data Pipeline Authentication Error

**Error:**
```
Error response from daemon: Head "https://us-docker.pkg.dev/v2/fhir-org-starter-project/fhir-pipelines/controller/manifests/latest": denied: Unauthenticated request
```

**Solution:**
The data pipeline service is optional and requires either:

**Option A: Build from source (Recommended)**
```bash
./enable-data-pipeline.sh
# Choose option 1: Build from source
./deploy-hie.sh restart
```

**Option B: Google Cloud Authentication**
```bash
# First authenticate with Google Cloud
gcloud auth configure-docker us-docker.pkg.dev
./enable-data-pipeline.sh
# Choose option 2: Use Google Cloud image
./deploy-hie.sh restart
```

**Option C: Skip Data Pipeline**
The HIE will work without the data pipeline. You can deploy without it and enable it later when needed.

### 2. SSL Certificate Issues

**Error:**
```
SSL certificate not found at: ./certs/star.yourdomain.com.crt
```

**Solution:**
1. Ensure SSL certificates are in the correct location:
   ```bash
   ls -la ./certs/
   # Should show your .crt and .key files
   ```

2. Update `.env` file with correct certificate paths:
   ```bash
   SSL_CERT_PATH=./certs/your-actual-cert.crt
   SSL_KEY_PATH=./certs/your-actual-key.key
   ```

3. For development/testing, you can create self-signed certificates:
   ```bash
   mkdir -p certs
   openssl req -x509 -newkey rsa:4096 -keyout certs/star.yourdomain.com.key -out certs/star.yourdomain.com.crt -days 365 -nodes
   ```

### 3. Service Not Starting

**Check service status:**
```bash
./deploy-hie.sh status
```

**View specific service logs:**
```bash
./deploy-hie.sh logs [service-name]
# Examples:
./deploy-hie.sh logs hapi-fhir-jpa
./deploy-hie.sh logs keycloak
./deploy-hie.sh logs nginx-proxy
```

**Common service issues:**

#### HAPI FHIR Database Connection
```bash
./deploy-hie.sh logs hapi-fhir-postgres
./deploy-hie.sh logs hapi-fhir-jpa
```

#### Keycloak Issues
```bash
./deploy-hie.sh logs keycloak-postgres
./deploy-hie.sh logs keycloak
```

#### Nginx Configuration
```bash
# Test nginx configuration
docker exec nginx-proxy nginx -t
```

### 4. Domain Resolution Issues

**Problem:** Can't access services via domain names

**Solution:**
1. Ensure DNS records point to your server
2. For local testing, add entries to `/etc/hosts`:
   ```bash
   sudo nano /etc/hosts
   # Add lines like:
   127.0.0.1 chanjo-provider.intellisoftkenya.com
   127.0.0.1 chanjo-auth.intellisoftkenya.com
   127.0.0.1 chanjo-reports.intellisoftkenya.com
   ```

### 5. Port Conflicts

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use
```

**Solution:**
Stop conflicting services:
```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Stop other web servers
sudo systemctl stop apache2
sudo systemctl stop nginx
```

### 6. Docker Issues

#### Insufficient Memory
```bash
# Increase Docker memory limit (Docker Desktop)
# Settings > Resources > Advanced > Memory: 8GB+
```

#### Network Issues
```bash
# Recreate Docker network
docker network rm cloudbuild
docker network create cloudbuild
./deploy-hie.sh restart
```

#### Permission Issues
```bash
# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

### 7. Build Issues

#### Maven Build Failures
```bash
# Clean build for data pipeline
cd fhir-data-pipes
mvn clean install -DskipTests
cd ..
./deploy-hie.sh restart
```

#### Node.js Build Issues
```bash
# Clear npm cache
npm cache clean --force
# Remove node_modules and reinstall
rm -rf ChanjoKe-*-web-app/node_modules
./deploy-hie.sh restart
```

### 8. Database Issues

#### PostgreSQL Connection Issues
```bash
# Check database logs
./deploy-hie.sh logs hapi-fhir-postgres
./deploy-hie.sh logs keycloak-postgres

# Reset databases (WARNING: This removes all data)
docker-compose -f docker-compose.unified.yml down -v
./deploy-hie.sh
```

#### MongoDB Issues
```bash
# Check MongoDB logs
./deploy-hie.sh logs mongo

# Reset MongoDB (WARNING: This removes all data)
docker volume rm mongodb-data
./deploy-hie.sh restart
```

## 🔍 Diagnostic Commands

### Check All Services
```bash
./deploy-hie.sh status
```

### Test Service Connectivity
```bash
# Test internal connectivity
docker exec nginx-proxy curl -f http://hapi-fhir-jpa:8080/fhir/metadata
docker exec nginx-proxy curl -f http://keycloak:8080/health
```

### Check Docker Resources
```bash
# Check disk space
docker system df

# Check running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check logs for all services
docker-compose -f docker-compose.unified.yml logs --tail=50
```

### Monitor Resources
```bash
# Monitor container resource usage
docker stats

# Check system resources
htop
df -h
```

## 🆘 Getting Help

### Gather Information
When reporting issues, please include:

1. **System Information:**
   ```bash
   uname -a
   docker --version
   docker-compose --version
   ```

2. **Service Status:**
   ```bash
   ./deploy-hie.sh status > status.log
   ```

3. **Recent Logs:**
   ```bash
   docker-compose -f docker-compose.unified.yml logs --tail=100 > hie-logs.log
   ```

4. **Environment Configuration:**
   ```bash
   # Sanitize sensitive information before sharing
   grep -v "PASSWORD\|SECRET\|KEY" .env > config-sanitized.txt
   ```

### Force Clean Restart
If all else fails, perform a complete reset:

```bash
# WARNING: This removes all data and containers
./deploy-hie.sh stop
docker-compose -f docker-compose.unified.yml down --volumes --remove-orphans
docker system prune -f
./deploy-hie.sh
```

## 📞 Support Resources

- **Documentation:** `README-SIMPLIFIED-DEPLOYMENT.md`
- **Configuration Help:** `./quick-start.sh`
- **Data Pipeline Setup:** `./enable-data-pipeline.sh`
- **Community:** [GitHub Issues](https://github.com/your-repo/issues) 
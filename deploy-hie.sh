#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+="docker"
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing_deps+="docker-compose"
    fi
    
    if ! command -v envsubst &> /dev/null; then
        missing_deps+="envsubst (gettext package)"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Please install the missing dependencies and try again."
        exit 1
    fi
    
    print_status "All dependencies found."
}

# Function to load environment variables
load_env() {
    if [ ! -f ".env" ]; then
        print_error "No .env file found!"
        print_warning "Please copy env-template to .env and configure your domains:"
        echo "  cp env-template .env"
        echo "  # Edit .env with your domain names"
        exit 1
    fi
    
    print_status "Loading environment variables from .env..."
    export $(grep -v '^#' .env | xargs)
    
    # Validate required variables
    local required_vars=(
        "HIE_DOMAIN"
        "KEYCLOAK_DOMAIN" 
        "DATA_PIPES_DOMAIN"
        "OPENHIM_API_DOMAIN"
        "SSL_CERT_PATH"
        "SSL_KEY_PATH"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Required environment variable $var is not set in .env"
            exit 1
        fi
    done
    
    print_status "Environment variables loaded successfully."
}

# Function to generate configuration files
generate_configs() {
    print_status "Generating configuration files..."
    
    # Create generated-configs directory structure
    mkdir -p generated-configs/{nginx,openhim,hapi-fhir,data-pipes}
    
    # Generate nginx configuration
    print_status "Generating nginx configuration..."
    envsubst < templates/nginx.conf.template > generated-configs/nginx/nginx.conf
    
    # Update SSL certificate paths in nginx config
    sed -i "s|{{SSL_CERT_PATH}}|/opt/ssl.crt|g" generated-configs/nginx/nginx.conf
    sed -i "s|{{SSL_KEY_PATH}}|/opt/ssl.key|g" generated-configs/nginx/nginx.conf
    
    # Generate OpenHIM configuration
    print_status "Generating OpenHIM configuration..."
    envsubst < templates/openhim-default.json.template > generated-configs/openhim/default.json
    
    # Generate HAPI FHIR configuration (copy existing if available)
    print_status "Generating HAPI FHIR configuration..."
    if [ -f "hie/hapi-fhir/application.yaml" ]; then
        cp hie/hapi-fhir/application.yaml generated-configs/hapi-fhir/
    else
        # Create a basic HAPI FHIR configuration
        cat > generated-configs/hapi-fhir/application.yaml << EOF
spring:
  datasource:
    url: jdbc:postgresql://hapi-fhir-postgres:5432/${HAPI_DB_NAME}
    username: ${HAPI_DB_USER}
    password: ${HAPI_DB_PASSWORD}
    driverClassName: org.postgresql.Driver
  jpa:
    properties:
      hibernate.dialect: org.hibernate.dialect.PostgreSQL95Dialect
      hibernate.search.enabled: false

hapi:
  fhir:
    fhir_version: R4
    defer_indexing_for_codesystems_of_size: 0
    install_transitive_ig_dependencies: true
    implementationguides:
EOF
    fi
    
    # Generate Data Pipes configuration
    print_status "Generating Data Pipes configuration..."
    envsubst < templates/data-pipes-config.yaml.template > generated-configs/data-pipes/application.yaml
    
    # Copy existing data pipes configs if they exist
    if [ -d "fhir-data-pipes/docker/config" ]; then
        cp -r fhir-data-pipes/docker/config/* generated-configs/data-pipes/ 2>/dev/null || true
    fi
    
    print_status "Configuration files generated successfully."
}

# Function to verify SSL certificates
verify_ssl_certs() {
    print_status "Verifying SSL certificates..."
    
    if [ ! -f "$SSL_CERT_PATH" ]; then
        print_error "SSL certificate not found at: $SSL_CERT_PATH"
        print_warning "Please ensure your SSL certificate is available at the specified path."
        exit 1
    fi
    
    if [ ! -f "$SSL_KEY_PATH" ]; then
        print_error "SSL private key not found at: $SSL_KEY_PATH"
        print_warning "Please ensure your SSL private key is available at the specified path."
        exit 1
    fi
    
    print_status "SSL certificates verified."
}

# Function to create docker network
create_network() {
    print_status "Creating Docker network..."
    
    if ! docker network ls | grep -q "cloudbuild"; then
        docker network create cloudbuild
        print_status "Docker network 'cloudbuild' created."
    else
        print_status "Docker network 'cloudbuild' already exists."
    fi
}

# Function to start services
start_services() {
    print_status "Starting HIE services..."
    
    # Use docker compose (newer) or docker-compose (older)
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    print_status "Building and starting containers..."
    $COMPOSE_CMD -f docker-compose.unified.yml up -d --build
    
    print_status "HIE services are starting up..."
    print_status "This may take a few minutes for all services to be ready."
}

# Function to show service status
show_status() {
    print_status "Service URLs:"
    echo ""
    echo -e "🌐 Main HIE (Provider/Patient Apps): ${GREEN}https://${HIE_DOMAIN}${NC}"
    echo -e "🔐 Keycloak (Identity Management):    ${GREEN}https://${KEYCLOAK_DOMAIN}${NC}"
    echo -e "📊 Data Pipeline (Reports):           ${GREEN}https://${DATA_PIPES_DOMAIN}${NC}"
    echo -e "🔧 OpenHIM API:                       ${GREEN}https://${OPENHIM_API_DOMAIN}/openhim-api${NC}"
    echo ""
    echo -e "📋 Provider App:     ${GREEN}https://${HIE_DOMAIN}/provider/${NC}"
    echo -e "🏥 Patient App:      ${GREEN}https://${HIE_DOMAIN}/client/${NC}"
    echo -e "🔌 HAPI FHIR:        ${GREEN}https://${HIE_DOMAIN}/hapi/${NC}"
    echo -e "🔑 ChanjoKe Auth:     ${GREEN}https://${HIE_DOMAIN}/auth/${NC}"
    echo ""
    echo -e "Default credentials (change these immediately):"
    echo -e "  Keycloak Admin: ${YELLOW}admin / ${KEYCLOAK_ADMIN_PASSWORD}${NC}"
    echo -e "  OpenHIM Admin:  ${YELLOW}root@openhim.org / (set during first login)${NC}"
}

# Function to wait for services
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    local services=("nginx-proxy:80" "openhim-core:8080" "hapi-fhir-jpa:8080" "keycloak:8080")
    local max_attempts=60
    local attempt=0
    
    for service in "${services[@]}"; do
        local container=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)
        
        print_status "Waiting for $container to be ready..."
        while [ $attempt -lt $max_attempts ]; do
            if docker exec $container sh -c "nc -z localhost $port" 2>/dev/null; then
                print_status "$container is ready!"
                break
            fi
            sleep 5
            ((attempt++))
        done
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "$container may not be ready yet. Check logs: docker logs $container"
        fi
        attempt=0
    done
}

# Main execution
main() {
    echo "============================================"
    echo "        HIE Unified Deployment Script       "
    echo "============================================"
    echo ""
    
    check_dependencies
    load_env
    verify_ssl_certs
    generate_configs
    create_network
    start_services
    wait_for_services
    show_status
    
    echo ""
    print_status "HIE deployment completed successfully! 🎉"
    echo ""
    echo "To stop the HIE:"
    echo "  ./deploy-hie.sh stop"
    echo ""
    echo "To view logs:"
    echo "  docker-compose -f docker-compose.unified.yml logs -f [service-name]"
    echo ""
    echo "To check service status:"
    echo "  docker-compose -f docker-compose.unified.yml ps"
}

# Handle command line arguments
case "${1:-}" in
    "stop")
        print_status "Stopping HIE services..."
        if docker compose version &> /dev/null; then
            docker compose -f docker-compose.unified.yml down
        else
            docker-compose -f docker-compose.unified.yml down
        fi
        print_status "HIE services stopped."
        ;;
    "restart")
        $0 stop
        sleep 5
        $0
        ;;
    "logs")
        if docker compose version &> /dev/null; then
            docker compose -f docker-compose.unified.yml logs -f "${2:-}"
        else
            docker-compose -f docker-compose.unified.yml logs -f "${2:-}"
        fi
        ;;
    "status")
        if docker compose version &> /dev/null; then
            docker compose -f docker-compose.unified.yml ps
        else
            docker-compose -f docker-compose.unified.yml ps
        fi
        ;;
    *)
        main
        ;;
esac 
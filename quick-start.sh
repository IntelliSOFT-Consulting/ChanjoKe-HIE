#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}        ChanjoKe HIE Quick Start Setup         ${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists!${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting without changes."
        exit 0
    fi
fi

# Copy template
echo -e "${GREEN}📋 Copying environment template...${NC}"
cp env-template .env

# Prompt for domain configuration
echo ""
echo -e "${CYAN}🌐 Domain Configuration${NC}"
echo "Please enter your domain names (without https://):"
echo ""

read -p "Main HIE domain (provider/patient apps): " hie_domain
read -p "Keycloak domain (authentication): " keycloak_domain
read -p "Data pipes domain (reports): " data_pipes_domain
read -p "OpenHIM API domain: " openhim_api_domain

# Update .env file
echo ""
echo -e "${GREEN}🔧 Updating configuration file...${NC}"

sed -i "s/chanjo-provider\.yourdomain\.com/$hie_domain/g" .env
sed -i "s/chanjo-auth\.yourdomain\.com/$keycloak_domain/g" .env
sed -i "s/chanjo-reports\.yourdomain\.com/$data_pipes_domain/g" .env
sed -i "s/chanjoke\.yourdomain\.com/$openhim_api_domain/g" .env

# SSL Configuration
echo ""
echo -e "${CYAN}🔒 SSL Certificate Configuration${NC}"
echo "Please ensure your SSL certificates are available:"
echo ""
echo "Expected paths:"
echo "  📄 Certificate: ./certs/star.${hie_domain#*.}.crt"
echo "  🔑 Private Key: ./certs/star.${hie_domain#*.}.key"
echo ""

# Create certs directory
mkdir -p certs

# Update SSL paths in .env
domain_wildcard="star.${hie_domain#*.}"
sed -i "s|star\.yourdomain\.com|$domain_wildcard|g" .env

echo -e "${YELLOW}📝 Please place your SSL certificate files in the ./certs/ directory${NC}"
echo ""

# Generate random passwords
echo -e "${GREEN}🔐 Generating secure passwords...${NC}"
jwt_secret=$(openssl rand -hex 32)
keycloak_admin_pass=$(openssl rand -base64 24)
mongo_pass=$(openssl rand -base64 16)

sed -i "s/your-jwt-secret-key-here/$jwt_secret/g" .env
sed -i "s/admin123/$keycloak_admin_pass/g" .env
sed -i "s/admin123/$mongo_pass/g" .env

echo ""
echo -e "${GREEN}✅ Configuration completed!${NC}"
echo ""
echo -e "${CYAN}📋 Summary:${NC}"
echo "  🌐 Main HIE: https://$hie_domain"
echo "  🔐 Keycloak: https://$keycloak_domain"  
echo "  📊 Reports:  https://$data_pipes_domain"
echo "  🔧 API:      https://$openhim_api_domain"
echo ""
echo -e "${YELLOW}🚀 Next steps:${NC}"
echo "  1. Place SSL certificates in ./certs/ directory"
echo "  2. Review and adjust .env if needed"
echo "  3. Run: ./deploy-hie.sh"
echo ""
echo -e "${GREEN}📖 For detailed documentation, see: README-SIMPLIFIED-DEPLOYMENT.md${NC}" 
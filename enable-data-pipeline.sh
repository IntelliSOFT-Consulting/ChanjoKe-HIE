#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}        Enable Data Pipeline Service          ${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""

# Check if docker-compose.unified.yml exists
if [ ! -f "docker-compose.unified.yml" ]; then
    echo -e "${RED}❌ docker-compose.unified.yml not found!${NC}"
    echo "Please run this script from the HIE root directory."
    exit 1
fi

echo -e "${YELLOW}📊 Data Pipeline Options:${NC}"
echo ""
echo "1. Build from source (recommended - builds locally)"
echo "2. Use Google Cloud image (requires authentication)"
echo "3. Skip data pipeline (current setup)"
echo ""

read -p "Choose option (1-3): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}🔧 Enabling data pipeline with local build...${NC}"
        
        # Check if fhir-data-pipes directory exists
        if [ ! -d "fhir-data-pipes" ]; then
            echo -e "${RED}❌ fhir-data-pipes directory not found!${NC}"
            echo "The data pipeline source code should be in ./fhir-data-pipes/"
            exit 1
        fi
        
        # Uncomment the build version
        sed -i '/# pipeline-controller:/,/# SPRING_CONFIG_LOCATION: \/app\/config\/application.yaml/s/^#   /  /' docker-compose.unified.yml
        sed -i 's/^#     build:/    build:/' docker-compose.unified.yml
        sed -i 's/^#       context:/      context:/' docker-compose.unified.yml
        sed -i 's/^#       dockerfile:/      dockerfile:/' docker-compose.unified.yml
        
        # Uncomment the dependency in nginx
        sed -i 's/# - pipeline-controller/- pipeline-controller/' docker-compose.unified.yml
        
        echo -e "${GREEN}✅ Data pipeline enabled with local build${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${GREEN}🔧 Enabling data pipeline with Google Cloud image...${NC}"
        echo -e "${YELLOW}⚠️  You'll need to authenticate with Google Cloud first:${NC}"
        echo "   gcloud auth configure-docker us-docker.pkg.dev"
        echo ""
        
        # Uncomment the Google Cloud image version  
        sed -i '/# OPTION 2: Use pre-built image/,/# SPRING_CONFIG_LOCATION: \/workspace\/config\/application.yaml/s/^# //' docker-compose.unified.yml
        
        # Uncomment the dependency in nginx
        sed -i 's/# - pipeline-controller/- pipeline-controller/' docker-compose.unified.yml
        
        echo -e "${GREEN}✅ Data pipeline enabled with Google Cloud image${NC}"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}⏭️  Keeping data pipeline disabled${NC}"
        echo "You can enable it later by running this script again."
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}📋 Next Steps:${NC}"
echo "1. Restart HIE services: ./deploy-hie.sh restart"
echo "2. Check pipeline status: ./deploy-hie.sh logs pipeline-controller"
echo "3. Access reports at: https://${DATA_PIPES_DOMAIN:-chanjo-reports.intellisoftkenya.com}"
echo ""
echo -e "${GREEN}✅ Data pipeline configuration updated!${NC}" 
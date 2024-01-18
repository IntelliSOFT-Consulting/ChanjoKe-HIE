#!/bin/bash

if [ -n "$1" ]; then
    # Keycloak
    docker compose -f fhir-gateway/docker/keycloak/config-compose.yaml $1 $2 $3 $4 $5
    # Gateway
    docker compose -f fhir-gateway/docker/hapi-proxy-compose.yaml $1 $2 $3 $4 $5
else
    # Start Keycloak
    docker compose -f fhir-gateway/docker/keycloak/config-compose.yaml up -d --force-recreate
    # Start Gateway
    docker compose -f fhir-gateway/docker/hapi-proxy-compose.yaml up -d fhir-proxy --force-recreate
fi
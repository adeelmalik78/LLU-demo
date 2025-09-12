#!/bin/bash

#################################################################################
##  This script automates the complete Liquibase License Usage (LLU) demo:
##  1. Spins up three PostgreSQL databases (dev, qa, prod)
##  2. Runs Liquibase flow file against all three databases
##  3. Generates LLU usage report
##
##  Usage:
##    ./run.sh
##    
#################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
# LIQUIBASE_LICENSE_KEY="<LIQUIBASE_PRO_LICENSE_HERE>"
LIQUIBASE_LLU_PATH="../liquibase-secure-5.0.0-rc1/dist/liquibase-license-tracking"
export SERVER_PORT=8123
export POSTGRES_PORT=5430

print_header() {
    echo -e "${BLUE}#################################################################################${NC}"
    echo -e "${BLUE}##  $1${NC}"
    echo -e "${BLUE}#################################################################################${NC}"
}

print_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to wait for container to be ready
wait_for_container() {
    local container_name=$1
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Waiting for $container_name to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $container_name echo "Container ready" >/dev/null 2>&1; then
            print_step "$container_name is ready"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$container_name failed to become ready after $max_attempts attempts"
    return 1
}

# Clean up stopped containers before starting new ones
print_header "Cleaning Up Stopped Containers"
echo -e "${YELLOW}Removing stopped containers...${NC}"
docker container prune -f >/dev/null 2>&1
sleep 2
print_step "Container cleanup completed"

# Check if Java Home is Java 17 or higher
print_header "Starting the PostgreSQL database"

# Check if postgres-llu container is already running
if docker ps --format '{{.Names}}' | grep -q "^postgres-llu$"; then
    print_step "PostgreSQL container 'postgres-llu' is already running"
else
    echo -e "${YELLOW}Starting postgres-llu container...${NC}"
    docker run \
        --name postgres-llu \
        -p ${POSTGRES_PORT}:5432 \
        -e POSTGRES_PASSWORD=secret \
        -d postgres
    print_step "PostgreSQL container 'postgres-llu' started successfully"
fi

wait_for_container postgres-llu
if [ $? -eq 0 ]; then
    print_step "Postgres container 'llu-container' started successfully"
else
    print_error "Postgres container failed to become ready"
    exit 1
fi



# Start Liquibase License Utility
print_header "Starting Liquibase License Utility"

# Check if llu-container is already running
if docker ps --format '{{.Names}}' | grep -q "^llu-container$"; then
    print_step "LLU container 'llu-container' is already running"
else
    echo -e "${YELLOW}Starting llu-container...${NC}"
    if docker run -d \
      -v $PWD:/db \
      -p ${SERVER_PORT}:${SERVER_PORT} \
      --env SERVER_PORT=${SERVER_PORT} \
      --name llu-container \
      -e SPRING_DATASOURCE_URL="jdbc:postgresql://host.docker.internal:${POSTGRES_PORT}/postgres" \
      -e SPRING_DATASOURCE_USERNAME="postgres" \
      -e SPRING_DATASOURCE_PASSWORD="secret" \
      liquibase/liquibase-license-tracking:latest >/dev/null; then
        echo -e "${YELLOW}Waiting for container to initialize...${NC}"
        sleep 5
        wait_for_container llu-container
        if [ $? -eq 0 ]; then
            print_step "LLU container 'llu-container' started successfully"
        else
            print_error "LLU container failed to become ready"
            exit 1
        fi
    else
        print_error "Failed to start llu-container"
        exit 1
    fi
fi



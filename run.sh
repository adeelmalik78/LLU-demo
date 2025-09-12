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
LIQUIBASE_PATH="../liquibase-secure-5.0.0-rc1/liquibase"
FLOW_FILE="liquibase.flowfile.yaml"
PROPERTIES_FILE="liquibase.properties"
export SERVER_PORT="8123"

# Database configurations
DATABASES[dev]=5432
DATABASES[qa]=5433
DATABASES[prod]=5434

dev_port=5432
qa_port=5433
prod_port=5434

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

# Function to wait for PostgreSQL to accept connections
wait_for_postgres() {
    local container_name=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Waiting for PostgreSQL in $container_name to accept connections...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $container_name pg_isready -U postgres >/dev/null 2>&1; then
            print_step "PostgreSQL in $container_name is ready"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "PostgreSQL in $container_name failed to become ready"
    return 1
}

# Function to check if web server is running
check_web_server() {
    local port=$1
    
    if curl -s --max-time 5 --connect-timeout 3 "http://localhost:${port}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to run Liquibase flow
run_liquibase_flow() {
    local env_name=$1
    local port=$2
    
    print_header "Running Liquibase Flow Against $env_name Database (Port: $port)"
        
    echo -e "${YELLOW}Executing Liquibase flow...${NC}"
    if $LIQUIBASE_PATH --license-key="$LIQUIBASE_LICENSE_KEY" --url="jdbc:postgresql://localhost:${port}/postgres" flow --flow-file=$FLOW_FILE; then
        print_step "Liquibase flow completed successfully for $env_name"
        sleep 2
    else
        print_error "Liquibase flow failed for $env_name"
        return 1
    fi
}

# Main execution starts here
print_header "Starting Liquibase License Usage Demo"


# Set environment variables
export LIQUIBASE_LICENSE_KEY="$LIQUIBASE_LICENSE_KEY"

# Clean up existing containers
print_header "Cleaning Up Existing Containers"
containers_to_cleanup="postgres-dev postgres-qa postgres-prod"

for container in $containers_to_cleanup; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "${YELLOW}Removing existing container: $container${NC}"
        docker rm -f $container >/dev/null 2>&1
        print_step "Removed $container"
    fi
done

# Check if LLU is running
print_header "Checking if Liquibase License Utility is running"

# Check if web server is running before opening browser
if ! check_web_server "${SERVER_PORT}"; then
    print_error "Liquibase Licence Utility not running on localhost:${SERVER_PORT}. Please start LLU and try running this script again"
    exit 1
fi

# Start PostgreSQL databases
print_header "Starting PostgreSQL Databases"

# Start postgres-dev
echo -e "${YELLOW}Starting postgres-dev on port 5432...${NC}"
docker run --name postgres-dev -p 5432:5432 -e POSTGRES_PASSWORD=secret -d postgres >/dev/null
wait_for_postgres postgres-dev 5432

# Start postgres-qa
echo -e "${YELLOW}Starting postgres-qa on port 5433...${NC}"
docker run --name postgres-qa -p 5433:5432 -e POSTGRES_PASSWORD=secret -d postgres >/dev/null
wait_for_postgres postgres-qa 5433

# Start postgres-prod
echo -e "${YELLOW}Starting postgres-prod on port 5434...${NC}"
docker run --name postgres-prod -p 5434:5432 -e POSTGRES_PASSWORD=secret -d postgres >/dev/null
wait_for_postgres postgres-prod 5434

print_step "All PostgreSQL databases are running"

# Check if Liquibase exists
if [ ! -f "$LIQUIBASE_PATH" ]; then
    print_error "Liquibase not found at $LIQUIBASE_PATH"
    print_error "Please ensure Liquibase Pro is installed at the correct path"
    exit 1
fi

# Run Liquibase flows against all databases

# port=${DATABASES[${env_name}]}
run_liquibase_flow "dev" 5432
# Add a small delay between runs
sleep 1

run_liquibase_flow "qa" 5433
# Add a small delay between runs
sleep 1

run_liquibase_flow "prod" 5434
# Add a small delay between runs
sleep 1

# Open LLU report in browser (always)
print_header "Opening LLU Usage Report in Browser"

echo -e "${YELLOW}Opening browser to view LLU report at: ${BLUE}http://localhost:${SERVER_PORT}/v1/report${NC}"

# Detect OS and open browser appropriately
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if open "http://localhost:${SERVER_PORT}/v1/report" 2>/dev/null; then
        print_step "Browser opened successfully (macOS)"
    else
        print_warning "Failed to open browser automatically"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if xdg-open "http://localhost:${SERVER_PORT}/v1/report" 2>/dev/null; then
        print_step "Browser opened successfully (Linux)"
    else
        print_warning "Failed to open browser automatically"
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    if start "http://localhost:${SERVER_PORT}/v1/report" 2>/dev/null; then
        print_step "Browser opened successfully (Windows)"
    else
        print_warning "Failed to open browser automatically"
    fi
else
    print_warning "Unknown OS type, cannot open browser automatically"
fi

echo -e "${BLUE}If the browser didn't open automatically, please visit: ${YELLOW}http://localhost:${SERVER_PORT}/v1/report${NC}"
print_step "LLU report is available in your browser"
       

# Show final status
print_header "Final Status"
echo -e "${BLUE}Running Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

print_header "Demo Completed Successfully!"
echo -e "${GREEN}✓ 3 PostgreSQL databases started and configured${NC}"
echo -e "${GREEN}✓ Liquibase flows executed against all databases${NC}"

# Shutdown all containers
print_header "Shutting Down All Containers"
containers_to_shutdown="postgres-dev postgres-qa postgres-prod"
if [ "$START_LLU" = true ]; then
    containers_to_shutdown="$containers_to_shutdown llu"
fi

for container in $containers_to_shutdown; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "${YELLOW}Stopping and removing container: $container${NC}"
        docker stop $container >/dev/null 2>&1
        docker rm $container >/dev/null 2>&1
        print_step "Stopped and removed $container"
    fi
done

print_step "All containers have been shut down and removed"
echo -e "${GREEN}Demo cleanup completed!${NC}"
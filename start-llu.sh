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
LIQUIBASE_LLU_PATH="../liquibase-license-utility-0.0.1"
JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.6

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

# Check if Java Home is Java 17 or higher
print_header "Checking if JAVA_HOME is set to Java 17 or higher"

# Check if JAVA_HOME is set
if [ -z "$JAVA_HOME" ]; then
    print_error "JAVA_HOME environment variable is not set"
    print_error "Please set JAVA_HOME to point to Java 17 or higher installation"
    exit 1
fi

# Check if JAVA_HOME directory exists
if [ ! -d "$JAVA_HOME" ]; then
    print_error "JAVA_HOME directory does not exist: $JAVA_HOME"
    exit 1
fi

# Check if java executable exists
JAVA_EXEC="$JAVA_HOME/bin/java"
if [ ! -f "$JAVA_EXEC" ]; then
    print_error "Java executable not found at: $JAVA_EXEC"
    exit 1
fi

echo -e "${YELLOW}Checking Java version at: $JAVA_HOME${NC}"

# Get Java version
JAVA_VERSION_OUTPUT=$("$JAVA_EXEC" -version 2>&1 | head -n 1)
echo -e "${YELLOW}Java version output: $JAVA_VERSION_OUTPUT${NC}"

# Extract version number (handles both old format like "1.8.0" and new format like "17.0.1")
JAVA_VERSION=$(echo "$JAVA_VERSION_OUTPUT" | sed -n 's/.*version "\([0-9]*\).*/\1/p')

if [ -z "$JAVA_VERSION" ]; then
    print_error "Could not determine Java version from: $JAVA_VERSION_OUTPUT"
    exit 1
fi

# Check if version is 17 or higher
if [ "$JAVA_VERSION" -lt 17 ]; then
    print_error "Java version $JAVA_VERSION is less than required version 17"
    print_error "Please set JAVA_HOME to point to Java 17 or higher installation"
    exit 1
fi

print_step "Java version $JAVA_VERSION detected - meets minimum requirement (17+)"


sleep 2

# Start Liquibase License Utility
print_header "Starting Liquibase License Utility"


# Start LLU 
cd ${LIQUIBASE_LLU_PATH}
./start.sh


# docker run -d \
#     -v $PWD/llu_db:/db \
#     -p 8080:8080 \
#     --name llu \
#     --env SERVER_PORT=8123 \
#     docker-llu.liquibase.net/llu:0.1-SNAPSHOT
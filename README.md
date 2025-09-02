# Liquibase License Usage (LLU) Demo

This repository demonstrates how to track Liquibase Pro license usage across multiple database environments using the Liquibase License Usage (LLU) server and Docker containers.

## Prerequisites

### Required Software
<!-- - Docker installed and running -->
- Liquibase Pro 4.33.0+ installed. Used as `LIQUIBASE_PATH="../liquibase-pro-4.33.0/liquibase"`
- Liquibase License Utilities installed. Used as `LIQUIBASE_LLU_PATH="../liquibase-license-utility-0.0.1"`
- Valid Liquibase Pro license key. Used as `LIQUIBASE_LICENSE_KEY="ABwwGgQUWlMd5..."`
- Bash shell environment

<!-- ### Docker Image Setup (REQUIRED)
Before running any scripts, you must first download the LLU Docker image:

```bash
# Login to the Docker registry (replace PASSWORD_IN_BITWARDEN with actual password)
docker login docker-llu.liquibase.net -u testuserllu -p PASSWORD_IN_BITWARDEN

# Pull the LLU Docker image
docker pull docker-llu.liquibase.net/llu:0.1-SNAPSHOT
```

**⚠️ Important**: The demo will fail if you haven't downloaded the LLU Docker image first. -->

## Overview

The demo showcases:
- Multi-environment database deployments (dev, qa, prod)
- Liquibase Pro license usage tracking with LLU server
- Automated workflow execution
- Usage report generation (when LLU is enabled)

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   PostgreSQL    │    │   PostgreSQL    │
│   (dev)         │    │   (qa)          │    │   (prod)        │
│   Port: 5432    │    │   Port: 5433    │    │   Port: 5434    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                        ┌─────────────────┐
                        │  LLU Server     │
                        │  Port: 8080     │
                        └─────────────────┘
```

## Quick Start

### Automated Execution (Recommended)

The script supports two modes of operation:

```bash
./run.sh
```
This starts the LLU server and tracks license usage during database deployments.

#### Help
```bash
./run.sh --help
```

## What Each Mode Does

### Standard Mode (`./run.sh`)
1. Clean up any existing containers
2. Start 3 PostgreSQL databases
3. Execute Liquibase flows against all databases
4. Clean up all containers


#### 3. Run Liquibase Flows
```bash
# Set license key
export LIQUIBASE_LICENSE_KEY="your_license_key_here"

# Run against dev (port 5432)
../liquibase-pro-4.33.0/liquibase --license-key="$LIQUIBASE_LICENSE_KEY" --url="jdbc:postgresql://localhost:5432/postgres" flow --flow-file=liquibase.flowfile.yaml

# Run against qa (port 5433)
../liquibase-pro-4.33.0/liquibase --license-key="$LIQUIBASE_LICENSE_KEY" --url="jdbc:postgresql://localhost:5433/postgres" flow --flow-file=liquibase.flowfile.yaml

# Run against prod (port 5434)
../liquibase-pro-4.33.0/liquibase --license-key="$LIQUIBASE_LICENSE_KEY" --url="jdbc:postgresql://localhost:5434/postgres" flow --flow-file=liquibase.flowfile.yaml
```

#### 4. Generate Report (If LLU Server is Running)

Opens a browser to this location:
http://localhost:8080/v1/report

## File Structure

```
LLU-UAT/
├── README.md                    # This documentation
├── run.sh                      # Complete automation script with --llu option
├── setup-llu.sh               # LLU server setup script
├── liquibase.flowfile.yaml    # Liquibase flow configuration
├── liquibase.properties       # Database connection properties
├── changelog.xml               # Database change log
├── main/
│   ├── 100_ddl/               # DDL scripts
│   │   ├── 01_sales.sql
│   │   ├── 02_employee.sql
│   │   └── 03_contractors.sql
│   └── 700_dml/               # DML scripts
│       └── Q4-2022_employees2.sql
├── llu_db/                    # LLU database storage (created at runtime)
└── readme.txt                 # Additional setup notes
```

## What Happens During Execution

### 1. Container Setup
- **postgres-dev**: PostgreSQL on port 5432
- **postgres-qa**: PostgreSQL on port 5433  
- **postgres-prod**: PostgreSQL on port 5434
- **llu**: License Usage server on port 8080 (only when `--llu` is used)

### 2. Liquibase Flow Execution (Per Database)
Each database goes through the same flow:

1. **Status Check**: Verify connection and pending changes
2. **Changelog Checks**: Validate changelog quality
3. **Update**: Apply database changes (DDL and DML)
4. **Database Checks**: Validate deployed database
5. **History**: Record deployment history
6. **DropAll**: Clean up (in endStage)

### 3. Changes Applied
The following database objects are created and populated:
- Sales tables and data
- Employee tables and data  
- Contractor tables and data
- Sample data for Q4 2022 employees

### 4. License Usage Tracking
The LLU server tracks:
- Number of Liquibase operations
- Commands executed
- Environments targeted
- Timestamp information
- License utilization metrics

### 5. Report Generation
The final report includes:
- License usage summary
- Operation counts by environment
- Detailed execution history
- Resource utilization metrics

## Configuration Details

### Liquibase Properties
```properties
changeLogFile=changelog.xml
# URLs are dynamically updated by the script for each database
username: postgres
password: secret
liquibase.license.utility.enabled=true
liquibase.license.utility.url=http://localhost:8080
liquibase.license.utility.trackingId=LLU-DEMO
```

### Flow File Structure
```yaml
stages:
  Default:
    actions:
      - type: liquibase
        command: status
      - type: liquibase  
        command: checks run
        cmdArgs: {checks-scope: changelog}
      - type: liquibase
        command: update
      - type: liquibase
        command: checks run
        cmdArgs: {checks-scope: database}

endStage:
  actions:
    - type: liquibase
      command: history
    - type: liquibase
      command: dropAll
```

## Troubleshooting

### Common Issues

1. **Docker Image Not Found**
   - Ensure you've run the Docker login and pull commands from the Prerequisites section
   - Verify the LLU Docker image is available: `docker images | grep llu`

2. **License Key Invalid**
   - Ensure the license key is properly set in the script
   - Verify the license is valid and not expired

3. **Containers Already Running**
   - The script automatically cleans up existing containers
   - Manual cleanup: `docker rm -f postgres-dev postgres-qa postgres-prod llu`

4. **Liquibase Not Found**
   - Verify Liquibase Pro is installed at `../liquibase-pro-4.33.0/`
   - Update the `LIQUIBASE_PATH` variable in run.sh if needed

5. **Port Conflicts**
   - Ensure ports 5432, 5433, 5434, and 8080 are available
   - Stop any conflicting services before running

### Logs and Debugging

- Container logs: `docker logs <container_name>`
- LLU server logs: `docker exec llu cat /app/logs/application.log`
- Liquibase verbose output: Add `--verbose` to Liquibase commands

## Script Usage Examples

```bash
# Run basic demo without license tracking
./run.sh

# Run full demo with license tracking and reporting
./run.sh --llu

# Show help and available options
./run.sh --help
```

## Customization

### Adding New Environments
1. Add new database ports to the `DATABASES` array in run.sh
2. Create additional PostgreSQL containers
3. Update the flow execution loop

### Modifying Database Changes
1. Edit files in `main/100_ddl/` for schema changes
2. Edit files in `main/700_dml/` for data changes  
3. Update `changelog.xml` to reference new files

### Changing LLU Configuration
1. Update tracking ID in `liquibase.properties`
2. Modify LLU server environment variables in `setup-llu.sh`

## Output Example

When running `./run.sh --llu`, you'll see colored output showing:
- Container startup progress
- Database readiness checks
- Liquibase flow execution results
- Generated report content (with LLU)
- Final cleanup status

## Benefits Demonstrated

- **Flexible Operation**: Run with or without license tracking based on needs
- **Centralized License Tracking**: Monitor usage across all environments (LLU mode)
- **Automated Deployments**: Consistent, repeatable database updates
- **Quality Assurance**: Built-in changelog and database validation
- **Audit Trail**: Complete history of all database operations
- **Resource Optimization**: Track license utilization for planning (LLU mode)

## Next Steps

After running this demo, consider:
- Integrating with CI/CD pipelines
- Adding additional quality checks
- Implementing approval workflows
- Scaling to more environments
- Setting up automated reporting schedules (for LLU deployments)
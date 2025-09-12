# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a Liquibase License Usage (LLU) demonstration that showcases license tracking across multiple database environments. It automates database deployments using Liquibase Pro flows while tracking license usage through the Liquibase License Utility server.

## Essential Commands

### Primary Demo Execution
- `./run.sh` - Complete demo automation: starts PostgreSQL databases (dev/qa/prod), runs Liquibase flows, generates usage reports
- `./start-llu.sh` - Starts the Liquibase License Utility server (prerequisite for tracking)
- `./start-llu-container.sh` - Alternative LLU startup using Docker container

### Direct Liquibase Commands
```bash
# Run flow against specific environment
../liquibase-secure-5.0.0-rc1/liquibase --license-key="$LIQUIBASE_LICENSE_KEY" \
  --url="jdbc:postgresql://localhost:5432/postgres" \
  flow --flow-file=liquibase.flowfile.yaml

# Access LLU report (when LLU server is running)
open "http://localhost:8123/v1/report"
```

### Environment Setup Requirements
- Java 17+ required (checked by start-llu.sh)
- Docker required for PostgreSQL databases
- Liquibase Pro at `../liquibase-secure-5.0.0-rc1/liquibase` (path configurable in run.sh)
- Valid Liquibase Pro license key as `LIQUIBASE_LICENSE_KEY` environment variable

## Architecture

### Database Structure
- **3 PostgreSQL environments**: dev (5432), qa (5433), prod (5434)
- **LLU Server**: Port 8123 for license tracking
- **Multi-environment deployment**: Same changeset deployed across all environments

### Directory Structure
```
main/
├── 100_ddl/          # DDL scripts (sales, employee, contractors tables)
│   ├── 01_sales.sql
│   ├── 02_employee.sql
│   ├── 03_contractors.sql
│   └── *-rollback.sql # Rollback scripts for each DDL
└── 700_dml/          # DML scripts (data population)
    └── Q4-2022_employees2.sql
```

### Configuration Files
- **liquibase.properties**: Database connection settings, LLU configuration
- **liquibase.flowfile.yaml**: Multi-step workflow (status → checks → update → checks → history → dropAll)
- **changelog.xml**: Master changelog referencing DDL and DML scripts

## Key Configuration Details

### LLU Integration
- License tracking enabled via `liquibase.license.utility.enabled=true`
- Tracking ID: `LLU_UAT`
- Server URL: `http://localhost:8123` (configurable via SERVER_PORT)

### Flow Execution Pattern
1. **Status check** - Verify database state
2. **Changelog validation** - Quality checks on changes
3. **Update execution** - Apply database changes
4. **Database validation** - Post-deployment checks
5. **History recording** - Audit trail
6. **Cleanup** - dropAll in endStage (always runs)

### Environment Variables Used
- `LIQUIBASE_LICENSE_KEY` - Pro license key (required)
- `SERVER_PORT` - LLU server port (default 8123, used by start-llu-container.sh)
- `JAVA_HOME` - Java 17+ installation path (checked by start-llu.sh)
- `LIQUIBASE_PATH` - Path to Liquibase executable (set in run.sh, defaults to `../liquibase-secure-5.0.0-rc1/liquibase`)

## Development Notes

### Script Behavior
- `run.sh` automatically cleans up existing containers before starting
- Database readiness checks ensure PostgreSQL is accepting connections
- Colored output provides clear status feedback
- Automatic browser opening for LLU reports (cross-platform)
- Sequential execution with delays between environments

### Error Handling
- Scripts exit on first error (`set -e`)
- Comprehensive prerequisite checks (Java version, Liquibase path, license key)
- Container health verification before proceeding

### Customization Points
- Database ports can be modified in the DATABASES array in run.sh
- Flow file (`liquibase.flowfile.yaml`) can be customized for different deployment patterns
- Additional environments can be added by extending the container setup loop in run.sh
- LLU tracking ID can be changed in `liquibase.properties` (currently `LLU_UAT`)
- Liquibase executable path can be updated via `LIQUIBASE_PATH` variable in run.sh
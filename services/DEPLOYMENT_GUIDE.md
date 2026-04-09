# Deployment & Quick Start Guide

## Prerequisites

- Docker & Docker Compose (for container deployment)
- OR Java 21 + Gradle (for local development)
- PostgreSQL 16 (for local development without Docker)

## Option 1: Docker Compose (Recommended)

### Quick Start

```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Remove all data (fresh start)
docker-compose down -v
```

### Verify Services

```bash
# Check Dispatch Service
curl http://localhost:8084/api/dispatch/plans

# Check Inspection Service  
curl http://localhost:8085/api/inspection/items

# Check PostgreSQL
docker exec skep-postgres psql -U postgres -l
```

### Service Endpoints

| Service | URL | Port |
|---------|-----|------|
| Dispatch Service | http://localhost:8084 | 8084 |
| Inspection Service | http://localhost:8085 | 8085 |
| PostgreSQL | localhost | 5432 |

## Option 2: Local Development Setup

### Step 1: Start PostgreSQL

```bash
# Option A: Using Docker
docker run -d \
  --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_INITDB_ARGS="--encoding=UTF8" \
  -p 5432:5432 \
  postgres:16-alpine

# Option B: Using existing PostgreSQL
# Just ensure it's running on port 5432
```

### Step 2: Create Databases

```bash
psql -U postgres -h localhost
```

```sql
CREATE DATABASE dispatch_db;
CREATE DATABASE inspection_db;
\q
```

### Step 3: Start Dispatch Service

```bash
cd dispatch-service
./gradlew bootRun
```

Service runs on `http://localhost:8084`

### Step 4: Start Inspection Service (new terminal)

```bash
cd inspection-service
./gradlew bootRun
```

Service runs on `http://localhost:8085`

## Database Migrations

### Automatic Migration (Flyway)

When services start, Flyway automatically:
1. Creates schema if not exists
2. Executes migration files in `src/main/resources/db/migration/`
3. Tracks migration history

### Adding New Migrations

1. Create SQL file: `src/main/resources/db/migration/V2__description.sql`
2. Follow Flyway naming convention: `V{version}__{description}.sql`
3. Restart service to apply

Example:

```bash
# Dispatch Service migration
cat > dispatch-service/src/main/resources/db/migration/V2__add_status_column.sql << 'SQL'
ALTER TABLE deployment_plans ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;
SQL
```

## Sample API Requests

### Dispatch Service

#### Create Deployment Plan

```bash
curl -X POST http://localhost:8084/api/dispatch/plans \
  -H "Content-Type: application/json" \
  -d '{
    "supplierId": "550e8400-e29b-41d4-a716-446655440000",
    "bpCompanyId": "550e8400-e29b-41d4-a716-446655440001",
    "siteName": "Site A",
    "equipmentId": "550e8400-e29b-41d4-a716-446655440002",
    "startDate": "2026-03-20",
    "startTime": "08:00:00",
    "endDate": "2026-04-20",
    "endTime": "17:00:00",
    "rateDaily": 100000,
    "rateOvertime": 15000,
    "notes": "Sample deployment plan"
  }'
```

#### Get Plans

```bash
curl http://localhost:8084/api/dispatch/plans
```

### Inspection Service

#### Get Inspection Items

```bash
curl http://localhost:8085/api/inspection/items/equipment-type/550e8400-e29b-41d4-a716-446655440000
```

#### Start Safety Inspection

```bash
curl -X POST http://localhost:8085/api/inspection/safety/start \
  -H "Content-Type: application/json" \
  -d '{
    "equipmentId": "550e8400-e29b-41d4-a716-446655440002",
    "inspectorId": "550e8400-e29b-41d4-a716-446655440003",
    "inspectionDate": "2026-03-20",
    "inspectorGpsLat": 37.4979,
    "inspectorGpsLng": 127.0276,
    "equipmentGpsLat": 37.4979,
    "equipmentGpsLng": 127.0276
  }'
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :8084  # Dispatch Service
lsof -i :8085  # Inspection Service
lsof -i :5432  # PostgreSQL

# Kill process
kill -9 <PID>

# Or change port in application.yml
```

### Database Connection Error

```bash
# Check PostgreSQL logs
docker logs skep-postgres

# Verify connection
psql -U postgres -h localhost -c "SELECT 1"

# Reset databases
docker-compose down -v
docker-compose up -d postgres
docker-compose up -d
```

### Flyway Migration Failed

```bash
# Check flyway_schema_history table
psql -U postgres -d dispatch_db -c "SELECT * FROM flyway_schema_history;"

# Clear and restart
docker-compose down -v
docker-compose up -d
```

### Service Won't Start

```bash
# Check logs
docker-compose logs dispatch-service
docker-compose logs inspection-service

# Rebuild images
docker-compose build --no-cache
docker-compose up -d
```

## Health Checks

### Application Health

```bash
# Dispatch Service
curl http://localhost:8084/api/dispatch/plans

# Inspection Service
curl http://localhost:8085/api/inspection/items
```

### Database Health

```bash
# Docker Compose
docker-compose ps

# Manual check
psql -U postgres -h localhost -c "SELECT 1"
```

## Performance Tuning

### Gradle Build Optimization

Edit `gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
org.gradle.parallel=true
org.gradle.caching=true
```

### PostgreSQL Optimization

Add to docker-compose.yml services.postgres.command:

```yaml
command:
  - "postgres"
  - "-c"
  - "shared_buffers=256MB"
  - "-c"
  - "effective_cache_size=1GB"
  - "-c"
  - "work_mem=16MB"
```

## Environment Variables

See `.env.example` for all available options:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DISPATCH_DB_NAME=dispatch_db
INSPECTION_DB_NAME=inspection_db
DISPATCH_SERVICE_PORT=8084
INSPECTION_SERVICE_PORT=8085
LOG_LEVEL=INFO
```

## Monitoring & Logging

### View Service Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dispatch-service
docker-compose logs -f inspection-service
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs -f --tail=100 dispatch-service
```

### Log Levels

Change in `src/main/resources/application.yml`:

```yaml
logging:
  level:
    root: INFO
    com.skep: DEBUG  # Your app packages
    org.springframework: INFO
    org.hibernate: DEBUG  # SQL logging
```

## Backup & Restore

### Backup Database

```bash
docker exec skep-postgres pg_dump -U postgres dispatch_db > dispatch_db.sql
docker exec skep-postgres pg_dump -U postgres inspection_db > inspection_db.sql
```

### Restore Database

```bash
docker exec -i skep-postgres psql -U postgres dispatch_db < dispatch_db.sql
docker exec -i skep-postgres psql -U postgres inspection_db < inspection_db.sql
```

## Production Checklist

- [ ] Change default PostgreSQL password
- [ ] Set up regular database backups
- [ ] Configure health checks
- [ ] Set up monitoring (Prometheus, Grafana, etc.)
- [ ] Enable application logging aggregation
- [ ] Configure rate limiting if behind load balancer
- [ ] Set resource limits in docker-compose.yml
- [ ] Review and optimize database indexes
- [ ] Test disaster recovery procedures
- [ ] Document runbooks for common issues

## Next Steps

1. Review service-specific README files:
   - `dispatch-service/README.md`
   - `inspection-service/README.md`

2. Explore API documentation with tools like Swagger/Springdoc

3. Set up CI/CD pipeline for automated deployments

4. Configure monitoring and alerting

5. Implement API gateway for production

## Support

For detailed information, see individual service README files in their respective directories.

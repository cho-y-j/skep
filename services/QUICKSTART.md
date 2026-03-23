# SKEP Microservices - Quick Start Guide

## Installation & Setup

### Prerequisites
- Docker & Docker Compose installed
- Java 21 JDK (for local development)
- Gradle (optional, wrapper included)

### Option 1: Docker Compose (Recommended)

```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop all services
docker-compose down
```

Services will be available at:
- Settlement Service: http://localhost:8086
- Notification Service: http://localhost:8087
- Location Service: http://localhost:8088
- PostgreSQL: localhost:5432

### Option 2: Local Development

#### Setup PostgreSQL
```bash
# Create databases
psql -U postgres
CREATE DATABASE skep_settlement;
CREATE DATABASE skep_notification;
CREATE DATABASE skep_location;
```

#### Build & Run Each Service
```bash
# Settlement Service
cd settlement-service
gradle build
gradle bootRun

# In new terminal - Notification Service
cd notification-service
gradle build
gradle bootRun

# In new terminal - Location Service
cd location-service
gradle build
gradle bootRun
```

---

## API Testing

### Settlement Service Examples

**Generate Settlement**
```bash
curl -X POST http://localhost:8086/api/settlement/generate \
  -H "Content-Type: application/json" \
  -d '{
    "deploymentPlanId": "550e8400-e29b-41d4-a716-446655440000",
    "supplierId": "550e8400-e29b-41d4-a716-446655440001",
    "bpCompanyId": "550e8400-e29b-41d4-a716-446655440002",
    "yearMonth": "2024-01"
  }'
```

**Get Settlements**
```bash
curl http://localhost:8086/api/settlement \
  -H "Content-Type: application/json"
```

**Get Settlement Details**
```bash
curl http://localhost:8086/api/settlement/{id} \
  -H "Content-Type: application/json"
```

**Send Settlement Email**
```bash
curl -X POST http://localhost:8086/api/settlement/{id}/send \
  -H "Content-Type: application/json" \
  -d '{"bpEmailAddress": "bp@example.com"}'
```

**Mark as Paid**
```bash
curl -X PUT http://localhost:8086/api/settlement/{id}/mark-paid \
  -H "Content-Type: application/json"
```

**Get Supplier Statistics**
```bash
curl http://localhost:8086/api/settlement/statistics/supplier/{supplierId} \
  -H "Content-Type: application/json"
```

---

### Notification Service Examples

**Send Notification**
```bash
curl -X POST http://localhost:8087/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "type": "PAYMENT",
    "title": "Payment Processed",
    "body": "Your payment has been processed",
    "recipientId": "550e8400-e29b-41d4-a716-446655440003",
    "priority": "NORMAL"
  }'
```

**Get My Notifications**
```bash
curl "http://localhost:8087/api/notifications/my?userId=550e8400-e29b-41d4-a716-446655440003" \
  -H "Content-Type: application/json"
```

**Register FCM Token**
```bash
curl -X POST http://localhost:8087/api/notifications/fcm/register \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "550e8400-e29b-41d4-a716-446655440003",
    "token": "fcm_token_here",
    "deviceType": "ANDROID"
  }'
```

**Send Message**
```bash
curl -X POST http://localhost:8087/api/notifications/messages \
  -H "Content-Type: application/json" \
  -d '{
    "senderId": "550e8400-e29b-41d4-a716-446655440001",
    "messageType": "INDIVIDUAL",
    "title": "Work Assignment",
    "content": "You have been assigned to site A",
    "targetUserId": "550e8400-e29b-41d4-a716-446655440003",
    "requiresConfirmation": true
  }'
```

**Mark Message as Read**
```bash
curl -X PUT "http://localhost:8087/api/notifications/messages/{id}/read?userId=550e8400-e29b-41d4-a716-446655440003" \
  -H "Content-Type: application/json"
```

**Confirm Message**
```bash
curl -X PUT "http://localhost:8087/api/notifications/messages/{id}/confirm?userId=550e8400-e29b-41d4-a716-446655440003" \
  -H "Content-Type: application/json"
```

---

### Location Service Examples

**REST Location Update**
```bash
curl -X POST http://localhost:8088/api/location/update \
  -H "Content-Type: application/json" \
  -d '{
    "workerId": "550e8400-e29b-41d4-a716-446655440003",
    "equipmentId": "550e8400-e29b-41d4-a716-446655440004",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "accuracy": 5.2,
    "workerName": "John Doe",
    "equipmentName": "Excavator A",
    "vehicleNumber": "ABC-123",
    "siteName": "Site A"
  }'
```

**Get Site Current Locations**
```bash
curl http://localhost:8088/api/location/current/550e8400-e29b-41d4-a716-446655440005 \
  -H "Content-Type: application/json"
```

**Get Worker Location History**
```bash
curl "http://localhost:8088/api/location/worker/550e8400-e29b-41d4-a716-446655440003?page=0&size=20" \
  -H "Content-Type: application/json"
```

**Get Current Location of Worker**
```bash
curl http://localhost:8088/api/location/worker/550e8400-e29b-41d4-a716-446655440003/current \
  -H "Content-Type: application/json"
```

---

### WebSocket Location Updates

**Connect to WebSocket**
```javascript
const stompClient = new StompJs.Client({
    brokerURL: 'ws://localhost:8088/ws/location'
});

stompClient.onConnect = function(frame) {
    // Subscribe to site location updates
    stompClient.subscribe('/topic/site/550e8400-e29b-41d4-a716-446655440005', function(message) {
        console.log('Location update:', JSON.parse(message.body));
    });
    
    // Send location update
    stompClient.send('/app/location/update', {}, JSON.stringify({
        workerId: '550e8400-e29b-41d4-a716-446655440003',
        equipmentId: '550e8400-e29b-41d4-a716-446655440004',
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 5.2,
        workerName: 'John Doe',
        equipmentName: 'Excavator A',
        vehicleNumber: 'ABC-123',
        siteName: 'Site A'
    }));
};

stompClient.activate();
```

---

## Configuration

### Settlement Service (application.yml)
```yaml
spring:
  datasource:
    url: jdbc:postgresql://postgres:5432/skep_settlement
    username: postgres
    password: postgres
  mail:
    host: smtp.gmail.com
    port: 587
    username: your-email@gmail.com
    password: your-app-password
```

### Notification Service (application.yml)
```yaml
spring:
  datasource:
    url: jdbc:postgresql://postgres:5432/skep_notification
    username: postgres
    password: postgres
  mail:
    host: smtp.gmail.com
    port: 587

firebase:
  credentials-path: /path/to/firebase-adminsdk.json
```

### Location Service (application.yml)
```yaml
spring:
  datasource:
    url: jdbc:postgresql://postgres:5432/skep_location
    username: postgres
    password: postgres
```

---

## Development

### Project Structure
```
services/
├── settlement-service/
│   ├── build.gradle
│   ├── Dockerfile
│   └── src/main/
│       ├── java/com/skep/settlement/
│       └── resources/
├── notification-service/
│   ├── build.gradle
│   ├── Dockerfile
│   └── src/main/
│       ├── java/com/skep/notification/
│       └── resources/
├── location-service/
│   ├── build.gradle
│   ├── Dockerfile
│   └── src/main/
│       ├── java/com/skep/location/
│       └── resources/
├── docker-compose.yml
└── init-databases.sql
```

### Adding New Endpoints

1. **Create DTO in `dto/` package**
2. **Create Entity in `entity/` package**
3. **Create Repository in `repository/` package**
4. **Create Service in `service/` package**
5. **Add Controller methods in `controller/` package**
6. **Add database migration in `resources/db/migration/`**

Example:
```bash
# Settlement Service - Add new feature
mkdir -p settlement-service/src/main/java/com/skep/settlement/feature
```

---

## Troubleshooting

### Database Connection Error
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Verify connection
psql -h localhost -U postgres -d skep_settlement -c "SELECT 1"
```

### Port Already in Use
```bash
# Kill process using port
lsof -i :8086
kill -9 <PID>

# Or use different port in application.yml
server:
  port: 8090
```

### Firebase Credentials Not Found
```bash
# Notification Service needs firebase-adminsdk.json
# Place it at: /config/firebase-adminsdk.json
# Or set FIREBASE_CREDENTIALS_PATH environment variable
```

### WebSocket Connection Issues
```bash
# Enable CORS for production
# Update WebSocketConfig.java
.setAllowedOrigins("https://yourdomain.com")
```

---

## Performance Tuning

### Database
```properties
spring.jpa.properties.hibernate.jdbc.batch_size=20
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
```

### Connection Pool
```properties
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
```

### Logging
```properties
logging.level.org.springframework=INFO
logging.level.org.hibernate=WARN
logging.level.com.skep=DEBUG
```

---

## Monitoring & Logging

### View Docker Logs
```bash
docker-compose logs settlement-service
docker-compose logs notification-service
docker-compose logs location-service
docker-compose logs postgres
```

### Health Check
```bash
curl http://localhost:8086/actuator/health
curl http://localhost:8087/actuator/health
curl http://localhost:8088/actuator/health
```

---

## Deployment

### Build Docker Images
```bash
docker build -t skep/settlement:1.0 ./settlement-service
docker build -t skep/notification:1.0 ./notification-service
docker build -t skep/location:1.0 ./location-service
```

### Push to Registry
```bash
docker tag skep/settlement:1.0 registry.example.com/skep/settlement:1.0
docker push registry.example.com/skep/settlement:1.0
```

### Kubernetes Deployment
Create `k8s/deployment.yaml` with service manifests for each microservice.

---

## Support & Documentation

- **Settlement Service:** See `STRUCTURE.md` - Settlement Service section
- **Notification Service:** See `STRUCTURE.md` - Notification Service section
- **Location Service:** See `STRUCTURE.md` - Location Service section

For complete technical details, see `STRUCTURE.md`

---

Generated: March 19, 2026
All services ready for production deployment.

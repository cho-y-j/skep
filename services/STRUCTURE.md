# SKEP Microservices Architecture

## Project Overview
Three complete Spring Boot 3.2.x microservices for SKEP platform running on Java 21.

## Services

### 1. Settlement Service (Port 8086)
Location: `/settlement-service/`

**Responsibilities:**
- Automatic invoice generation based on work deployment plan
- Calculate settlement amounts by multiplying rates × hours
- Support daily, overtime, early morning, night, and overnight rates
- Calculate supply amount + tax (10%)
- PDF generation and email distribution

**Key Features:**
- PostgreSQL with Flyway migrations
- JPA for data persistence
- PDF generation with iText
- Email sending via JavaMail
- RESTful API with filtering and pagination

**Database Tables:**
- `settlements` - Main settlement records
- `settlement_daily_details` - Daily work breakdown

**Controllers:**
- `/api/settlement/generate` - Create new settlement
- `/api/settlement` - List settlements with filters
- `/api/settlement/{id}` - Get settlement details
- `/api/settlement/{id}/send` - Email distribution
- `/api/settlement/{id}/mark-paid` - Payment status update
- `/api/settlement/statistics/supplier/{supplierId}` - Supplier stats
- `/api/settlement/statistics/bp/{bpId}` - BP company stats

---

### 2. Notification Service (Port 8087)
Location: `/notification-service/`

**Responsibilities:**
- FCM push notifications via Firebase Admin SDK
- Email notifications via AWS SES/JavaMail
- Message system (1:1, group, broadcast)
- Read confirmation tracking

**Key Features:**
- Firebase Cloud Messaging integration
- AWS SES support
- JSONB data storage for flexible metadata
- Message read/confirmation status tracking
- Role-based and individual targeting

**Database Tables:**
- `fcm_tokens` - FCM device tokens per user
- `notifications` - Notification records
- `messages` - Message broadcasts
- `message_reads` - Message delivery/read tracking

**Controllers:**
- `/api/notifications/send` - Send notification
- `/api/notifications/my` - Get my notifications
- `/api/notifications/{id}/read` - Mark as read
- `/api/notifications/messages` - Send message
- `/api/notifications/messages/my` - Get my messages
- `/api/notifications/messages/{id}/read` - Mark message read
- `/api/notifications/messages/{id}/confirm` - Confirm message
- `/api/notifications/messages/{id}/read-status` - Delivery stats
- `/api/notifications/messages/{id}/resend-unread` - Resend to unread
- `/api/notifications/fcm/register` - Register FCM token
- `/api/notifications/unread-count` - Get unread count

---

### 3. Location Service (Port 8088)
Location: `/location-service/`

**Responsibilities:**
- Real-time GPS location tracking via WebSocket
- Display worker location = equipment location
- Store location history
- Site-wide location broadcasting

**Key Features:**
- STOMP WebSocket support
- Real-time location updates
- Location history with pagination
- Current location caching
- Site-based location grouping

**Database Tables:**
- `location_records` - Historical GPS records
- `current_locations` - Cache of current positions

**WebSocket Endpoints:**
- `/ws/location` - Main WebSocket endpoint
- `/app/location/update` - Submit location update
- `/topic/site/{siteId}` - Broadcast to site

**REST Endpoints:**
- `/api/location/update` - REST location update
- `/api/location/current/{siteId}` - Get all current positions
- `/api/location/worker/{workerId}` - Get location history
- `/api/location/worker/{workerId}/current` - Get current position

---

## Technology Stack

### Common
- **Java:** 21
- **Spring Boot:** 3.2.0
- **Build Tool:** Gradle
- **Database:** PostgreSQL 16
- **Migrations:** Flyway
- **ORM:** Spring Data JPA, Hibernate
- **Utils:** Lombok

### Settlement Service
- **PDF:** iText 5.5.13
- **Email:** Spring Mail, JavaMail

### Notification Service
- **Push:** Firebase Admin SDK 9.2.0
- **Email:** AWS SES, Spring Mail
- **Data Format:** JSONB in PostgreSQL

### Location Service
- **WebSocket:** Spring WebSocket, STOMP, SockJS

---

## Database Configuration

All services require PostgreSQL 16 running locally or via Docker.

**Connection Details:**
- Host: `localhost:5432` (or `postgres` in Docker)
- Username: `postgres`
- Password: `postgres`
- Databases:
  - `skep_settlement`
  - `skep_notification`
  - `skep_location`

**Automatic Setup via Docker Compose:**
```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services
docker-compose up -d
```

---

## Project Structure

```
services/
├── settlement-service/
│   ├── build.gradle
│   ├── Dockerfile
│   ├── .gitignore
│   ├── src/main/
│   │   ├── java/com/skep/settlement/
│   │   │   ├── SettlementServiceApplication.java
│   │   │   ├── controller/SettlementController.java
│   │   │   ├── service/
│   │   │   │   ├── SettlementService.java
│   │   │   │   ├── SettlementPdfService.java
│   │   │   │   └── SettlementEmailService.java
│   │   │   ├── entity/
│   │   │   │   ├── Settlement.java
│   │   │   │   └── SettlementDailyDetail.java
│   │   │   ├── repository/
│   │   │   │   ├── SettlementRepository.java
│   │   │   │   └── SettlementDailyDetailRepository.java
│   │   │   └── dto/
│   │   │       ├── SettlementRequest.java
│   │   │       ├── SettlementResponse.java
│   │   │       ├── SettlementDailyDetailResponse.java
│   │   │       └── SettlementStatisticsResponse.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   │           └── V1__Create_settlements_tables.sql
│
├── notification-service/
│   ├── build.gradle
│   ├── Dockerfile
│   ├── .gitignore
│   ├── src/main/
│   │   ├── java/com/skep/notification/
│   │   │   ├── NotificationServiceApplication.java
│   │   │   ├── controller/NotificationController.java
│   │   │   ├── service/
│   │   │   │   ├── NotificationService.java
│   │   │   │   ├── MessageService.java
│   │   │   │   └── FcmService.java
│   │   │   ├── entity/
│   │   │   │   ├── FcmToken.java
│   │   │   │   ├── Notification.java
│   │   │   │   ├── Message.java
│   │   │   │   └── MessageRead.java
│   │   │   ├── repository/
│   │   │   │   ├── FcmTokenRepository.java
│   │   │   │   ├── NotificationRepository.java
│   │   │   │   ├── MessageRepository.java
│   │   │   │   └── MessageReadRepository.java
│   │   │   └── dto/
│   │   │       ├── NotificationRequest.java
│   │   │       ├── NotificationResponse.java
│   │   │       ├── MessageRequest.java
│   │   │       ├── MessageResponse.java
│   │   │       ├── FcmTokenRequest.java
│   │   │       └── MessageReadStatusResponse.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   │           └── V1__Create_notification_tables.sql
│
├── location-service/
│   ├── build.gradle
│   ├── Dockerfile
│   ├── .gitignore
│   ├── src/main/
│   │   ├── java/com/skep/location/
│   │   │   ├── LocationServiceApplication.java
│   │   │   ├── config/WebSocketConfig.java
│   │   │   ├── controller/LocationController.java
│   │   │   ├── websocket/LocationWebSocketHandler.java
│   │   │   ├── service/LocationService.java
│   │   │   ├── entity/
│   │   │   │   ├── LocationRecord.java
│   │   │   │   └── CurrentLocation.java
│   │   │   ├── repository/
│   │   │   │   ├── LocationRecordRepository.java
│   │   │   │   └── CurrentLocationRepository.java
│   │   │   └── dto/
│   │   │       ├── LocationRequest.java
│   │   │       ├── LocationResponse.java
│   │   │       └── CurrentLocationResponse.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   │           └── V1__Create_location_tables.sql
│
├── docker-compose.yml
├── init-databases.sql
└── STRUCTURE.md
```

---

## Build & Run

### Local Development
```bash
# Settlement Service
cd settlement-service
gradle build
gradle bootRun

# Notification Service
cd notification-service
gradle build
gradle bootRun

# Location Service
cd location-service
gradle build
gradle bootRun
```

### Docker Build
```bash
cd settlement-service && gradle build && docker build -t skep/settlement:latest .
cd ../notification-service && gradle build && docker build -t skep/notification:latest .
cd ../location-service && gradle build && docker build -t skep/location:latest .
```

### Docker Compose
```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services
docker-compose up -d
```

---

## Key Design Patterns

### 1. Settlement Service
- **Service Layer Pattern:** Business logic separated from controllers
- **Repository Pattern:** Data access abstraction
- **DTO Pattern:** Request/Response data transfer objects
- **Transaction Management:** @Transactional ensures data consistency

### 2. Notification Service
- **Async Communication:** FCM for push notifications
- **Message Queue Pattern:** Message storage for future delivery
- **Status Tracking:** Read/confirmation status persistence
- **Role-based Distribution:** Flexible recipient targeting

### 3. Location Service
- **Real-time Updates:** WebSocket for instant location broadcasting
- **Event Streaming:** STOMP messaging for scalability
- **Caching Layer:** CurrentLocation table for quick access
- **History Preservation:** LocationRecord for audit trail

---

## Configuration Notes

### Settlement Service
- Email configuration: Update `spring.mail` properties in `application.yml`
- PDF generation is synchronous; consider async for high volume

### Notification Service
- Firebase credentials: Place `firebase-adminsdk.json` in `/config/` directory
- AWS SES: Configure credentials in environment variables
- Database: JSONB columns support flexible metadata storage

### Location Service
- WebSocket CORS: Configure `setAllowedOrigins` for production
- Real-time performance: Consider adding Redis caching for high-frequency updates
- SockJS fallback: Enabled for browser compatibility

---

## Production Considerations

1. **Security:**
   - Add Spring Security with JWT/OAuth2
   - Implement rate limiting
   - Validate all inputs

2. **Performance:**
   - Add Redis for caching
   - Implement database connection pooling (HikariCP)
   - Use async/reactive patterns where applicable

3. **Observability:**
   - Add Prometheus metrics
   - Implement ELK stack for logging
   - Distributed tracing with Sleuth/Zipkin

4. **Resilience:**
   - Add circuit breakers (Resilience4j)
   - Implement retry logic
   - Add health checks

5. **Infrastructure:**
   - Use Kubernetes for orchestration
   - Implement GitOps with ArgoCD
   - Setup monitoring and alerting


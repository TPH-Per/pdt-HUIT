# pdt-HUIT · Complete Production Refactoring Plan v4.1 — FINAL
**Agent-Ready · All 30+ Gaps Resolved · Source-Verified · Layer 1+2+3 Reviewed**

---

## Confirmed Ground Truth (from actual source reads)

| Fact | Confirmed Value |
|---|---|
| Current package | `com.example.demo` |
| Flyway location | `classpath:db/migration_new` |
| Max Flyway version | **V5** → new migrations start at V6 |
| `ddl-auto` | `none` ✅ already set |
| `open-in-view` | `false` ✅ already set |
| HikariCP | Already configured (pool=20, idle=5) ✅ |
| JWT secret | **Hardcoded** in `application.properties` → must move to env |
| Actuator | Exposes `health,info,metrics,logfile` → must restrict |
| Flutter HTTP client | `http` package, `_baseUrl = http://127.0.0.1:8081/api/student` |
| Flutter state | `provider` → migrate to BLoC |
| Flutter nav | `go_router: ^13.2.0` already installed ✅ |
| Flutter `shimmer`, `dio`, `cached_network_image` | Already in `pubspec.yaml` ✅ |
| `/api/student/**` | `permitAll()` in SecurityConfig → **critical security gap** |
| `student.student_id` PK | **`VARCHAR(10)`** — all SQL must use VARCHAR FK |
| `queue_tickets` table | **Does NOT exist** → create in V6 |
| `notification` table | **Does NOT exist** → create in V7 |
| `refresh_token` table | **Does NOT exist** → create in V8 |
| `student_device_token` table | **Does NOT exist** → create in V9 |
| `appointment.status` | **INTEGER** 0/1/2 |
| `report`, `reply`, `student_feedback` | All exist in V1 schema |
| `vw_daily_stats` VIEW | Verify: `SELECT * FROM vw_daily_stats LIMIT 1;` — create V11 if missing |
| Vue Vite proxy | Not configured → must add |
| Vue `.env` | Not present → must create |
| `stomp_dart_client` | Must use `^2.0.0` — `^1.2.0` is outdated |
| JWT in WebSocket | Neither Vue nor Flutter sends JWT in STOMP CONNECT — both broken without fix |
| Flutter JWT storage | Currently uses Hive (unencrypted) → must use `flutter_secure_storage` |

---

## Standards This Plan Targets

| Category | Standard |
|---|---|
| Backend test coverage | ≥ 80% service layer, ≥ 60% overall |
| API response time | P95 < 200ms cached, < 500ms complex queries |
| Race condition | Zero duplicate queue calls under 20-thread concurrent load |
| SQL | No `SELECT *`, all list queries paginated, all FK columns indexed |
| Controller size | Max 50 lines per method, zero business logic |
| WebSocket | JWT-authenticated STOMP, reconnect ≤ 3s, no missed events |
| Vue bundle | < 500KB gzipped initial chunk (code-splitting per route) |
| Flutter | 60fps on Pixel 6, cold start < 2s |
| Security | JWT + refresh token rotation, all endpoints role-guarded, rate-limited |
| Error handling | Zero unhandled 500s reaching client |
| Caching | Redis backend (30min categories, 5s queue-stats), frontend stale-while-revalidate, mobile cache-first BLoC |

---

## PHASE 0 — Branch, Environment & Version Detection

### 0.1 Create Branch
```bash
git checkout -b refactor/clean-architecture
git push -u origin refactor/clean-architecture
```

### 0.2 Detect Flyway State
```bash
ls backend/src/main/resources/db/migration_new/ | sort -V
# Confirmed output: V1 through V5
# BASE_V=5 → all new migrations start at V6
```

### 0.3 Verify Folder Casing (Linux is case-sensitive)
```bash
ls -la | grep -E "Admin|flutter|backend|scripts|config"
# Must show exact: AdminStaff/  flutter_huit_student/  backend/  config/
# NEVER cd adminstaff — fails silently on case-insensitive dev machines
```

### 0.4 Audit config/ Folder
```bash
ls -la config/
cat config/*.conf  2>/dev/null || echo "No .conf files"
cat config/*.yml   2>/dev/null || echo "No .yml files"
# If nginx config present, add WebSocket upstream block:
# location /ws {
#   proxy_pass http://backend:8081;
#   proxy_http_version 1.1;
#   proxy_set_header Upgrade $http_upgrade;
#   proxy_set_header Connection "upgrade";
# }
```

### 0.5 Verify vw_daily_stats VIEW
```bash
psql -U $DB_USER -d $DB_NAME -c "SELECT * FROM vw_daily_stats LIMIT 1;"
# SUCCESS → view exists in V1-V5, skip V11 migration
# ERROR: relation does not exist → create V11 (see 1.8)
```

### 0.6 docker-compose.prod.yml
```yaml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

  backend:
    build: ./backend
    ports: ["8081:8081"]
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/${DB_NAME}
      - SPRING_DATASOURCE_USERNAME=${DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
      - SPRING_REDIS_HOST=redis
      - SPRING_REDIS_PORT=6379
      - JWT_SECRET=${JWT_SECRET}
      - SWAGGER_ENABLED=false
      - GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-service-account.json
    volumes:
      - ./firebase-service-account.json:/app/firebase-service-account.json:ro

  frontend:
    build: ./AdminStaff
    ports: ["3000:80"]
    depends_on: [backend]

volumes:
  pgdata:
```

**Create `.env.example` at repo root:**
```bash
DB_NAME=pdt_huit_db
DB_USER=myuser
DB_PASSWORD=changeme
JWT_SECRET=replace-with-min-256-bit-secret-at-least-32-chars!!
VITE_API_BASE_URL=http://localhost:8081/api
VITE_WS_URL=http://localhost:8081
```

### 0.7 Remove Hardcoded Secrets from application.properties
```properties
# application.properties
jwt.secret=${JWT_SECRET:dev-insecure-secret-replace-before-prod!!1234}
jwt.expiration=3600000
jwt.refresh-expiration=604800000

management.endpoints.web.exposure.include=health
management.endpoint.health.show-details=when-authorized
management.endpoints.web.base-path=/internal/actuator
```

**Also add `application-prod.properties`:**
```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.redis.host=${REDIS_HOST:redis}
spring.redis.port=${REDIS_PORT:6379}
spring.jpa.show-sql=false
logging.level.root=WARN
logging.level.com.huit.pdt=INFO
springdoc.swagger-ui.enabled=false
management.endpoints.web.exposure.include=health
management.endpoints.web.base-path=/internal/actuator
```

### ✅ Phase 0 Gate
```bash
cd backend && ./mvnw spring-boot:run &
sleep 15
curl -s http://localhost:8081/internal/actuator/health | jq '.status'
# Expected: "UP"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/metrics
# Expected: 404 — old actuator path sealed
```

---

## PHASE 1 — Backend Refactor

### 1.0 Package Rename: `com.example.demo` → `com.huit.pdt`

> **Do this first before any other changes. All subsequent files go into the new package.**

```bash
# Step 1: pom.xml
sed -i 's|<groupId>com.example</groupId>|<groupId>com.huit</groupId>|' backend/pom.xml
sed -i 's|<artifactId>demo</artifactId>|<artifactId>pdt-huit</artifactId>|' backend/pom.xml

# Step 2: Rename all package/import declarations
find backend/src -name "*.java" -exec sed -i \
  's/package com\.example\.demo/package com.huit.pdt/g;
   s/import com\.example\.demo/import com.huit.pdt/g' {} +

# Step 3: Move source tree
mkdir -p backend/src/main/java/com/huit/pdt
cp -r backend/src/main/java/com/example/demo/* \
      backend/src/main/java/com/huit/pdt/
rm -rf backend/src/main/java/com/example/

mkdir -p backend/src/test/java/com/huit/pdt
cp -r backend/src/test/java/com/example/demo/* \
      backend/src/test/java/com/huit/pdt/ 2>/dev/null || true
rm -rf backend/src/test/java/com/example/

# Step 4: Fix logging config
sed -i 's/com.example.demo/com.huit.pdt/g' \
    backend/src/main/resources/application.properties

# Step 5: Verify compilation
cd backend && ./mvnw compile -q
# Must exit 0
```

### 1.1 pom.xml Dependencies

> **NOTE:** After removing `spring-boot-starter-data-jpa`, `@Transactional` continues working via `DataSourceTransactionManager` — auto-configured by `spring-boot-starter-jdbc`. No manual `TransactionManager` bean needed. Remove JPA dependency LAST, after all JDBC repos are verified.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.5.0</version>
</dependency>
<dependency>
    <groupId>com.github.vladimir-bukhtoyarov</groupId>
    <artifactId>bucket4j-core</artifactId>
    <version>8.10.1</version>
</dependency>
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.3.0</version>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
```

### 1.2 Clean Package Architecture

```
com.huit.pdt/
  domain/
    auth/
      service/AuthService.java
      service/impl/AuthServiceImpl.java
      service/StudentUserDetailsService.java       ← split from single service (GAP-D)
      service/RegistrarUserDetailsService.java     ← split from single service (GAP-D)
      dto/LoginRequest.java, LoginResponse.java, RefreshTokenRequest.java
    student/
      repository/StudentRepository.java, impl/StudentRepositoryImpl.java
      service/StudentService.java, impl/StudentServiceImpl.java
      dto/StudentDTO.java, UpdateProfileRequest.java
    queue/
      repository/QueueRepository.java, impl/QueueRepositoryImpl.java
      service/QueueService.java, impl/QueueServiceImpl.java
      dto/QueueTicketDTO.java, QueueStatsDTO.java
    request/
      repository/RequestRepository.java, impl/RequestRepositoryImpl.java
      service/RequestService.java, impl/RequestServiceImpl.java
      dto/RequestDTO.java, CreateRequestRequest.java, RequestHistoryDTO.java
    appointment/
      repository/AppointmentRepository.java, impl/AppointmentRepositoryImpl.java
      service/AppointmentService.java, impl/AppointmentServiceImpl.java
      dto/AppointmentDTO.java, CreateAppointmentRequest.java, AvailableSlotDTO.java
    feedback/
      repository/FeedbackRepository.java, impl/FeedbackRepositoryImpl.java  ← student_feedback
      repository/ReplyRepository.java, impl/ReplyRepositoryImpl.java         ← reply table (restored)
      service/FeedbackService.java, impl/FeedbackServiceImpl.java
      dto/FeedbackDTO.java, ReplyDTO.java, SubmitFeedbackRequest.java
    report/
      repository/ReportRepository.java, impl/ReportRepositoryImpl.java       ← report table (restored)
      service/ReportService.java, impl/ReportServiceImpl.java
      dto/DashboardReportDTO.java, ServiceUsageReportDTO.java
      dto/RegistrarPerformanceDTO.java, DailyStatsDTO.java
    notification/
      repository/NotificationRepository.java, impl/NotificationRepositoryImpl.java
      service/NotificationService.java, impl/NotificationServiceImpl.java
      dto/NotificationDTO.java
    servicedesk/
      repository/ServiceDeskRepository.java
      service/ServiceDeskService.java, impl/ServiceDeskServiceImpl.java
      dto/ServiceDeskDTO.java, ServiceDeskStatusDTO.java
    registrar/
      repository/RegistrarRepository.java
      service/RegistrarService.java, impl/RegistrarServiceImpl.java
    academicservice/
      repository/AcademicServiceRepository.java
      service/AcademicServiceService.java, impl/AcademicServiceServiceImpl.java
  infrastructure/
    persistence/rowmapper/        ← All RowMapper implementations
    cache/CacheService.java
    websocket/
      WebSocketConfig.java
      WebSocketSecurityConfig.java
    security/
      JwtService.java
      JwtAuthenticationFilter.java
      RefreshTokenService.java
    ratelimit/RateLimitFilter.java
  web/
    controller/
      AuthController.java
      StudentAuthController.java
      StudentController.java          ← was 33KB god class, now ≤100 lines
      RegistrarQueueController.java   ← was 22KB god class, now ≤100 lines
      RegistrarRequestController.java
      RegistrarFeedbackController.java
      RegistrarDashboardController.java
      RegistrarAppointmentController.java
      ServiceDeskController.java
      PublicController.java
    exception/
      GlobalExceptionHandler.java
      ResourceNotFoundException.java
      QueueConflictException.java
      AppointmentConflictException.java
      BusinessHoursException.java
    dto/ApiResponse.java
  config/
    WebSocketConfig.java
    RedisConfig.java
    SecurityConfig.java
    SwaggerConfig.java
    FirebaseConfig.java
```

### 1.3 Dual-Auth UserDetailsService (GAP-D)

```java
// domain/auth/service/StudentUserDetailsService.java
@Service("studentUserDetailsService")
@RequiredArgsConstructor
public class StudentUserDetailsService implements UserDetailsService {
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public UserDetails loadUserByUsername(String studentId) {
        String sql = """
            SELECT student_id, password_hash, is_active
            FROM student WHERE student_id = :id
            """;
        return jdbc.queryForObject(sql, Map.of("id", studentId), (rs, n) ->
            User.builder()
                .username(rs.getString("student_id"))
                .password(rs.getString("password_hash"))
                .disabled(!rs.getBoolean("is_active"))
                .roles("STUDENT")
                .build());
    }
}

// domain/auth/service/RegistrarUserDetailsService.java
@Service("registrarUserDetailsService")
@RequiredArgsConstructor
public class RegistrarUserDetailsService implements UserDetailsService {
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public UserDetails loadUserByUsername(String registrarCode) {
        String sql = """
            SELECT reg.registrar_code, reg.password_hash, reg.is_active,
                   r.role_name
            FROM registrar reg
            JOIN role r ON r.id = reg.role_id
            WHERE reg.registrar_code = :code
            """;
        return jdbc.queryForObject(sql, Map.of("code", registrarCode), (rs, n) ->
            User.builder()
                .username(rs.getString("registrar_code"))
                .password(rs.getString("password_hash"))
                .disabled(!rs.getBoolean("is_active"))
                .roles(rs.getString("role_name"))   // "Admin" or "Registrar"
                .build());
    }
}
```

### 1.4 SecurityConfig Complete Rewrite (GAP-E + critical /api/student/** fix)

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    @Bean @Qualifier("studentAuthProvider")
    public AuthenticationProvider studentAuthProvider(
            @Qualifier("studentUserDetailsService") UserDetailsService svc,
            PasswordEncoder encoder) {
        DaoAuthenticationProvider p = new DaoAuthenticationProvider(svc);
        p.setPasswordEncoder(encoder);
        return p;
    }

    @Bean @Qualifier("registrarAuthProvider")
    public AuthenticationProvider registrarAuthProvider(
            @Qualifier("registrarUserDetailsService") UserDetailsService svc,
            PasswordEncoder encoder) {
        DaoAuthenticationProvider p = new DaoAuthenticationProvider(svc);
        p.setPasswordEncoder(encoder);
        return p;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .cors(cors -> cors.configurationSource(corsConfigSource()))
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(sm ->
                sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Public — no auth required
                .requestMatchers(HttpMethod.POST,
                    "/api/auth/login",
                    "/api/student/auth/login").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/auth/refresh").permitAll()
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/internal/actuator/health").permitAll()
                .requestMatchers("/internal/actuator/**").hasRole("Admin")
                .requestMatchers("/swagger-ui/**", "/api-docs/**").permitAll()
                .requestMatchers("/ws/**").permitAll()   // WS auth done in STOMP layer
                // Role-guarded routes
                .requestMatchers("/api/student/**").hasRole("STUDENT")   // ← WAS permitAll!
                .requestMatchers("/api/registrar/**").hasAnyRole("Admin", "Registrar")
                .requestMatchers("/api/admin/**").hasRole("Admin")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }

    @Bean
    public CorsConfigurationSource corsConfigSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

### 1.5 WebSocket Backend Security with JWT Auth (GAP-009)

```java
@Configuration
public class WebSocketSecurityConfig
        extends AbstractSecurityWebSocketMessageBrokerConfigurer {

    @Override
    protected void configureInbound(MessageSecurityMetadataSourceRegistry messages) {
        messages
            .simpConnectDestMatchers("/**").authenticated()
            .simpSubscribeDestMatching("/user/**").authenticated()
            .simpSubscribeDestMatching("/topic/queue/**")
                .hasAnyRole("Admin", "Registrar")
            .anyMessage().authenticated();
    }

    // Extract JWT from STOMP CONNECT frame Authorization header
    @Bean
    public ChannelInterceptor webSocketJwtInterceptor(JwtService jwtService) {
        return new ChannelInterceptorAdapter() {
            @Override
            public Message<?> preSend(Message<?> msg, MessageChannel channel) {
                StompHeaderAccessor accessor =
                    MessageHeaderAccessor.getAccessor(msg, StompHeaderAccessor.class);
                if (StompCommand.CONNECT.equals(accessor.getCommand())) {
                    String auth = accessor.getFirstNativeHeader("Authorization");
                    if (auth != null && auth.startsWith("Bearer ")) {
                        Authentication authentication =
                            jwtService.getAuthentication(auth.substring(7));
                        accessor.setUser(authentication);
                    }
                }
                return msg;
            }
        };
    }

    @Override
    protected boolean sameOriginDisabled() { return true; }
}
```

### 1.6 RedisConfig (was missing entirely)

```java
@Configuration
@EnableCaching
public class RedisConfig {

    @Bean
    public RedisCacheConfiguration defaultCacheConfig() {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .disableCachingNullValues()
            .serializeValuesWith(
                RedisSerializationContext.SerializationPair.fromSerializer(
                    new GenericJackson2JsonRedisSerializer()));
    }

    @Bean
    public RedisCacheManagerBuilderCustomizer redisCacheManagerCustomizer() {
        return builder -> builder
            .withCacheConfiguration("service-categories",
                RedisCacheConfiguration.defaultCacheConfig()
                    .entryTtl(Duration.ofMinutes(30)))
            .withCacheConfiguration("academic-services",
                RedisCacheConfiguration.defaultCacheConfig()
                    .entryTtl(Duration.ofMinutes(30)))
            .withCacheConfiguration("queue-stats",
                RedisCacheConfiguration.defaultCacheConfig()
                    .entryTtl(Duration.ofSeconds(5)))
            .withCacheConfiguration("service-desks",
                RedisCacheConfiguration.defaultCacheConfig()
                    .entryTtl(Duration.ofMinutes(1)))
            .withCacheConfiguration("student-profile",
                RedisCacheConfiguration.defaultCacheConfig()
                    .entryTtl(Duration.ofMinutes(15)));
    }
}

// Cache usage on service methods:
// @Cacheable(value = "service-categories", key = "'all'") on getAllCategories()
// @CacheEvict(value = "service-categories", allEntries = true) on createCategory()
// @Cacheable(value = "queue-stats", key = "#deskId") on getQueueStats()
// @CacheEvict(value = "queue-stats", key = "#deskId") on updateTicketStatus()
```

### 1.7 FirebaseConfig

```java
@Configuration
public class FirebaseConfig {

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        if (FirebaseApp.getApps().isEmpty()) {
            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .build();
            return FirebaseApp.initializeApp(options);
        }
        return FirebaseApp.getInstance();
    }

    @Bean
    public FirebaseMessaging firebaseMessaging(FirebaseApp app) {
        return FirebaseMessaging.getInstance(app);
    }
}
// Env: GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-service-account.json
```

### 1.8 Flyway Migrations V6–V11

**V6 — queue_tickets (DOES NOT EXIST — must create)**
```sql
-- V6__create_queue_tickets.sql
-- student_id VARCHAR(10) matches student.student_id PK confirmed in V1
CREATE TABLE queue_tickets (
    id             BIGSERIAL PRIMARY KEY,
    ticket_number  INTEGER NOT NULL,
    ticket_prefix  VARCHAR(5) DEFAULT 'A',
    student_id     VARCHAR(10) REFERENCES student(student_id) ON DELETE SET NULL,
    desk_id        INTEGER NOT NULL REFERENCES service_desk(id),
    registrar_id   INTEGER REFERENCES registrar(id),
    request_id     INTEGER REFERENCES request(id) ON DELETE CASCADE,
    status         VARCHAR(20) NOT NULL DEFAULT 'WAITING',
    CONSTRAINT chk_queue_status
        CHECK (status IN ('WAITING','CALLING','SERVING','COMPLETED','SKIPPED','CANCELLED')),
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    called_at      TIMESTAMPTZ,
    served_at      TIMESTAMPTZ,
    completed_at   TIMESTAMPTZ,
    notes          TEXT
);
CREATE UNIQUE INDEX uidx_ticket_number_desk_day
    ON queue_tickets(desk_id, ticket_number, DATE(created_at));
CREATE INDEX idx_queue_tickets_desk_status
    ON queue_tickets(desk_id, status, created_at ASC);
CREATE INDEX idx_queue_tickets_student
    ON queue_tickets(student_id, created_at DESC);

CREATE OR REPLACE FUNCTION reset_daily_queue() RETURNS void AS $$
BEGIN
    UPDATE queue_tickets
    SET status = 'CANCELLED', notes = 'Auto-cancelled: end of business day'
    WHERE status IN ('WAITING','CALLING') AND DATE(created_at) < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;
```

**V7 — notification**
```sql
CREATE TABLE notification (
    id         BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
    type       VARCHAR(50)  NOT NULL,
    -- QUEUE_CALLED | REQUEST_UPDATED | APPOINTMENT_REMINDER | FEEDBACK_REPLIED
    title      VARCHAR(255) NOT NULL,
    body       TEXT,
    is_read    BOOLEAN DEFAULT FALSE,
    ref_id     BIGINT,
    ref_type   VARCHAR(30),  -- 'REQUEST' | 'APPOINTMENT' | 'QUEUE'
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notification_student_unread
    ON notification(student_id, is_read, created_at DESC);
```

**V8 — refresh_token**
```sql
CREATE TABLE refresh_token (
    id         BIGSERIAL PRIMARY KEY,
    token      VARCHAR(512) UNIQUE NOT NULL,
    user_id    VARCHAR(50)  NOT NULL,  -- handles both MSSV and registrar_code
    user_type  VARCHAR(20)  NOT NULL,  -- 'STUDENT' | 'REGISTRAR'
    expires_at TIMESTAMPTZ  NOT NULL,
    revoked    BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_refresh_token_active ON refresh_token(token) WHERE NOT revoked;
CREATE INDEX idx_refresh_token_user   ON refresh_token(user_id, user_type) WHERE NOT revoked;
```

**V9 — student_device_token**
```sql
CREATE TABLE student_device_token (
    id         BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
    fcm_token  VARCHAR(512) NOT NULL,
    platform   VARCHAR(10) DEFAULT 'android',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_student_fcm UNIQUE (student_id, fcm_token)
);
```

**V10 — performance indexes**
```sql
CREATE INDEX CONCURRENTLY idx_request_student_phase
    ON request(student_id, current_phase, created_at DESC);
CREATE INDEX CONCURRENTLY idx_request_history_request
    ON request_history(request_id, created_at DESC);
CREATE INDEX CONCURRENTLY idx_appointment_registrar_date
    ON appointment(registrar_id, appointment_date, status);
CREATE INDEX CONCURRENTLY idx_student_feedback_student
    ON student_feedback(student_id, status, created_at DESC);
CREATE INDEX CONCURRENTLY idx_report_student
    ON report(student_id, status, created_at DESC);
CREATE INDEX CONCURRENTLY idx_reply_report
    ON reply(report_id, created_at ASC);
```

**V11 — vw_daily_stats (ONLY if Phase 0.5 confirmed it does not exist)**
```sql
CREATE OR REPLACE VIEW vw_daily_stats AS
SELECT
    COUNT(*) FILTER (WHERE current_phase NOT IN (0,4)) AS total_active,
    COUNT(*) FILTER (WHERE current_phase = 1)          AS waiting,
    COUNT(*) FILTER (WHERE current_phase = 2)          AS pending,
    COUNT(*) FILTER (WHERE current_phase = 3)          AS processing,
    COUNT(*) FILTER (WHERE current_phase = 4)          AS completed,
    COUNT(*) FILTER (WHERE current_phase = 0)          AS cancelled
FROM request
WHERE DATE(created_at) = CURRENT_DATE;
```

### 1.9 Queue Service — FOR UPDATE SKIP LOCKED (race condition fix)

```java
@Service
@RequiredArgsConstructor
@Transactional
public class QueueServiceImpl implements QueueService {

    private final NamedParameterJdbcTemplate jdbc;
    private final SimpMessagingTemplate ws;
    private final NotificationService notificationService;

    @Override
    public Optional<QueueTicketDTO> callNextTicket(Integer deskId, Integer registrarId) {
        // SELECT FOR UPDATE SKIP LOCKED: second concurrent transaction
        // immediately skips the locked row — zero deadlock, zero duplicate serve
        String sql = """
            UPDATE queue_tickets
            SET status       = 'CALLING',
                called_at    = NOW(),
                registrar_id = :registrarId
            WHERE id = (
                SELECT id FROM queue_tickets
                WHERE desk_id = :deskId
                  AND status  = 'WAITING'
                  AND DATE(created_at) = CURRENT_DATE
                ORDER BY ticket_number ASC
                LIMIT 1
                FOR UPDATE SKIP LOCKED
            )
            RETURNING id, ticket_number, ticket_prefix, student_id,
                      desk_id, registrar_id, status, called_at
            """;

        List<QueueTicketDTO> result = jdbc.query(sql,
            Map.of("deskId", deskId, "registrarId", registrarId),
            new QueueTicketRowMapper());

        if (!result.isEmpty()) {
            QueueTicketDTO ticket = result.get(0);
            ws.convertAndSend("/topic/queue/" + deskId, ticket);
            if (ticket.studentId() != null) {
                ws.convertAndSendToUser(ticket.studentId(), "/queue/your-turn", ticket);
                notificationService.createAndPush(
                    ticket.studentId(), "QUEUE_CALLED",
                    "Đến lượt của bạn!",
                    "Số " + ticket.ticketPrefix() + ticket.ticketNumber());
            }
            ws.convertAndSend("/topic/queue/" + deskId + "/stats", getQueueStats(deskId));
            return Optional.of(ticket);
        }
        return Optional.empty();
    }
}
```

### 1.10 Appointment Booking — Race Condition Fix (GAP-C)

```java
@Service
@RequiredArgsConstructor
@Transactional
public class AppointmentServiceImpl implements AppointmentService {

    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public AppointmentDTO book(String studentId, CreateAppointmentRequest req) {
        validateBusinessHours(req.appointmentTime());

        String sql = """
            INSERT INTO appointment (request_id, registrar_id,
                                     appointment_date, appointment_time,
                                     status, notes)
            SELECT :requestId, :registrarId, :date, :time, 0, :notes
            WHERE NOT EXISTS (
                SELECT 1 FROM appointment
                WHERE registrar_id     = :registrarId
                  AND appointment_date = :date
                  AND appointment_time = :time
                  AND status          != 2
                FOR UPDATE
            )
            RETURNING id, appointment_date, appointment_time, status
            """;

        List<AppointmentDTO> result = jdbc.query(sql,
            Map.of("requestId",   req.requestId(),
                   "registrarId", req.registrarId(),
                   "date",        req.appointmentDate(),
                   "time",        req.appointmentTime(),
                   "notes",       req.notes()),
            new AppointmentRowMapper());

        if (result.isEmpty())
            throw new AppointmentConflictException(
                "Time slot " + req.appointmentTime()
                    + " on " + req.appointmentDate() + " is already taken");
        return result.get(0);
    }

    private void validateBusinessHours(LocalTime time) {
        if (time.isBefore(LocalTime.of(7, 30)) || time.isAfter(LocalTime.of(16, 30)))
            throw new BusinessHoursException("Appointments only available 07:30–16:30");
    }
}

// AppointmentRowMapper — converts INTEGER status (0/1/2) to String label
public class AppointmentRowMapper implements RowMapper<AppointmentDTO> {
    @Override
    public AppointmentDTO mapRow(ResultSet rs, int n) throws SQLException {
        String statusLabel = switch (rs.getInt("status")) {
            case 0 -> "BOOKED";
            case 1 -> "COMPLETED";
            case 2 -> "CANCELLED";
            default -> "UNKNOWN";
        };
        return new AppointmentDTO(
            rs.getLong("id"),
            rs.getDate("appointment_date").toLocalDate(),
            rs.getTime("appointment_time").toLocalTime(),
            statusLabel);
    }
}
```

### 1.11 ServiceDeskService (was missing — tested in Phase 1 Gate)

```java
@Service
@RequiredArgsConstructor
@Transactional
public class ServiceDeskServiceImpl implements ServiceDeskService {

    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public ServiceDeskDTO openDesk(Integer deskId, Integer registrarId) {
        return jdbc.queryForObject("""
            UPDATE service_desk
            SET is_active = TRUE, registrar_id = :registrarId, opened_at = NOW()
            WHERE id = :deskId
            RETURNING id, desk_name, desk_code, is_active, registrar_id
            """,
            Map.of("deskId", deskId, "registrarId", registrarId),
            new ServiceDeskRowMapper());
    }

    @Override
    public ServiceDeskDTO closeDesk(Integer deskId) {
        jdbc.update("""
            UPDATE queue_tickets SET status = 'CANCELLED', notes = 'Desk closed'
            WHERE desk_id = :deskId AND status = 'WAITING'
              AND DATE(created_at) = CURRENT_DATE
            """, Map.of("deskId", deskId));
        return jdbc.queryForObject("""
            UPDATE service_desk
            SET is_active = FALSE, registrar_id = NULL, closed_at = NOW()
            WHERE id = :deskId
            RETURNING id, desk_name, desk_code, is_active, registrar_id
            """, Map.of("deskId", deskId), new ServiceDeskRowMapper());
    }

    @Override
    @Cacheable(value = "service-desks", key = "'all-active'")
    public List<ServiceDeskStatusDTO> getActiveDesks() {
        return jdbc.query("""
            SELECT sd.id, sd.desk_name, sd.desk_code, sd.is_active,
                   reg.full_name AS registrar_name,
                   COUNT(qt.id) FILTER (WHERE qt.status = 'WAITING')             AS waiting_count,
                   COUNT(qt.id) FILTER (WHERE qt.status IN ('CALLING','SERVING')) AS serving_count
            FROM service_desk sd
            LEFT JOIN registrar reg ON reg.id = sd.registrar_id
            LEFT JOIN queue_tickets qt ON qt.desk_id = sd.id
                AND DATE(qt.created_at) = CURRENT_DATE
            GROUP BY sd.id, sd.desk_name, sd.desk_code, sd.is_active, reg.full_name
            ORDER BY sd.desk_code
            """, Map.of(), new ServiceDeskStatusRowMapper());
    }
}
```

### 1.12 NotificationService — createAndPush (FCM + DB)

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationServiceImpl implements NotificationService {

    private final NamedParameterJdbcTemplate jdbc;
    private final FirebaseMessaging firebaseMessaging;

    @Override
    @Async
    public void createAndPush(String studentId, String type, String title, String body) {
        // 1. Persist notification
        jdbc.update("""
            INSERT INTO notification(student_id, type, title, body)
            VALUES (:studentId, :type, :title, :body)
            """, Map.of("studentId", studentId, "type", type, "title", title, "body", body));

        // 2. Get FCM tokens for student
        List<String> tokens = jdbc.queryForList(
            "SELECT fcm_token FROM student_device_token WHERE student_id = :id",
            Map.of("id", studentId), String.class);

        // 3. Push to each device
        for (String token : tokens) {
            try {
                firebaseMessaging.send(Message.builder()
                    .setToken(token)
                    .setNotification(Notification.builder()
                        .setTitle(title).setBody(body).build())
                    .putData("type", type)
                    .build());
            } catch (FirebaseMessagingException e) {
                if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED) {
                    jdbc.update("DELETE FROM student_device_token WHERE fcm_token = :t",
                        Map.of("t", token));
                }
                log.warn("[FCM] Send failed for token {}: {}", token, e.getMessage());
            }
        }
    }
}
```

### 1.13 Report Queries (report + reply domains restored)

```java
@Repository
@RequiredArgsConstructor
public class ReportRepositoryImpl implements ReportRepository {

    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public List<ServiceUsageReportDTO> getServiceUsageSummary(LocalDate from, LocalDate to) {
        return jdbc.query("""
            SELECT
                ac.service_name,
                sc.name                                              AS category_name,
                COUNT(r.id)                                          AS total_requests,
                COUNT(r.id) FILTER (WHERE r.current_phase = 4)      AS completed,
                COUNT(r.id) FILTER (WHERE r.current_phase = 0)      AS cancelled,
                ROUND(AVG(EXTRACT(EPOCH FROM (r.updated_at - r.created_at))/3600), 1) AS avg_hours,
                DATE_TRUNC('month', r.created_at)                   AS month
            FROM request r
            JOIN academic_service ac ON ac.id = r.service_id
            JOIN service_category sc ON sc.id = ac.service_category_id
            WHERE r.created_at BETWEEN :from AND :to
            GROUP BY ac.service_name, sc.name, DATE_TRUNC('month', r.created_at)
            ORDER BY month DESC, total_requests DESC
            """, Map.of("from", from, "to", to), new ServiceUsageRowMapper());
    }

    @Override
    public List<RegistrarPerformanceDTO> getRegistrarPerformance(LocalDate from, LocalDate to) {
        return jdbc.query("""
            SELECT
                reg.full_name,
                COUNT(DISTINCT rh.request_id)                        AS handled_requests,
                ROUND(AVG(EXTRACT(EPOCH FROM (r.updated_at - r.created_at))/3600), 1) AS avg_hours,
                COUNT(DISTINCT sf.id)                                AS feedback_received,
                ROUND(AVG(sf.rating), 1)                             AS avg_rating
            FROM registrar reg
            LEFT JOIN request_history rh ON rh.registrar_id = reg.id
                AND rh.created_at BETWEEN :from AND :to
            LEFT JOIN request r ON r.id = rh.request_id
            LEFT JOIN student_feedback sf ON sf.registrar_id = reg.id
                AND sf.created_at BETWEEN :from AND :to
            GROUP BY reg.id, reg.full_name
            ORDER BY handled_requests DESC
            """, Map.of("from", from, "to", to), new RegistrarPerformanceRowMapper());
    }

    @Override
    public DailyStatsDTO getDailyStats() {
        return jdbc.queryForObject("SELECT * FROM vw_daily_stats",
            Map.of(), new DailyStatsRowMapper());
    }
}
```

### 1.14 Auth Controller (Refresh + Logout)

```java
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@RequestBody @Valid LoginRequest req) {
        return ResponseEntity.ok(ApiResponse.ok(authService.login(req)));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<LoginResponse>> refresh(@RequestBody @Valid RefreshTokenRequest req) {
        return ResponseEntity.ok(ApiResponse.ok(authService.refreshAccessToken(req.refreshToken())));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestBody @Valid RefreshTokenRequest req) {
        authService.revokeRefreshToken(req.refreshToken());
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
```

### 1.15 ApiResponse + GlobalExceptionHandler

```java
public record ApiResponse<T>(
    boolean success, String message, T data,
    String errorCode, LocalDateTime timestamp) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, "OK", data, null, LocalDateTime.now());
    }
    public static ApiResponse<Void> error(String msg, String code) {
        return new ApiResponse<>(false, msg, null, code, LocalDateTime.now());
    }
}

@Slf4j   // ← Required — without this log.error() won't compile
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> notFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(404).body(ApiResponse.error(ex.getMessage(), "NOT_FOUND"));
    }
    @ExceptionHandler(QueueConflictException.class)
    public ResponseEntity<ApiResponse<Void>> queueConflict(QueueConflictException ex) {
        return ResponseEntity.status(409).body(ApiResponse.error(ex.getMessage(), "QUEUE_CONFLICT"));
    }
    @ExceptionHandler(AppointmentConflictException.class)
    public ResponseEntity<ApiResponse<Void>> apptConflict(AppointmentConflictException ex) {
        return ResponseEntity.status(409).body(ApiResponse.error(ex.getMessage(), "APPOINTMENT_CONFLICT"));
    }
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> forbidden(AccessDeniedException ex) {
        return ResponseEntity.status(403).body(ApiResponse.error("Access denied", "FORBIDDEN"));
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> generic(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(500).body(ApiResponse.error("Internal server error", "INTERNAL_ERROR"));
    }
}
```

### 1.16 Rate Limiting

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RateLimitFilter extends OncePerRequestFilter {

    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();
    private record RateLimitRule(String path, long capacity, long refill, Duration period) {}

    private static final List<RateLimitRule> RULES = List.of(
        new RateLimitRule("/api/auth/login",         5,  5,  Duration.ofMinutes(15)),
        new RateLimitRule("/api/student/auth/login", 5,  5,  Duration.ofMinutes(15)),
        new RateLimitRule("/api/public/",           100, 100, Duration.ofMinutes(1)),
        new RateLimitRule("/api/student/requests",  10, 10,  Duration.ofHours(1))
    );

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String ip = req.getRemoteAddr(), path = req.getRequestURI();
        for (RateLimitRule rule : RULES) {
            if (path.startsWith(rule.path())) {
                Bucket bucket = buckets.computeIfAbsent(ip + ":" + rule.path(), k ->
                    Bucket.builder().addLimit(Bandwidth.classic(rule.capacity(),
                        Refill.intervally(rule.refill(), rule.period()))).build());
                if (!bucket.tryConsume(1)) {
                    res.setStatus(429); res.setContentType("application/json");
                    res.getWriter().write("""
                        {"success":false,"errorCode":"RATE_LIMITED","message":"Too many requests."}
                        """);
                    return;
                }
                break;
            }
        }
        chain.doFilter(req, res);
    }
}
```

### 1.17 application-test.properties

```properties
# src/test/resources/application-test.properties
spring.datasource.url=jdbc:tc:postgresql:15:///pdt_test?TC_REUSABLE=true
spring.datasource.driver-class-name=org.testcontainers.jdbc.ContainerDatabaseDriver
spring.datasource.username=test
spring.datasource.password=test
spring.flyway.locations=classpath:db/migration_new
spring.flyway.clean-disabled=false
spring.redis.host=localhost
spring.redis.port=6370
jwt.secret=test-secret-at-least-32-chars-long!!test
logging.level.com.huit.pdt=DEBUG
```

### 1.18 JUnit Test Suite

```
src/test/java/com/huit/pdt/
  domain/
    queue/
      QueueServiceTest.java               ← unit, Mockito
      QueueRaceConditionTest.java         ← @ParameterizedTest(2,5,10,20) + @RepeatedTest(100)
    appointment/
      AppointmentServiceTest.java
      AppointmentRaceConditionTest.java   ← @ParameterizedTest(2,5,10) + @RepeatedTest(50)
    request/RequestServiceTest.java
    notification/NotificationServiceTest.java
    auth/
      RefreshTokenServiceTest.java
      StudentUserDetailsServiceTest.java
      RegistrarUserDetailsServiceTest.java
  infrastructure/persistence/
    QueueRepositoryIntegrationTest.java      ← Testcontainers PG
    AppointmentRepositoryIntegrationTest.java
    NotificationRepositoryIntegrationTest.java
  web/controller/
    AuthControllerTest.java      ← 200 login/refresh/logout, 429 rate-limit
    QueueControllerTest.java     ← 200 success, 409 conflict
    StudentControllerTest.java   ← 401 when no token
    AppointmentControllerTest.java
  integration/
    FullQueueFlowTest.java
    FullAppointmentFlowTest.java
```

**Race condition tests:**

```java
@SpringBootTest
@ActiveProfiles("test")
@Testcontainers
class QueueRaceConditionTest {

    @ParameterizedTest
    @ValueSource(ints = {2, 5, 10, 20})
    @RepeatedTest(100)
    void concurrentCallNext_exactlyOneWins(int concurrency) throws Exception {
        Integer deskId = seedOneWaitingTicket();
        ExecutorService pool = Executors.newFixedThreadPool(concurrency);
        List<Future<Optional<QueueTicketDTO>>> futures = pool.invokeAll(
            IntStream.range(0, concurrency)
                .mapToObj(i -> (Callable<Optional<QueueTicketDTO>>)
                    () -> queueService.callNextTicket(deskId, i + 1))
                .toList());
        pool.shutdown(); pool.awaitTermination(10, TimeUnit.SECONDS);
        long wins = futures.stream()
            .map(f -> { try { return f.get(); } catch (Exception e) { return Optional.empty(); }})
            .filter(Optional::isPresent).count();
        assertThat(wins).isEqualTo(1);
    }
}

class AppointmentRaceConditionTest {
    @ParameterizedTest
    @ValueSource(ints = {2, 5, 10})
    @RepeatedTest(50)
    void concurrentBooking_onlyOneSucceeds(int concurrency) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(concurrency);
        CreateAppointmentRequest req = new CreateAppointmentRequest(
            1, 1, LocalDate.of(2026, 6, 1), LocalTime.of(9, 0), null);
        List<Future<AppointmentDTO>> futures = pool.invokeAll(
            Collections.nCopies(concurrency, () -> appointmentService.book("2001215001", req)));
        pool.shutdown();
        long success = futures.stream()
            .map(f -> { try { return f.get(); } catch (Exception e) { return null; }})
            .filter(Objects::nonNull).count();
        assertThat(success).isEqualTo(1);
    }
}
```

### ✅ Phase 1 Gate — Full curl Verification

```bash
BASE="http://localhost:8081/api"
cd backend && ./mvnw verify -Dspring.profiles.active=test
# Expected: BUILD SUCCESS, 0 failures

./mvnw spring-boot:run -Dspring-boot.run.profiles=dev &
sleep 15

# Health check
curl -s http://localhost:8081/internal/actuator/health | jq '.status'
# Expected: "UP"

# Old actuator path sealed
[ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8081/actuator/metrics)" = "404" ] \
  && echo "✅ Actuator secured" || echo "❌ FAIL"

# Student route requires auth
[ "$(curl -s -o /dev/null -w '%{http_code}' $BASE/student/profile)" = "401" ] \
  && echo "✅ Auth enforced" || echo "❌ FAIL"

# Get all three tokens
ADMIN_TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"ADMIN","password":"123456"}' | jq -r '.data.token')
REG_TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"NV001","password":"123456"}' | jq -r '.data.token')
STU_TOKEN=$(curl -s -X POST $BASE/student/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mssv":"2001215001","password":"123456"}' | jq -r '.data.token')
echo "Tokens OK: ADMIN=${ADMIN_TOKEN:0:20}..."

# Public endpoints (no auth)
curl -s $BASE/public/service-categories | jq '{count: (.data | length)}'
# Expected: {count: 3}

# Student endpoints
curl -s $BASE/student/profile -H "Authorization: Bearer $STU_TOKEN" | jq '.data.studentId'
# Expected: "2001215001"
curl -s $BASE/student/notifications -H "Authorization: Bearer $STU_TOKEN" | jq '.success'
curl -s $BASE/student/notifications/unread-count -H "Authorization: Bearer $STU_TOKEN" | jq '.data'
curl -s -X PATCH $BASE/student/notifications/read-all -H "Authorization: Bearer $STU_TOKEN" | jq '.success'
curl -s "$BASE/student/appointments/available-slots?serviceId=1&date=2026-06-01" \
  -H "Authorization: Bearer $STU_TOKEN" | jq '.success'
curl -s -X POST $BASE/student/appointments \
  -H "Authorization: Bearer $STU_TOKEN" -H "Content-Type: application/json" \
  -d '{"requestId":1,"registrarId":1,"appointmentDate":"2026-06-01","appointmentTime":"09:00"}' \
  | jq '{success, id: .data.id}'

# Registrar endpoints
curl -s $BASE/registrar/queue/1/stats -H "Authorization: Bearer $REG_TOKEN" | jq '.data'
curl -s -X POST $BASE/registrar/queue/1/call-next -H "Authorization: Bearer $REG_TOKEN" \
  | jq '{success, ticket: .data.ticketNumber}'
curl -s -X POST $BASE/registrar/desks/1/open -H "Authorization: Bearer $REG_TOKEN" | jq '.success'
curl -s -X POST $BASE/registrar/desks/1/close -H "Authorization: Bearer $REG_TOKEN" | jq '.success'

# Refresh token cycle
REFRESH=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"ADMIN","password":"123456"}' | jq -r '.data.refreshToken')
NEW_TOKEN=$(curl -s -X POST $BASE/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}" | jq -r '.data.token')
[ -n "$NEW_TOKEN" ] && echo "✅ Refresh OK" || echo "❌ Refresh failed"

curl -s -X POST $BASE/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}" | jq '.success'

# Revoked token must be rejected
[ "$(curl -s -o /dev/null -w '%{http_code}' -X POST $BASE/auth/refresh \
  -H 'Content-Type: application/json' -d "{\"refreshToken\":\"$REFRESH\"}")" = "401" ] \
  && echo "✅ Revoked token rejected"

# Role separation
[ "$(curl -s -o /dev/null -w '%{http_code}' $BASE/registrar/dashboard \
  -H "Authorization: Bearer $STU_TOKEN")" = "403" ] \
  && echo "✅ Role separation OK"

# Rate limiting: attempts 1-5 → 401, attempts 6-7 → 429
for i in {1..7}; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE/auth/login \
    -H "Content-Type: application/json" -d '{"username":"x","password":"x"}')
  [ $i -le 5 ] && EXP="401" || EXP="429"
  [ "$HTTP" = "$EXP" ] && echo "✅ Attempt $i: $HTTP" || echo "❌ Attempt $i: $HTTP (expected $EXP)"
done

# WebSocket auth
wscat -c "ws://localhost:8081/ws/websocket" \
  --header "Authorization: Bearer $REG_TOKEN" && echo "✅ WS auth accepted"
wscat -c "ws://localhost:8081/ws/websocket" 2>&1 | grep -qi "unauthorized\|403\|401" \
  && echo "✅ WS rejects unauthenticated" || echo "❌ WS accepted unauthenticated"
```

---

## PHASE 2 — Vue.js AdminStaff Refactor

### 2.1 .env Setup + Vite Proxy

**`AdminStaff/.env.example`:**
```bash
VITE_API_BASE_URL=http://localhost:8081/api
VITE_WS_URL=http://localhost:8081
```

**`AdminStaff/vite.config.ts`:**
```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [vue()],
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  server: {
    port: 5173,
    proxy: {
      '/api': { target: 'http://localhost:8081', changeOrigin: true },
      '/ws':  { target: 'http://localhost:8081', ws: true, changeOrigin: true },
    }
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-vue':  ['vue', 'vue-router', 'pinia'],
          'vendor-http': ['axios'],
          'vendor-ws':   ['@stomp/stompjs', 'sockjs-client'],
        }
      }
    },
    chunkSizeWarningLimit: 500,
  },
  test: {
    environment: 'happy-dom',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      threshold: { lines: 70, functions: 70, branches: 60 }
    }
  }
})
```

### 2.2 Install Dependencies

```bash
cd AdminStaff
npm install @stomp/stompjs sockjs-client axios
npm install -D vitest @vue/test-utils happy-dom @vitest/coverage-v8
# Add to package.json: "test:unit": "vitest run", "test:coverage": "vitest run --coverage"
```

### 2.3 Feature-Sliced Architecture

```
AdminStaff/src/
  features/
    auth/
      composables/useAuth.ts
      stores/authStore.ts
      views/LoginView.vue
    queue/
      composables/useQueue.ts
      composables/useQueueWebSocket.ts    ← with JWT in STOMP CONNECT
      stores/queueStore.ts
      views/QueueManagementView.vue
      views/QueueDisplayBoard.vue         ← fullscreen kiosk view
      components/QueueTicketCard.vue
      components/QueueStatsBar.vue
      components/QueueWsStatusBanner.vue  ← disconnect/reconnect indicator
    requests/
      stores/requestStore.ts
      views/RequestListView.vue
      views/RequestDetailView.vue
      components/RequestStatusBadge.vue   ← maps phase 0-6 to colored badges
      components/RequestPhaseTimeline.vue
    appointments/
      stores/appointmentStore.ts
      views/AppointmentCalendarView.vue
      views/AppointmentListView.vue
    feedback/
      stores/feedbackStore.ts
      views/FeedbackListView.vue
      views/FeedbackDetailView.vue        ← includes Reply thread
    dashboard/
      stores/dashboardStore.ts
      views/DashboardView.vue
      components/DailyStatsWidget.vue
      components/ServiceUsageChart.vue
      components/RegistrarPerformanceTable.vue
    notifications/
      stores/notificationStore.ts
      components/NotificationBell.vue     ← badge + dropdown
  shared/
    api/apiClient.ts, endpoints.ts
    components/
      BaseButton.vue, BaseModal.vue, BaseTable.vue
      BasePagination.vue, BaseToast.vue
      BaseSkeletonLoader.vue, BaseStatusBadge.vue
      BaseEmptyState.vue, BaseConfirmDialog.vue
    composables/usePagination.ts, useToast.ts, useConfirm.ts
    stores/uiStore.ts
    types/api.types.ts, domain.types.ts
    utils/formatDate.ts, formatStatus.ts
  router/index.ts
  App.vue
  main.ts
```

### 2.4 API Client with Global Error Handler

```typescript
// shared/api/apiClient.ts
import axios from 'axios'
import type { AxiosError } from 'axios'

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 10000,
})

apiClient.interceptors.request.use(config => {
  const auth = useAuthStore()
  if (auth.token) config.headers.Authorization = `Bearer ${auth.token}`
  return config
})

apiClient.interceptors.response.use(
  res => res,
  async (err: AxiosError<{ message?: string; errorCode?: string }>) => {
    if (err.response?.status === 401) {
      const auth = useAuthStore()
      const refreshed = await auth.tryRefresh()
      if (refreshed) {
        err.config!.headers!['Authorization'] = `Bearer ${auth.token}`
        return apiClient.request(err.config!)
      }
      auth.logout()
      window.location.href = '/login'
    }
    return Promise.reject({
      message: err.response?.data?.message  ?? 'Lỗi kết nối mạng',
      code:    err.response?.data?.errorCode ?? 'NETWORK_ERROR',
      status:  err.response?.status ?? 0,
    })
  }
)

// main.ts — global Vue error boundary
// app.config.errorHandler = (err, _instance, info) => {
//   const { showToast } = useToast()
//   console.error('[Vue Error]', err, info)
//   showToast({ type: 'error', message: 'Đã có lỗi xảy ra. Vui lòng thử lại.' })
// }
```

### 2.5 Domain Types (aligned with actual DB schema)

```typescript
// shared/types/domain.types.ts
// IMPORTANT: request.current_phase is INTEGER per V1 schema

export const REQUEST_PHASE = {
  0: { label: 'Đã hủy',          color: 'red'    },
  1: { label: 'Xếp hàng',        color: 'blue'   },
  2: { label: 'Chờ xử lý',       color: 'yellow' },
  3: { label: 'Đang xử lý',      color: 'orange' },
  4: { label: 'Hoàn thành',      color: 'green'  },
  5: { label: 'Đã nhận kết quả', color: 'teal'   },
  6: { label: 'Bổ sung hồ sơ',   color: 'purple' },
} as const

export const APPOINTMENT_STATUS = {
  0: { label: 'Đã đặt lịch', color: 'blue'  },
  1: { label: 'Hoàn thành',  color: 'green' },
  2: { label: 'Đã hủy',      color: 'red'   },
} as const

export const REPORT_TYPE = {
  0: { label: 'Góp ý',     color: 'blue'  },
  1: { label: 'Khiếu nại', color: 'red'   },
  2: { label: 'Khen ngợi', color: 'green' },
} as const

export interface Student {
  studentId: string    // VARCHAR(10) — NOT a number!
  fullName: string
  major?: string
  dateOfBirth?: string
  gender?: string
  phone?: string
  email?: string
}
```

### 2.6 WebSocket Composable WITH JWT (GAP-B resolved)

```typescript
// features/queue/composables/useQueueWebSocket.ts
import { ref, onUnmounted } from 'vue'
import { Client } from '@stomp/stompjs'
import SockJS from 'sockjs-client'
import { useAuthStore } from '@/features/auth/stores/authStore'

export function useQueueWebSocket(deskId: number) {
  const currentTicket = ref<QueueTicket | null>(null)
  const queueStats = ref({ waiting: 0, calling: 0, serving: 0, completed: 0 })
  const connected = ref(false)
  const auth = useAuthStore()

  const client = new Client({
    webSocketFactory: () => new SockJS(`${import.meta.env.VITE_WS_URL}/ws`),

    // ── JWT in STOMP CONNECT frame ──────────────────────────────
    connectHeaders: { Authorization: `Bearer ${auth.token}` },
    // ───────────────────────────────────────────────────────────

    reconnectDelay: 3000,
    onConnect: () => {
      connected.value = true
      client.subscribe(`/topic/queue/${deskId}`, msg => {
        currentTicket.value = JSON.parse(msg.body)
      })
      client.subscribe(`/topic/queue/${deskId}/stats`, msg => {
        queueStats.value = JSON.parse(msg.body)
      })
    },
    onDisconnect: () => { connected.value = false },
    onStompError:  () => { connected.value = false },
  })

  client.activate()
  onUnmounted(() => client.deactivate())
  return { currentTicket, queueStats, connected }
}
```

### 2.7 Date Utilities — vi-VN (centralized, no scattered formatting)

```typescript
// shared/utils/formatDate.ts
const viDT = new Intl.DateTimeFormat('vi-VN', {
  day: '2-digit', month: '2-digit', year: 'numeric',
  hour: '2-digit', minute: '2-digit', hour12: false,
})
const viD = new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
const viT = new Intl.DateTimeFormat('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false })

export const formatDateTime = (iso?: string | null) => iso ? viDT.format(new Date(iso)) : '—'
export const formatDate     = (iso?: string | null) => iso ? viD.format(new Date(iso)) : '—'
export const formatTime     = (iso?: string | null) => iso ? viT.format(new Date(iso)) : '—'
export const formatRelative = (iso: string): string => {
  const diff = Date.now() - new Date(iso).getTime()
  if (diff < 60000)    return 'Vừa xong'
  if (diff < 3600000)  return `${Math.floor(diff / 60000)} phút trước`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)} giờ trước`
  return formatDate(iso)
}
```

### 2.8 Pinia Stores — Stale-While-Revalidate

```typescript
export const useQueueStore = defineStore('queue', () => {
  const stats = ref<Record<number, QueueStats>>({})
  const lastFetch = ref<Record<number, number>>({})
  const STALE_MS = 5000  // 5 seconds for real-time queue data

  async function fetchStats(deskId: number) {
    const now = Date.now()
    if (lastFetch.value[deskId] && now - lastFetch.value[deskId] < STALE_MS)
      return stats.value[deskId]  // cache hit — no API call
    const res = await apiClient.get(`/registrar/queue/${deskId}/stats`)
    stats.value[deskId] = res.data.data
    lastFetch.value[deskId] = now
    return stats.value[deskId]
  }

  // WebSocket invalidation — call when WS push arrives
  function invalidate(deskId: number) { lastFetch.value[deskId] = 0 }

  return { stats, fetchStats, invalidate }
})
```

### 2.9 Router with Lazy Loading + Guards

```typescript
const routes = [
  { path: '/login',
    component: () => import('@/features/auth/views/LoginView.vue'),
    meta: { public: true } },
  { path: '/queue/:deskId',
    component: () => import('@/features/queue/views/QueueManagementView.vue'),
    meta: { requiresAuth: true, roles: ['Admin', 'Registrar'] } },
  { path: '/queue/:deskId/display',
    component: () => import('@/features/queue/views/QueueDisplayBoard.vue'),
    meta: { public: true } },  // display board shown on public screens
  { path: '/requests',
    component: () => import('@/features/requests/views/RequestListView.vue'),
    meta: { requiresAuth: true, roles: ['Admin', 'Registrar'] } },
  { path: '/requests/:id',
    component: () => import('@/features/requests/views/RequestDetailView.vue'),
    meta: { requiresAuth: true, roles: ['Admin', 'Registrar'] } },
  { path: '/appointments',
    component: () => import('@/features/appointments/views/AppointmentListView.vue'),
    meta: { requiresAuth: true, roles: ['Admin', 'Registrar'] } },
  { path: '/feedback',
    component: () => import('@/features/feedback/views/FeedbackListView.vue'),
    meta: { requiresAuth: true, roles: ['Admin', 'Registrar'] } },
  { path: '/dashboard',
    component: () => import('@/features/dashboard/views/DashboardView.vue'),
    meta: { requiresAuth: true, roles: ['Admin'] } },
  { path: '/:pathMatch(.*)*', redirect: '/queue/1' },
]

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isAuthenticated) return next('/login')
  if (to.meta.roles && !auth.hasAnyRole(to.meta.roles as string[])) return next('/403')
  next()
})
```

### 2.10 Vitest Tests

```typescript
// __tests__/shared/utils/formatDate.spec.ts
describe('formatDate vi-VN', () => {
  it('formats ISO to dd/MM/yyyy', () =>
    expect(formatDate('2026-01-15T00:00:00Z')).toMatch(/15\/01\/2026/))
  it('returns — for null', () => expect(formatDate(null)).toBe('—'))
  it('returns — for undefined', () => expect(formatDate(undefined)).toBe('—'))
})

// __tests__/features/queue/queueStore.spec.ts
describe('queueStore stale-while-revalidate', () => {
  it('returns cache within TTL — no API call', async () => {
    const store = useQueueStore()
    store.$patch({ stats: { 1: mockStats }, lastFetch: { 1: Date.now() } })
    const spy = vi.spyOn(apiClient, 'get')
    await store.fetchStats(1)
    expect(spy).not.toHaveBeenCalled()
  })
  it('calls API when cache is stale', async () => {
    const store = useQueueStore()
    store.$patch({ lastFetch: { 1: Date.now() - 10000 } })
    vi.spyOn(apiClient, 'get').mockResolvedValue({ data: { data: mockStats } })
    await store.fetchStats(1)
    expect(apiClient.get).toHaveBeenCalledWith('/registrar/queue/1/stats')
  })
})

// __tests__/features/auth/authStore.spec.ts
describe('authStore', () => {
  it('sets token on login', async () => { /* ... */ })
  it('clears token on logout', () => { /* ... */ })
  it('401 interceptor triggers logout after failed refresh', async () => { /* ... */ })
})
```

### ✅ Phase 2 Gate

```bash
cd AdminStaff

# Build — all chunks must be < 500KB
npm run build
# Expected: dist/ created, 0 TypeScript errors

# Unit tests — must meet threshold
npm run test:coverage
# Expected: all pass, lines ≥ 70%

# Proxy verification (confirms Vue → Backend connection)
npm run dev &
sleep 5
curl -s http://localhost:5173/api/public/service-categories | jq '{count: (.data | length)}'
# Expected: {count: 3} — Vite proxy routing to backend works

# UX Acceptance — Queue Management (manual):
# [ ] Skeleton visible within 100ms of navigation
# [ ] WS "connected" indicator green immediately on arrive
# [ ] "Gọi số tiếp theo" → button shows loading → ticket updates < 500ms via WS push
# [ ] WS disconnect → QueueWsStatusBanner appears (NON-BLOCKING, top banner — not modal)
# [ ] WS reconnect → banner auto-dismisses within 3s, zero user action required
# [ ] Ticket number transition: slide-up 200ms, no flash or jump
# [ ] Queue count badge updates without full page re-render

# UX Acceptance — Appointment Calendar:
# [ ] Available slots green, taken slots red/grey
# [ ] Clicking slot → optimistic color change immediately before API resolves
# [ ] 409 conflict → slot turns red, toast shows: "Khung giờ này đã có người đặt"

# UX Acceptance — Request Detail:
# [ ] 7-step phase stepper with colors matching REQUEST_PHASE map exactly
# [ ] Phase 6 "Bổ sung hồ sơ" shows prominent upload CTA

# UX Acceptance — Feedback:
# [ ] Reply thread renders below feedback card
# [ ] New reply → optimistic prepend to thread, no page reload
```

---

## PHASE 3 — Flutter Refactor

### 3.1 Endpoint Audit (GAP-001 — critical)

> Actual `api_service.dart` uses `_baseUrl = 'http://127.0.0.1:8081/api/student'`.
> After changing base to `/api`, every endpoint string must be audited:

| Old relative path | Full old URL | New path (base = `/api`) | Changed? |
|---|---|---|---|
| `/auth/login` | `/api/student/auth/login` | `/student/auth/login` | ✅ same |
| `/categories` | `/api/student/categories` | `/public/service-categories` | 🔴 changed |
| `/services?categoryId=X` | `/api/student/services?...` | `/public/services?categoryId=X` | 🔴 changed |
| `/appointments?mssv=X` | `/api/student/appointments?mssv=X` | `/student/appointments` (JWT = identity) | 🔴 mssv param removed |
| `/appointments/{id}?mssv=X` | `/api/student/appointments/{id}?mssv=X` | `/student/appointments/{id}` | 🔴 mssv param removed |
| `/feedback?mssv=X` | `/api/student/feedback?mssv=X` | `/student/feedback` | 🔴 mssv param removed |
| `/profile PUT` | `/api/student/profile` | `/student/profile` | ✅ same |
| *(new)* | — | `/student/notifications` | 🆕 |
| *(new)* | — | `/student/notifications/unread-count` | 🆕 |
| *(new)* | — | `/student/notifications/fcm-token` | 🆕 |

### 3.2 Final pubspec.yaml

```yaml
name: flutter_huit_student
description: HUIT Student Services App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  go_router: ^14.0.0
  dio: ^5.4.3                       # already in project ✅
  stomp_dart_client: ^2.0.0         # MUST be ^2.0.0 — ^1.2.0 is outdated
  flutter_secure_storage: ^9.2.2    # JWT MUST use this — NOT Hive (Hive = unencrypted!)
  hive_flutter: ^1.1.0              # Non-sensitive cache only: request lists, categories
  firebase_core: ^3.3.0
  firebase_messaging: ^15.1.0
  flutter_local_notifications: ^17.2.0
  connectivity_plus: ^6.0.5
  shimmer: ^3.0.0                   # already in project ✅
  cached_network_image: ^3.3.1      # already in project ✅
  flutter_svg: ^2.0.10+1
  lottie: ^3.1.0
  intl: ^0.19.0
  uuid: ^4.4.0
  url_launcher: ^6.2.6
  google_fonts: ^6.2.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  build_runner: ^2.4.9
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

### 3.3 AppConfig (replaces hardcoded URL)

```dart
// lib/core/config/app_config.dart
class AppConfig {
  // Override at build time:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api
  //             --dart-define=WS_URL=http://10.0.2.2:8081
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081/api',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );
}
```

**Run commands:**
```bash
# Android Emulator (10.0.2.2 = host machine localhost)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081/api \
  --dart-define=WS_URL=http://10.0.2.2:8081

# Physical device
adb reverse tcp:8081 tcp:8081
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081/api \
  --dart-define=WS_URL=http://127.0.0.1:8081

# Production release
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.huit-pdt.edu.vn/api \
  --dart-define=WS_URL=https://api.huit-pdt.edu.vn
```

### 3.4 Secure Token Storage (GAP-I — JWT must not use Hive)

```dart
// lib/core/storage/secure_storage.dart
// CRITICAL: JWT MUST use FlutterSecureStorage — NOT Hive
// Hive stores data unencrypted; on rooted/jailbroken devices = exposed tokens

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String studentId,
  }) async {
    await Future.wait([
      _storage.write(key: 'access_token',  value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
      _storage.write(key: 'student_id',    value: studentId),
    ]);
  }

  Future<String?> getAccessToken()  async => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() async => _storage.read(key: 'refresh_token');
  Future<String?> getStudentId()    async => _storage.read(key: 'student_id');
  Future<void>    clearAll()        async => _storage.deleteAll();
}
```

### 3.5 Dio Client with JWT Interceptor + Auto-Refresh

```dart
// lib/core/api/api_client.dart
class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);
  final SecureStorage _storage;
  final Dio _dio;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    final token = await _storage.getAccessToken();
    if (token != null) o.headers['Authorization'] = 'Bearer $token';
    h.next(o);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler h) async {
    if (err.response?.statusCode == 401) {
      final refresh = await _storage.getRefreshToken();
      if (refresh != null) {
        try {
          final res = await _dio.post('/student/auth/refresh',
              data: {'refreshToken': refresh});
          final newToken   = res.data['data']['token'] as String;
          final newRefresh = res.data['data']['refreshToken'] as String;
          await _storage.saveTokens(
            accessToken:  newToken,
            refreshToken: newRefresh,
            studentId:    await _storage.getStudentId() ?? '',
          );
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retry = await _dio.fetch(err.requestOptions);
          return h.resolve(retry);
        } catch (_) { await _storage.clearAll(); }
      }
    }
    h.next(err);
  }
}
```

### 3.6 Feature Architecture

```
flutter_huit_student/lib/
  core/
    api/api_client.dart, api_endpoints.dart
    cache/hive_cache_manager.dart        ← non-sensitive data (request lists, categories)
    config/app_config.dart
    connectivity/connectivity_cubit.dart
    storage/secure_storage.dart          ← JWT only
    websocket/queue_ws_service.dart
  features/
    auth/
      data/auth_repository_impl.dart
      domain/auth_repository.dart, models/auth_model.dart
      presentation/bloc/auth_bloc.dart
      presentation/pages/login_page.dart
    queue/
      data/queue_repository_impl.dart
      domain/models/queue_ticket_model.dart
      presentation/bloc/queue_bloc.dart
      presentation/pages/queue_status_page.dart
      presentation/widgets/queue_ticket_widget.dart
    requests/
      data/request_repository_impl.dart
      domain/models/request_model.dart
      presentation/bloc/request_bloc.dart
      presentation/pages/
        request_list_page.dart
        create_request_page.dart
        request_detail_page.dart
      presentation/widgets/request_phase_stepper.dart   ← phases 0-6
    appointments/
      presentation/bloc/appointment_bloc.dart
      presentation/pages/
        appointment_list_page.dart
        create_appointment_page.dart
    feedback/
      presentation/bloc/feedback_bloc.dart
      presentation/pages/
        feedback_list_page.dart
        submit_feedback_page.dart
    notifications/
      data/notification_repository_impl.dart
      data/fcm_token_service.dart
      presentation/bloc/notification_bloc.dart
      presentation/pages/notification_list_page.dart
    profile/
      presentation/bloc/profile_bloc.dart
      presentation/pages/profile_page.dart
  shared/
    widgets/
      loading_skeleton.dart
      offline_banner.dart
      status_badge.dart               ← maps integers to colored chips
      empty_state.dart, error_state.dart
      app_bottom_nav.dart
  app/
    router/app_router.dart
    theme/app_theme.dart
    app.dart
  main.dart
```

### 3.7 WebSocket Client WITH JWT (GAP-B Flutter resolved)

```dart
// lib/core/websocket/queue_ws_service.dart
class QueueWsService {
  StompClient? _client;
  final SecureStorage _storage;
  QueueWsService(this._storage);

  Future<void> connect({
    required String studentId,
    required void Function(QueueTicketModel) onYourTurn,
    required void Function() onConnected,
    required void Function() onDisconnected,
  }) async {
    final token = await _storage.getAccessToken();

    _client = StompClient(
      config: StompConfig.SockJS(
        url: '${AppConfig.wsUrl}/ws',

        // ── JWT in STOMP CONNECT frame ──────────────────────
        stompConnectHeaders: { 'Authorization': 'Bearer $token' },
        webSocketConnectHeaders: { 'Authorization': 'Bearer $token' },
        // ───────────────────────────────────────────────────

        onConnect: (frame) {
          onConnected();
          _client!.subscribe(
            destination: '/user/$studentId/queue/your-turn',
            callback: (frame) {
              final ticket = QueueTicketModel.fromJson(jsonDecode(frame.body!));
              onYourTurn(ticket);
            },
          );
          _client!.subscribe(
            destination: '/user/$studentId/notifications/new',
            callback: (_) { /* refresh NotificationBloc unread count */ },
          );
        },
        onDisconnect: (_) => onDisconnected(),
        onWebSocketError: (e) { debugPrint('[WS] Error: $e'); onDisconnected(); },
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _client!.activate();
  }

  void disconnect() => _client?.deactivate();
}
```

### 3.8 Connectivity + Offline Banner

```dart
// lib/core/connectivity/connectivity_cubit.dart
class ConnectivityCubit extends Cubit<ConnectivityState> {
  late final StreamSubscription _sub;
  ConnectivityCubit() : super(const ConnectivityOnline()) {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      emit(results.any((r) => r != ConnectivityResult.none)
          ? const ConnectivityOnline() : const ConnectivityOffline());
    });
  }
  @override
  Future<void> close() { _sub.cancel(); return super.close(); }
}

// lib/shared/widgets/offline_banner.dart
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
    BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) => Column(children: [
        if (state is ConnectivityOffline)
          Container(
            width: double.infinity,
            color: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Flexible(child: Text(
                'Không có kết nối — đang hiển thị dữ liệu đã lưu',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              )),
            ]),
          ),
        Expanded(child: child),
      ]),
    );
}
```

### 3.9 Cache-First BLoC Pattern

```dart
Future<void> _onLoadRequests(LoadRequests event, Emitter<RequestState> emit) async {
  // 1. Show cached immediately — instant perceived performance
  final cached = await _cache.getRequests();
  if (cached != null) {
    emit(RequestLoaded(requests: cached, isStale: true));
  } else {
    emit(RequestLoading());
  }

  // 2. Always fetch fresh
  try {
    final fresh = await _repo.getRequests();
    await _cache.saveRequests(fresh);
    emit(RequestLoaded(requests: fresh, isStale: false));
  } on DioException catch (e) {
    if (cached == null) emit(RequestError(message: e.message ?? 'Lỗi kết nối'));
    // if cached exists → silently keep showing stale (offline scenario)
  }
}
```

### 3.10 GoRouter + Deep Links

```dart
// lib/app/router/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/queue',
  redirect: (context, state) {
    final isAuthenticated = context.read<AuthBloc>().state is AuthAuthenticated;
    final onLogin = state.matchedLocation == '/login';
    if (!isAuthenticated && !onLogin) return '/login';
    if (isAuthenticated && onLogin) return '/queue';
    return null;
  },
  routes: [
    GoRoute(path: '/login',   builder: (_, __) => const LoginPage()),
    GoRoute(path: '/queue',   builder: (_, __) => const QueueStatusPage()),
    GoRoute(path: '/requests', builder: (_, __) => const RequestListPage()),
    GoRoute(path: '/requests/:id',
        builder: (_, state) =>
            RequestDetailPage(id: int.parse(state.pathParameters['id']!))),
    GoRoute(path: '/appointments', builder: (_, __) => const AppointmentListPage()),
    GoRoute(path: '/appointments/create',
        builder: (_, state) =>
            CreateAppointmentPage(serviceId: state.uri.queryParameters['serviceId'])),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationListPage()),
    GoRoute(path: '/feedback',      builder: (_, __) => const FeedbackListPage()),
    GoRoute(path: '/feedback/submit', builder: (_, __) => const SubmitFeedbackPage()),
    GoRoute(path: '/profile',       builder: (_, __) => const ProfilePage()),
  ],
  errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Trang không tồn tại: ${state.error}'))),
);
```

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<activity ...>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="huit-pdt" android:host="*" />
  </intent-filter>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="huit-pdt.app" />
  </intent-filter>
</activity>
```

**`ios/Runner/Info.plist`:**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>huit-pdt</string></array>
    <key>CFBundleURLName</key>
    <string>edu.huit.pdt</string>
  </dict>
</array>
```

### 3.11 FCM Push Notifications

**Step 1 — Firebase setup (one-time):**
```bash
dart pub global activate flutterfire_cli
cd flutter_huit_student
flutterfire configure --project=pdt-huit-firebase
# Generates: android/app/google-services.json
#            ios/Runner/GoogleService-Info.plist
```

**Step 2 — `main.dart`:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
  );
  runApp(const PdtHuitApp());
}
```

**Step 3 — FCM Token Service:**
```dart
// lib/features/notifications/data/fcm_token_service.dart
class FcmTokenService {
  final ApiClient _apiClient;
  final SecureStorage _storage;
  FcmTokenService(this._apiClient, this._storage);

  Future<void> registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final studentId = await _storage.getStudentId();
    if (studentId == null) return;
    await _apiClient.dio.post('/student/notifications/fcm-token', data: {
      'fcmToken': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
  }

  void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => registerToken());
  }
}
```

**Step 4 — FCM handlers in `app.dart`:**
```dart
void _setupFcmHandlers(BuildContext context) {
  // Foreground → in-app banner
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final n = message.notification;
    if (n != null) _showLocalNotification(n.title, n.body);
    context.read<NotificationBloc>().add(RefreshUnreadCount());
  });

  // Background tap → navigate
  FirebaseMessaging.onMessageOpenedApp.listen((msg) =>
      _handleNotificationNavigation(context, msg.data));

  // Cold start
  FirebaseMessaging.instance.getInitialMessage().then((msg) {
    if (msg != null) _handleNotificationNavigation(context, msg.data);
  });
}

void _handleNotificationNavigation(BuildContext ctx, Map<String, dynamic> data) {
  switch (data['type']) {
    case 'QUEUE_CALLED':         ctx.go('/queue');
    case 'REQUEST_UPDATED':
      if (data['refId'] != null) ctx.go('/requests/${data['refId']}');
    case 'APPOINTMENT_REMINDER': ctx.go('/appointments');
  }
}
```

### 3.12 Widget Tests

```dart
// test/features/queue/queue_status_page_test.dart
@GenerateMocks([QueueBloc])
void main() {
  group('QueueStatusPage', () {
    late MockQueueBloc mockBloc;
    setUp(() => mockBloc = MockQueueBloc());

    testWidgets('shows shimmer skeleton while loading', (tester) async {
      whenListen(mockBloc, Stream.value(QueueLoading()),
          initialState: QueueLoading());
      await tester.pumpWidget(_wrap(mockBloc, const QueueStatusPage()));
      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('shows ticket number when CALLING', (tester) async {
      final ticket = QueueTicketModel(
          id: 1, ticketNumber: 42, ticketPrefix: 'A',
          status: 'CALLING', deskName: 'Bàn 1',
          createdAt: DateTime.now());
      whenListen(mockBloc, Stream.value(QueueCalling(ticket: ticket)),
          initialState: QueueCalling(ticket: ticket));
      await tester.pumpWidget(_wrap(mockBloc, const QueueStatusPage()));
      expect(find.text('A42'), findsOneWidget);
    });

    testWidgets('shows full-screen overlay on QueueYourTurn', (tester) async {
      whenListen(mockBloc, Stream.value(QueueYourTurn(ticket: fakeTicket)),
          initialState: QueueYourTurn(ticket: fakeTicket));
      await tester.pumpWidget(_wrap(mockBloc, const QueueStatusPage()));
      await tester.pump();
      expect(find.byKey(const Key('your_turn_overlay')), findsOneWidget);
    });
  });

  group('OfflineBanner', () {
    testWidgets('shows banner when offline', (tester) async {
      final cubit = ConnectivityCubit()..emit(const ConnectivityOffline());
      await tester.pumpWidget(BlocProvider<ConnectivityCubit>.value(
        value: cubit,
        child: const MaterialApp(home: OfflineBanner(child: Scaffold())),
      ));
      expect(find.text('Không có kết nối'), findsOneWidget);
    });

    testWidgets('hides banner when online', (tester) async {
      final cubit = ConnectivityCubit()..emit(const ConnectivityOnline());
      await tester.pumpWidget(BlocProvider<ConnectivityCubit>.value(
        value: cubit,
        child: const MaterialApp(home: OfflineBanner(child: Scaffold())),
      ));
      expect(find.text('Không có kết nối'), findsNothing);
    });
  });
}

Widget _wrap(Bloc bloc, Widget child) =>
    BlocProvider.value(value: bloc, child: MaterialApp(home: child));
```

### ✅ Phase 3 Gate

```bash
cd flutter_huit_student

# 1. Static analysis
flutter analyze
# Expected: 0 errors, 0 warnings

# 2. Unit + widget tests
flutter test --coverage
# Expected: all pass, coverage ≥ 60%

# 3. Release APK build
flutter build apk --release \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081/api \
  --dart-define=WS_URL=http://10.0.2.2:8081
# Expected: build/app/outputs/flutter-apk/app-release.apk created

# 4. Emulator smoke test
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081/api \
  --dart-define=WS_URL=http://10.0.2.2:8081

# Manual checklist on emulator:
# [ ] Login with MSSV "2001215001" / "123456" → home screen with student name
# [ ] Queue status page: shimmer on first load
# [ ] Airplane mode ON → offline banner appears; OFF → banner dismisses
# [ ] FCM token registered (check backend: GET /admin/students/2001215001/devices)
# [ ] WebSocket connects: console shows "[WS] Connected"
# [ ] Trigger callNextTicket via registrar Vue UI → Flutter shows full-screen alert
# [ ] Deep link test:
#     adb shell am start -a android.intent.action.VIEW \
#       -d "huit-pdt://requests/1" com.huit.pdt
#     → opens RequestDetailPage directly

# 5. Physical device
adb reverse tcp:8081 tcp:8081
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081/api \
  --dart-define=WS_URL=http://127.0.0.1:8081

# 6. Mobile → Backend curl verification (from dev machine as proxy)
BASE_EMU="http://10.0.2.2:8081/api"

# Health check reachable from emulator network
adb shell "curl -s $BASE_EMU/../internal/actuator/health 2>/dev/null || echo 'need adb reverse'"

# Student login (what Flutter calls first)
STU_TOKEN=$(curl -s -X POST http://localhost:8081/api/student/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mssv":"2001215001","password":"123456"}' | jq -r '.data.token')
echo "Flutter would get: ${STU_TOKEN:0:20}..."

# Public categories (Flutter home screen)
curl -s http://localhost:8081/api/public/service-categories | jq '{count: (.data | length)}'
# Expected: {count: 3}

# Student requests (Flutter request list)
curl -s http://localhost:8081/api/student/requests \
  -H "Authorization: Bearer $STU_TOKEN" | jq '{success, count: (.data.content | length)}'

# Student notifications (Flutter notification badge)
curl -s http://localhost:8081/api/student/notifications/unread-count \
  -H "Authorization: Bearer $STU_TOKEN" | jq '.data'

# Appointment available slots (Flutter appointment creation)
curl -s "http://localhost:8081/api/student/appointments/available-slots?serviceId=1&date=2026-06-01" \
  -H "Authorization: Bearer $STU_TOKEN" | jq '.success'
```

---

## PHASE 4 — Full E2E Integration Verification

### 4.1 Complete Cross-Layer Connection Map

| Client | Endpoint | Auth | Verify command |
|---|---|---|---|
| Vue /login | `POST /api/auth/login` | None | `curl -X POST …/auth/login` |
| Vue Queue page | `GET /api/registrar/queue/{id}/stats` | Registrar JWT | `curl -H "Bearer …"` |
| Vue Queue WS | `ws://host/ws` STOMP | JWT in CONNECT header | `wscat --header Authorization:…` |
| Vue Dashboard | `GET /api/registrar/dashboard` | Registrar JWT | `curl` |
| Flutter login | `POST /api/student/auth/login` | None | `curl` |
| Flutter categories | `GET /api/public/service-categories` | None | `curl` |
| Flutter requests | `GET /api/student/requests` | Student JWT | `curl -H "Bearer …"` |
| Flutter queue WS | `ws://host/ws` STOMP `/user/{id}/queue/your-turn` | JWT in CONNECT | Flutter debug log |
| Flutter FCM | `POST /api/student/notifications/fcm-token` | Student JWT | `curl` after login |

### 4.2 Full curl End-to-End Checklist

```bash
BASE="http://localhost:8081/api"

# ═══ Get all tokens ═════════════════════════════════════════════════
ADMIN_TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"ADMIN","password":"123456"}' | jq -r '.data.token')
REG_TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"NV001","password":"123456"}' | jq -r '.data.token')
STU_TOKEN=$(curl -s -X POST $BASE/student/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mssv":"2001215001","password":"123456"}' | jq -r '.data.token')

# ═══ Full Queue Flow ══════════════════════════════════════════════════
echo "=== Queue Flow ==="
# Student takes a number
TICKET=$(curl -s -X POST $BASE/student/queue/take \
  -H "Authorization: Bearer $STU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deskId":1}' | jq '.data.ticketNumber')
echo "Student ticket: $TICKET"

# Registrar calls next — must match student's ticket
CALLED=$(curl -s -X POST $BASE/registrar/queue/1/call-next \
  -H "Authorization: Bearer $REG_TOKEN" | jq '.data.ticketNumber')
echo "Called ticket: $CALLED"
[ "$TICKET" = "$CALLED" ] && echo "✅ Correct ticket called" || echo "❌ MISMATCH"

# Registrar marks serving, then completes
curl -s -X PATCH "$BASE/registrar/queue/tickets/$TICKET/serve" \
  -H "Authorization: Bearer $REG_TOKEN" | jq '.success'
curl -s -X PATCH "$BASE/registrar/queue/tickets/$TICKET/complete" \
  -H "Authorization: Bearer $REG_TOKEN" | jq '.success'

# Notification created for student
curl -s "$BASE/student/notifications?page=0&size=1" \
  -H "Authorization: Bearer $STU_TOKEN" | jq '.data.content[0].type'
# Expected: "QUEUE_CALLED"

# ═══ Full Request Flow ════════════════════════════════════════════════
echo "=== Request Flow ==="
REQ_ID=$(curl -s -X POST $BASE/student/requests \
  -H "Authorization: Bearer $STU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"serviceId":1,"note":"Xin cấp bảng điểm"}' | jq '.data.id')
echo "Created request: $REQ_ID"

curl -s -X PATCH "$BASE/registrar/requests/$REQ_ID/process" \
  -H "Authorization: Bearer $REG_TOKEN" | jq '.data.currentPhase'
# Expected: 3

curl -s -X PATCH "$BASE/registrar/requests/$REQ_ID/complete" \
  -H "Authorization: Bearer $REG_TOKEN" | jq '.data.currentPhase'
# Expected: 4

# ═══ Full Appointment Flow ════════════════════════════════════════════
echo "=== Appointment Flow ==="
APPT_ID=$(curl -s -X POST $BASE/student/appointments \
  -H "Authorization: Bearer $STU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"requestId":1,"registrarId":1,"appointmentDate":"2026-06-10","appointmentTime":"10:00"}' \
  | jq '.data.id')
echo "Appointment: $APPT_ID"

# Second attempt at SAME slot must return 409
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE/student/appointments \
  -H "Authorization: Bearer $STU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"requestId":2,"registrarId":1,"appointmentDate":"2026-06-10","appointmentTime":"10:00"}')
[ "$HTTP" = "409" ] && echo "✅ Double-booking blocked" || echo "❌ FAIL: $HTTP"

# ═══ Security Checks ══════════════════════════════════════════════════
echo "=== Security ==="
# Student cannot access registrar dashboard
HTTP=$(curl -s -o /dev/null -w "%{http_code}" $BASE/registrar/dashboard \
  -H "Authorization: Bearer $STU_TOKEN")
[ "$HTTP" = "403" ] && echo "✅ Role separation" || echo "❌ FAIL: $HTTP"

# Unauthenticated student route → 401
[ "$(curl -s -o /dev/null -w '%{http_code}' $BASE/student/profile)" = "401" ] \
  && echo "✅ Unauthenticated blocked"

# Rate limiting: 5x401 then 429
for i in {1..7}; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE/auth/login \
    -H "Content-Type: application/json" -d '{"username":"x","password":"x"}')
  [ $i -le 5 ] && EXP="401" || EXP="429"
  [ "$HTTP" = "$EXP" ] && echo "✅ Attempt $i: $HTTP" || echo "❌ Attempt $i: $HTTP"
done

# Refresh token then revoke
REFRESH=$(curl -s -X POST $BASE/auth/login -H "Content-Type: application/json" \
  -d '{"username":"ADMIN","password":"123456"}' | jq -r '.data.refreshToken')
NEW=$(curl -s -X POST $BASE/auth/refresh -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}" | jq -r '.data.token')
[ -n "$NEW" ] && echo "✅ Refresh OK"
curl -s -X POST $BASE/auth/logout -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}" | jq '.success'
[ "$(curl -s -o /dev/null -w '%{http_code}' -X POST $BASE/auth/refresh \
  -H 'Content-Type: application/json' -d "{\"refreshToken\":\"$REFRESH\"}")" = "401" ] \
  && echo "✅ Revoked token rejected"

# ═══ Dashboard / Reports ══════════════════════════════════════════════
echo "=== Dashboard ==="
curl -s "$BASE/admin/reports/service-usage?from=2026-01-01&to=2026-12-31" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '{success, count: (.data | length)}'
curl -s "$BASE/admin/reports/registrar-performance?from=2026-01-01&to=2026-12-31" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.success'
curl -s "$BASE/registrar/dashboard/daily-stats" \
  -H "Authorization: Bearer $REG_TOKEN" | jq '{success}'

# ═══ WebSocket Auth ═══════════════════════════════════════════════════
echo "=== WebSocket ==="
wscat -c "ws://localhost:8081/ws/websocket" \
  --header "Authorization: Bearer $REG_TOKEN" && echo "✅ WS auth accepted"
wscat -c "ws://localhost:8081/ws/websocket" 2>&1 | grep -qi "unauthorized\|401\|403" \
  && echo "✅ WS rejects unauthenticated"

echo "=== All Phase 4 checks done ==="
```

### 4.3 Concurrent Load Test

```bash
# 20 simultaneous queue call-next requests — only 1 must win
for i in {1..20}; do
  curl -s -X POST $BASE/registrar/queue/1/call-next \
    -H "Authorization: Bearer $REG_TOKEN" &
done
wait
echo "Check DB: SELECT COUNT(*) FROM queue_tickets WHERE status='CALLING' AND DATE(created_at)=CURRENT_DATE;"
# Expected: exactly 1
```

---

## PHASE 5 — CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, 'refactor/**']
  pull_request:
    branches: [main]

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_DB: pdt_test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-retries 5
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - name: Cache Maven
        uses: actions/cache@v4
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
      - name: Run backend tests
        working-directory: backend
        run: ./mvnw verify -Dspring.profiles.active=test
        env:
          JWT_SECRET: test-secret-at-least-32-chars-long!!

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm', cache-dependency-path: AdminStaff/package-lock.json }
      - name: Install, test, build
        working-directory: AdminStaff
        run: |
          npm ci
          npm run test:coverage
          npm run build

  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.0', channel: 'stable' }
      - name: Flutter test + build
        working-directory: flutter_huit_student
        run: |
          flutter pub get
          flutter analyze
          flutter test
          flutter build apk --release \
            --dart-define=API_BASE_URL=https://api.huit-pdt.edu.vn/api \
            --dart-define=WS_URL=https://api.huit-pdt.edu.vn
```

---

## Final Quality Gate Summary

| Check | Command | Expected |
|---|---|---|
| Backend tests | `./mvnw verify` | BUILD SUCCESS |
| Race condition queue ×100 | In test suite | 0 failures |
| Race condition appointment ×50 | In test suite | 0 failures |
| `/api/student/**` unauthenticated | `curl …/student/profile` | 401 |
| Rate limiting | 7× failed logins | 5× 401, 2× 429 |
| Refresh token | `POST /auth/refresh` | New JWT returned |
| Revoked token | `POST /auth/refresh` with old | 401 |
| Actuator `/metrics` | `curl /actuator/metrics` | 404 |
| WS JWT auth | `wscat` without token | 401/rejected |
| Vue build | `npm run build` | 0 errors, chunks < 500KB |
| Vue tests | `npm run test:coverage` | ≥70% coverage |
| Flutter analysis | `flutter analyze` | 0 errors |
| Flutter tests | `flutter test` | All pass |
| Flutter APK | `flutter build apk --release` | BUILD SUCCESS |
| CI pipeline | Push to branch | All 3 jobs green |
| Flyway | App startup log | "Successfully applied N migrations" |
| Queue display board | Browser + Flutter simultaneously | Both update on call-next |
| Double-booking | 2nd appointment same slot | 409 |
| Offline banner | Flutter + airplane mode | Banner appears instantly |
| Deep link | `adb shell am start -d "huit-pdt://requests/1"` | Opens RequestDetailPage |

---

*Plan v4.1 — Final. All 30 gaps from Layer 1+2+3 review resolved. Source-verified against actual repository state. Ready for agent execution.*
Đây là Phụ lục bổ sung — viết sẵn để paste vào cuối plan v4.1.

APPENDIX A — Pre-Execute Fixes (5 items)
Apply all 5 fixes before running Phase 0. Each fix is self-contained and non-breaking.

FIX-01 · V10 Flyway Migration — CONCURRENTLY inside Transaction
Problem: Flyway wraps every migration in a transaction by default. PostgreSQL forbids CREATE INDEX CONCURRENTLY inside any transaction — it will throw ERROR: CREATE INDEX CONCURRENTLY cannot run inside a transaction block and Flyway will mark V10 as failed, permanently poisoning the flyway_schema_history table.

Fix: Add the -- flyway:noTransaction hint as the very first line of the file. Flyway reads this comment before executing and skips the transaction wrapper for this migration only.

sql
-- V10__add_performance_indexes.sql
-- flyway:noTransaction

CREATE INDEX CONCURRENTLY idx_request_student_phase
    ON request(student_id, current_phase, created_at DESC);

CREATE INDEX CONCURRENTLY idx_request_history_request
    ON request_history(request_id, created_at DESC);

CREATE INDEX CONCURRENTLY idx_appointment_registrar_date
    ON appointment(registrar_id, appointment_date, status);

CREATE INDEX CONCURRENTLY idx_student_feedback_student
    ON student_feedback(student_id, status, created_at DESC);

CREATE INDEX CONCURRENTLY idx_report_student
    ON report(student_id, status, created_at DESC);

CREATE INDEX CONCURRENTLY idx_reply_report
    ON reply(report_id, created_at ASC);
Verify after migration:

bash
psql -U $DB_USER -d $DB_NAME -c "
SELECT indexname, tablename
FROM pg_indexes
WHERE indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
"
# Expected: 6 rows with the above index names
FIX-02 · Flutter main.dart — Hive Initialization
Problem: pubspec.yaml includes hive_flutter and hive packages. The cache-first BLoC implementations (§3.9) open Hive boxes via Hive.box('request_cache'). If Hive.initFlutter() is never called, every Hive.box() call throws HiveError: You need to initialize Hive — app crashes on first launch before any screen renders.

Fix: main.dart must be async and initialize all boxes before runApp. Register any custom TypeAdapter here as well.

dart
// flutter_huit_student/lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Hive — must come before any BLoC that reads cache
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>('request_cache'),
    Hive.openBox<String>('appointment_cache'),
    Hive.openBox<String>('notification_cache'),
    Hive.openBox<String>('queue_cache'),
  ]);

  // 2. Firebase — wrapped in try/catch so widget tests don't fail
  //    (google-services.json absent in CI → see FIX-CI below)
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Firebase not available in test/CI environment — FCM will no-op
  }

  runApp(const PdtHuitApp());
}
Verify:

bash
cd flutter_huit_student
flutter run --debug
# Expected: no HiveError in console, app reaches LoginScreen
flutter test test/widget/login_screen_test.dart
# Expected: all tests pass without HiveError
FIX-03 · getDailyStats() — Remove SELECT *
Problem: ReportRepositoryImpl.getDailyStats() calls SELECT * FROM vw_daily_stats. This violates the plan's own SQL standard ("No SELECT *, all list queries paginated, all FK columns indexed") and is also brittle — if the VIEW schema changes, DailyStatsRowMapper silently maps wrong columns.

Fix:

java
// domain/report/repository/impl/ReportRepositoryImpl.java

@Override
public DailyStatsDTO getDailyStats() {
    String sql = """
        SELECT
            total_active,
            waiting,
            pending,
            processing,
            completed,
            cancelled
        FROM vw_daily_stats
        """;
    return jdbc.queryForObject(sql, Map.of(), new DailyStatsRowMapper());
}

// infrastructure/persistence/rowmapper/DailyStatsRowMapper.java
public class DailyStatsRowMapper implements RowMapper<DailyStatsDTO> {
    @Override
    public DailyStatsDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new DailyStatsDTO(
            rs.getLong("total_active"),
            rs.getLong("waiting"),
            rs.getLong("pending"),
            rs.getLong("processing"),
            rs.getLong("completed"),
            rs.getLong("cancelled")
        );
    }
}
Verify:

bash
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8081/api/admin/dashboard/daily-stats | jq '.'
# Expected:
# {
#   "success": true,
#   "data": {
#     "totalActive": 0,
#     "waiting": 0,
#     "pending": 0,
#     "processing": 0,
#     "completed": 0,
#     "cancelled": 0
#   }
# }
FIX-04 · RateLimitFilter — In-Memory Caveat & Scale-Out Path
Problem: The ConcurrentHashMap<String, Bucket> in RateLimitFilter is JVM-local. On restart all rate limit counters reset (a single client could exhaust the limit, restart the process, and immediately get a full bucket again). On multi-instance deployment (2+ pods behind a load balancer), each pod keeps its own map — a client can send N × limit requests before being blocked.

Current implementation is acceptable for single-node deployment. Document the limitation and the upgrade path explicitly.

java
// infrastructure/ratelimit/RateLimitFilter.java

/**
 * Rate limiting via Bucket4j token bucket algorithm.
 *
 * CURRENT STORAGE: ConcurrentHashMap (JVM-local, in-memory)
 *   ✅ Correct for single-node / single-pod deployment
 *   ✅ No external dependency, zero latency overhead
 *   ⚠️  Counters reset on process restart
 *   ❌ NOT suitable for multi-instance / horizontal scaling
 *
 * SCALE-OUT UPGRADE PATH (when adding second pod):
 *   1. Add dependency: bucket4j-redis (com.bucket4j:bucket4j-redis:8.x)
 *   2. Replace ConcurrentHashMap with:
 *        ProxyManager<String> proxyManager =
 *            Bucket4jRedis.casBasedBuilder(redissonClient).build();
 *   3. Each request calls:
 *        Bucket bucket = proxyManager.builder()
 *            .addLimit(limit -> limit.capacity(60)
 *                .refillGreedy(60, Duration.ofMinutes(1)))
 *            .build(clientIp);
 *   Bucket state is stored in Redis — all pods share the same counters.
 */
@Component
@Order(1)
@RequiredArgsConstructor
public class RateLimitFilter extends OncePerRequestFilter {

    // JVM-local storage — see Javadoc above for scale-out path
    private final ConcurrentHashMap<String, Bucket> buckets =
        new ConcurrentHashMap<>();

    private Bucket resolveBucket(String clientIp) {
        return buckets.computeIfAbsent(clientIp, k ->
            Bucket.builder()
                .addLimit(limit -> limit
                    .capacity(60)
                    .refillGreedy(60, Duration.ofMinutes(1)))
                .build());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {

        String clientIp = Optional
            .ofNullable(request.getHeader("X-Forwarded-For"))
            .map(h -> h.split(",")[0].trim())
            .orElse(request.getRemoteAddr());

        Bucket bucket = resolveBucket(clientIp);

        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(429);
            response.setContentType("application/json");
            response.getWriter().write("""
                {"success":false,"message":"Too many requests",
                 "errorCode":"RATE_LIMITED","data":null}
                """);
        }
    }
}
Verify:

bash
# Confirm rate limit fires after 60 requests per minute
for i in $(seq 1 62); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    http://localhost:8081/api/public/services)
  echo "Request $i: $CODE"
done
# Expected: requests 1-60 → 200, request 61+ → 429
FIX-05 · Flutter Test _wrap Helper — MultiBlocProvider
Problem: The test helper in §3.12 has signature Widget _wrap(Bloc bloc, Widget child). Several screens require more than one BLoC — for example, QueueStatusScreen needs both QueueBloc and ConnectivityCubit, and RequestListScreen needs RequestBloc plus NotificationBloc. The single-BLoC helper forces test authors to either nest _wrap calls (creating duplicate MaterialApp wrappers that break routing) or skip needed providers (causing BlocProvider.of to throw at runtime inside tests).

Fix: Replace with a MultiBlocProvider-based helper in test/helpers/test_helpers.dart:

dart
// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Wraps [child] with all required BLoC providers for widget testing.
/// Pass only the providers the widget under test actually needs.
///
/// Usage:
///   testWidgets('shows queue number', (tester) async {
///     await tester.pumpWidget(_wrap(
///       providers: [
///         BlocProvider<QueueBloc>.value(value: mockQueueBloc),
///         BlocProvider<ConnectivityCubit>.value(value: mockConnectivity),
///       ],
///       child: const QueueStatusScreen(),
///     ));
///   });
Widget _wrap({
  required List<BlocProvider> providers,
  required Widget child,
  GoRouter? router,
}) {
  return MultiBlocProvider(
    providers: providers,
    child: MaterialApp(
      // Vietnamese locale — matches production app
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

/// Convenience builder for the most common combination:
/// QueueBloc + ConnectivityCubit (used in 4 screens).
Widget _wrapQueueScreen({
  required MockQueueBloc queueBloc,
  required MockConnectivityCubit connectivity,
  required Widget child,
}) {
  return _wrap(
    providers: [
      BlocProvider<QueueBloc>.value(value: queueBloc),
      BlocProvider<ConnectivityCubit>.value(value: connectivity),
    ],
    child: child,
  );
}
Update existing test in §3.12 to use the new signature:

dart
// test/widget/queue_status_screen_test.dart  (updated)
testWidgets('shows ticket number A042 after QueueCalledState', (tester) async {
  when(() => mockQueueBloc.state)
      .thenReturn(QueueCalledState(ticketPrefix: 'A', ticketNumber: 42));
  when(() => mockConnectivity.state).thenReturn(ConnectedState());

  await tester.pumpWidget(_wrap(
    providers: [
      BlocProvider<QueueBloc>.value(value: mockQueueBloc),
      BlocProvider<ConnectivityCubit>.value(value: mockConnectivity),
    ],
    child: const QueueStatusScreen(),
  ));

  expect(find.text('A042'), findsOneWidget);
  expect(find.text('Đến lượt của bạn!'), findsOneWidget);
});
Verify:

bash
cd flutter_huit_student
flutter test test/widget/ --reporter=expanded
# Expected: all widget tests pass, no BlocProvider.of() exceptions
APPENDIX B — Informational Notes
NOTE-CI · GitHub Actions — Flutter Build with Firebase
Context: FlutterFire requires google-services.json (Android) and GoogleService-Info.plist (iOS) to exist at build time. These files contain API keys and must never be committed to the repo.

Fix for CI/CD:

text
# .github/workflows/flutter.yml  (add this step before flutter build)
- name: Create Firebase config for CI
  env:
    GOOGLE_SERVICES_JSON: ${{ secrets.GOOGLE_SERVICES_JSON }}
  run: |
    echo "$GOOGLE_SERVICES_JSON" > \
      flutter_huit_student/android/app/google-services.json

# Store the real google-services.json content as a GitHub Secret:
# Settings → Secrets → Actions → New repository secret
# Name: GOOGLE_SERVICES_JSON
# Value: (paste entire contents of google-services.json)
For widget tests that don't need Firebase at all, add a conditional init guard in main.dart (already present in FIX-02 above via try/catch). This means flutter test runs without the JSON file — only flutter build and integration tests require it.

dart
// Already in FIX-02 — repeated here for clarity
try {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
} catch (_) {
  // Silently skip in test / CI environments
}
Full CI job:

text
flutter-test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with: { flutter-version: '3.22.0' }
    - name: Install dependencies
      run: cd flutter_huit_student && flutter pub get
    - name: Analyze
      run: cd flutter_huit_student && flutter analyze
    - name: Widget tests (no Firebase needed)
      run: cd flutter_huit_student && flutter test test/widget/
    - name: Create Firebase config
      env:
        GOOGLE_SERVICES_JSON: ${{ secrets.GOOGLE_SERVICES_JSON }}
      run: |
        echo "$GOOGLE_SERVICES_JSON" > \
          flutter_huit_student/android/app/google-services.json
    - name: Build APK (Firebase required)
      run: |
        cd flutter_huit_student
        flutter build apk --release --no-tree-shake-icons
NOTE-RBAC · Admin-Only Report Endpoints — Registrar 403 Verification
Context: SecurityConfig guards /api/admin/** with hasRole('Admin'). The report endpoints live at /api/admin/dashboard/** and /api/admin/reports/**. The question is: does a Registrar JWT get a 403 on these paths?

Add these curls to Phase 4 E2E test suite (after existing curl battery):

bash
# ── RBAC boundary: Registrar must NOT access admin reports ──────────────
echo "--- RBAC: Registrar blocked from admin reports ---"

# Step 1: Get a REGISTRAR-role JWT (not Admin)
REGISTRAR_TOKEN=$(curl -s -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"registrar01","password":"registrar_pass"}' \
  | jq -r '.data.accessToken')
echo "Registrar token acquired: ${REGISTRAR_TOKEN:0:20}..."

# Step 2: Verify registrar CAN access their own endpoints → 200
curl -s -o /dev/null -w "Registrar /api/registrar/queue: %{http_code}\n" \
  -H "Authorization: Bearer $REGISTRAR_TOKEN" \
  http://localhost:8081/api/registrar/queue/desks

# Step 3: Verify registrar CANNOT access admin endpoints → 403
curl -s -o /dev/null -w "Registrar /api/admin/dashboard: %{http_code}\n" \
  -H "Authorization: Bearer $REGISTRAR_TOKEN" \
  http://localhost:8081/api/admin/dashboard/daily-stats

curl -s -o /dev/null -w "Registrar /api/admin/reports/usage: %{http_code}\n" \
  -H "Authorization: Bearer $REGISTRAR_TOKEN" \
  "http://localhost:8081/api/admin/reports/usage?from=2026-01-01&to=2026-05-04"

curl -s -o /dev/null -w "Registrar /api/admin/reports/performance: %{http_code}\n" \
  -H "Authorization: Bearer $REGISTRAR_TOKEN" \
  "http://localhost:8081/api/admin/reports/performance?from=2026-01-01&to=2026-05-04"

curl -s -o /dev/null -w "Registrar /api/admin/users: %{http_code}\n" \
  -H "Authorization: Bearer $REGISTRAR_TOKEN" \
  http://localhost:8081/api/admin/users

# Step 4: Verify unauthenticated request → 401
curl -s -o /dev/null -w "Unauthenticated /api/admin/dashboard: %{http_code}\n" \
  http://localhost:8081/api/admin/dashboard/daily-stats

# ── Expected results ─────────────────────────────────────────────────────
# Registrar /api/registrar/queue:       200  ← allowed
# Registrar /api/admin/dashboard:       403  ← blocked ✅
# Registrar /api/admin/reports/usage:   403  ← blocked ✅
# Registrar /api/admin/reports/perf:    403  ← blocked ✅
# Registrar /api/admin/users:           403  ← blocked ✅
# Unauthenticated /api/admin/dashboard: 401  ← no token = unauthorized
Also verify the error response shape is correct (must return ApiResponse, not Spring default error):

bash
curl -s \
  -H "Authorization: Bearer $REGISTRAR_TOKEN" \
  http://localhost:8081/api/admin/dashboard/daily-stats | jq '.'
# Expected:
# {
#   "success": false,
#   "message": "Access denied",
#   "errorCode": "FORBIDDEN",
#   "data": null,
#   "timestamp": "2026-05-04T15:00:00"
# }
# NOT Spring's default {"status":403,"error":"Forbidden","path":...}
If the shape is wrong, confirm GlobalExceptionHandler has @ExceptionHandler(AccessDeniedException.class) — this is present in §1.15.

End of Appendix A + B — paste after Phase 4 in plan v4.1

Prepared using Claude Sonnet 4.6 Thinking

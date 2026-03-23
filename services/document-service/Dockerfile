FROM gradle:8.5-jdk21 AS builder
WORKDIR /build
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon 2>/dev/null || true
COPY src src
RUN gradle bootJar --no-daemon -x test

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S skep && adduser -S skep -G skep
COPY --from=builder /build/build/libs/*.jar app.jar
RUN chown skep:skep app.jar
USER skep
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8082/actuator/health || exit 1
EXPOSE 8082
ENTRYPOINT ["java", "-Xmx512m", "-XX:+UseG1GC", "-jar", "app.jar"]

# Build stage
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Download dependencies
RUN ./mvnw dependency:go-offline

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Environment variables (will be overridden by docker-compose)
ENV SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/hanhchinhcong
ENV SPRING_DATASOURCE_USERNAME=postgres
ENV SPRING_DATASOURCE_PASSWORD=postgres

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]

# ---- Stage 1: build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Dependencias primero para aprovechar la caché de capas.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline || true

COPY src ./src
RUN mvn -B -DskipTests package

# ---- Stage 2: runtime ----
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

COPY --from=build /app/target/sgiu-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 3000

# Dentro del contenedor (Linux) Launcher asume BD externa y arranca Spring en :3000.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
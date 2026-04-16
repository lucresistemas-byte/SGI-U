# Usamos una imagen de Java ya lista
FROM eclipse-temurin:21-jre-alpine

# Definimos dónde vivirá la app dentro de Docker
WORKDIR /app

# Copiamos el JAR que acabamos de generar
# Nota: Ajusta el nombre si tu JAR se llama distinto
COPY sgiu/target/*.jar app.jar

# Abrimos el puerto de Spring
EXPOSE 8080

# Comando para iniciar
ENTRYPOINT ["java", "-jar", "app.jar"]
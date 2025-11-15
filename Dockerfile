FROM openjdk:17-jdk-slim
COPY target/no-db-springboot-app-1.0.0.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]

FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN ./mvnw -B -q dependency:go-offline
COPY src src
RUN ./mvnw -B -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --system --uid 1001 sruu
COPY --from=build /src/target/sruu-backend-*.jar app.jar
USER sruu
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

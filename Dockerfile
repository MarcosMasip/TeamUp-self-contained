## Backend multi-stage Dockerfile
FROM eclipse-temurin:8-jdk AS build
WORKDIR /workspace
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw -q dependency:go-offline
COPY src src
RUN ./mvnw -q -DskipTests package && ls -l target

FROM eclipse-temurin:8-jre AS runtime
WORKDIR /app
ENV JAVA_OPTS=""
COPY --from=build /workspace/target/teamUp.jar app.jar
COPY src/main/resources/teamup.p12 teamup.p12
EXPOSE 8443
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]


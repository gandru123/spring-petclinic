FROM maven:3.9.11-eclipse-temurin-17-alpine AS build
RUN apk add --no-cache git
ADD . /JAVA
WORKDIR /JAVA
RUN mvn package



FROM eclipse-temurin:17-jre-alpine AS run
ARG myownuser=gandru
ENV APP_ENV=prod
RUN adduser -D -h /usr/share/gandru -s /bin/sh ${myownuser}
USER ${myownuser}
WORKDIR /spring
COPY --from=build /JAVA/target/*.jar /spring/paru.jar
EXPOSE 8080/tcp
CMD ["java","-jar","paru.jar"]

#FROM openjdk:17
#COPY spring-petclinic-3.5.0-SNAPSHOT.jar app.jar
#EXPOSE 8080
#CMD ["java", "-jar", "app.jar"]



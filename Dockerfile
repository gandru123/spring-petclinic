FROM maven:3.9.11-eclipse-temurin-17-alpine AS build
#RUN apk add --no-cache git
ADD . /JAVA
WORKDIR /JAVA
RUN mvn package



FROM eclipse-temurin:17-jre-alpine AS run
RUN adduser -D -h  /usr/share/devops -s /bin/sh devops
USER devops
WORKDIR /spring
COPY --from=build /JAVA/target/*.jar /spring/paru.jar
EXPOSE 8080/tcp
CMD ["java","-jar","paru.jar"]




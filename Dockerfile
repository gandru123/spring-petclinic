FROM maven:3.9.11-eclipse-temurin-17-alpine AS build
RUN apk add --no-cache git 
RUN git clone https://github.com/gandru123/spring-petclinic.git && \
    cd spring-petclinic && \
    mvn package
FROM openjdk:25-ea-17-jdk AS run
RUN adduser -D -h /usr/share/multistage -s /bin/bash dockerfile
USER dockerfile
WORKDIR /usr/share/multistage
COPY --from=build/target/*.jar app.jar
EXPOSE 8080/tcp
CMD ["java","-jar","app.jar"]




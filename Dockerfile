FROM maven:3.9.11-eclipse-temurin-17-alpine AS build
#RUN apk add --no-cache git
RUN git clone https://github.com/gandru123/spring-petclinic.git && \
    cd spring-petclinic && \
    mvn package



FROM eclipse-temurin:17-jre-alpine AS run
RUN adduser -D -h /usr/share/multistage -s /bin/sh paruu
USER paruu
WORKDIR /usr/share/multistage
COPY --from=build /spring-petclinic/target/*.jar app.jar
EXPOSE 8080/tcp
CMD ["java","-jar","app.jar"]




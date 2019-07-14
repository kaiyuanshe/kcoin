FROM maven:3.5-jdk-8-alpine as build
ADD . /app
WORKDIR /app
ADD ./src/main/resources/configs.properties.docker ./src/main/resources/configs.properties
RUN mvn install

FROM tomcat:8.5-alpine
RUN apk add libc6-compat
COPY --from=build /app/target/kcoin.war /usr/local/tomcat/webapps/

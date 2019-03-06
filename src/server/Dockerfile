FROM maven:3.5-jdk-8-alpine as build
ADD . /app
WORKDIR /app
RUN mvn install

FROM tomcat:8.5-alpine
COPY --from=build /app/target/kcoin.war /usr/local/tomcat/webapps/

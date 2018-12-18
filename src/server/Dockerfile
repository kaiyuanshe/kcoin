FROM maven AS build
ADD . /src
RUN mvn package -f /src

FROM tomcat:8-alpine
COPY --from=build /src/target/dist /usr/local/tomcat/webapps/

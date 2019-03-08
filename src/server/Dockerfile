FROM maven:3.5-jdk-8-alpine as build
ADD . /app
WORKDIR /app
COPY ./fabric ./src/main/resources/fabric
RUN mvn install

FROM tomcat:8.5-alpine
ENV fabricAdminPrivateKeyFileName=4ad015b1-db94-ab28-b027-161c5b83376f_sk
COPY --from=build /app/target/kcoin.war /usr/local/tomcat/webapps/

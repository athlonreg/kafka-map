#
# Build stage
#
FROM node:16 AS front-build

WORKDIR /app

COPY web .

RUN yarn config set registry https://registry.npmmirror.com/ --global
RUN yarn && yarn build

FROM maven:3.8.7-amazoncorretto-17 AS build

WORKDIR /app

COPY src src
COPY pom.xml pom.xml
COPY settings.xml /usr/share/maven/conf/settings.xml
COPY LICENSE LICENSE
COPY --from=front-build /app/dist src/main/resources/static

RUN mvn -f pom.xml clean package -Dmaven.test.skip=true

#
# Package stage
#
FROM amazoncorretto:17-alpine

ENV SERVER_PORT 8080
ENV DEFAULT_USERNAME admin
ENV DEFAULT_PASSWORD admin

WORKDIR /usr/local/kafka-map

COPY --from=build /app/target/*.jar kafka-map.jar
COPY --from=build /app/LICENSE LICENSE

EXPOSE $SERVER_PORT

ENTRYPOINT ["/usr/bin/java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/usr/local/kafka-map/kafka-map.jar", "--server.port=${SERVER_PORT}", "--default.username=${DEFAULT_USERNAME}", "--default.password=${DEFAULT_PASSWORD}"]
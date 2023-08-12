FROM maven:3.8.3-openjdk-17-slim

RUN apt-get update && \
    apt-get install -y openjdk-17-jdk

ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

WORKDIR /app

COPY ./consumer /app/

CMD mvn package && java -jar ./target/consumer-0.0.1-SNAPSHOT.jar

FROM ubuntu:latest

## Dont insert anything here
## this lines will get updated while executing ./kafka-start.sh script

RUN apt-get update && apt-get -y upgrade \
	&& apt-get install -y --no-install-recommends curl python3 curl openssl openjdk-8-jre-headless \
	&& rm -rf /var/lib/apt/lists/*

ADD ./kafka kafka
ADD ./createCerts.sh createCerts.sh
ADD ./docker-entrypoint.sh docker-entrypoint.sh 
ENTRYPOINT [ "/docker-entrypoint.sh" ]
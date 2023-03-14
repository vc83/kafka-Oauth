# Docker KAFKA OAuth2

This will help you quickly spin up a OAuth2 enabled Kafka instance with version 2.13-3.0.0

## How to

Basic commands

### Start the server
Export following varibles before running the script.

```bash
export BrokerClientId= \
BrokerClientSecret= \
ConsumerClientId= \
ConsumerClientSecret= \
ProducerClientId= \
ProducerClientSecret= \
ServerURL=
```

```bash
 ./kafka-start.sh
```

This script will create the OAuth2 configuration, ssl certificates and start kafka instance with one broker in docker container. whic can be access on localhost:9092. This will create topic ```test``` , with Create and Write permission for producer client Id. Consumer client Id will have consumer permission on ```oauth2-consumer-group```. 

Required certificates for SSL connection will get downloaded to kafkaCerts in current working diretory.

### Stop the server

```bash
./kafka-stop.sh
```

This script will stop and remove the container.
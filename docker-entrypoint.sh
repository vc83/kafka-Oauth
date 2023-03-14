#!/usr/bin/env bash

function exit_with_error {
    printf '\n%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function fail_by_rc {
  echo -e "Executing '$*'\n"
  "$@"
  rc=$?
  if [ ${rc} -ne 0 ]; then
      exit_with_error "Failed to execute cmd " $rc
  fi
}


fail_by_rc ./createCerts.sh
fail_by_rc /kafka/bin/zookeeper-server-start.sh -daemon /kafka/config/zookeeper.properties
sleep 2
fail_by_rc /kafka/bin/kafka-server-start.sh -daemon  /kafka/config/server.properties 
sleep 2

#  give create and write permission to producer
fail_by_rc /kafka/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --zk-tls-config-file /kafka/config/zookeeper-client.properties --add --allow-principal User:$ProducerClientId --operation Create --operation WRITE --operation Describe  --topic test

# create topic 
fail_by_rc /kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092  --command-config /kafka/config/producer.properties --replication-factor 1 --partitions 1 --topic test

#  give consume + consumer grp permission to consumer
fail_by_rc /kafka/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --zk-tls-config-file /kafka/config/zookeeper-client.properties --add --allow-principal User:$ConsumerClientId --topic test --consumer --group oauth2-consumer-group

fail_by_rc tail -f /kafka/logs/server.log
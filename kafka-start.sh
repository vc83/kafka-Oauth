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

function check_env_var_arr() {
  for val in "$@"; do
    if [[ -z "${!val}" ]]; then
      echo "Error: Environment variable is not set ${val}"
      exit 1
    fi
  done
}

function delete_from_file() {
  if [[ $1 -ne "0"  ]]; then
    echo "Deleting properties after line $1 from $2"
    sed -i $1',$d' $2
  fi
}

envVarArray=("ServerURL" "BrokerClientId" "BrokerClientSecret" "ProducerClientId" "ProducerClientSecret" "ConsumerClientId" "ConsumerClientSecret")
check_env_var_arr "${envVarArray[@]}"

fail_by_rc sed -i "3s/.*/ENV ConsumerClientId $ConsumerClientId/" ./Dockerfile
fail_by_rc sed -i "4s/.*/ENV ProducerClientId $ProducerClientId/" ./Dockerfile

BrokerEncodedVal=$(echo -n "$BrokerClientId:$BrokerClientSecret" | base64 | tr -d '\n')
BROKER_OAUTH_AUTHORIZATION="Basic%20${BrokerEncodedVal}"

BrokerOauthData=$(cat <<EOF
##################### auto generated thorugh shell script #####################
super.users=User:${BrokerClientId}
listener.name.sasl_ssl.oauthbearer.sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required OAUTH_LOGIN_SERVER=${ServerURL} OAUTH_LOGIN_ENDPOINT='/oauth2/default/v1/token' OAUTH_LOGIN_GRANT_TYPE=client_credentials OAUTH_LOGIN_SCOPE=kafka OAUTH_AUTHORIZATION='${BROKER_OAUTH_AUTHORIZATION}' OAUTH_INTROSPECT_SERVER=${ServerURL} OAUTH_INTROSPECT_ENDPOINT='/oauth2/default/v1/introspect' OAUTH_INTROSPECT_AUTHORIZATION='${BROKER_OAUTH_AUTHORIZATION}' unsecuredLoginStringClaim_sub="${BrokerClientId}";
EOF
)
#echo -e "$BrokerOauthData" 
line=$(awk '/auto generated thorugh shell script/{ print NR; exit }' $PWD/kafka/config/server.properties)
delete_from_file $line $PWD/kafka/config/server.properties
echo -e "$BrokerOauthData" | cat >> $PWD/kafka/config/server.properties


ProducerEncodedVal=$(echo -n "$ProducerClientId:$ProducerClientSecret" | base64 | tr -d '\n')
PRODUCER_OAUTH_AUTHORIZATION="Basic%20${ProducerEncodedVal}"

ProducerOauthData=$(cat <<EOF
##################### auto generated thorugh shell script #####################
sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required OAUTH_LOGIN_SERVER=${ServerURL} OAUTH_LOGIN_ENDPOINT='/oauth2/default/v1/token' OAUTH_LOGIN_GRANT_TYPE=client_credentials OAUTH_LOGIN_SCOPE=kafka OAUTH_AUTHORIZATION='${PRODUCER_OAUTH_AUTHORIZATION}' OAUTH_INTROSPECT_SERVER=${ServerURL} OAUTH_INTROSPECT_ENDPOINT='/oauth2/default/v1/introspect' OAUTH_INTROSPECT_AUTHORIZATION='${PRODUCER_OAUTH_AUTHORIZATION}' unsecuredLoginStringClaim_sub="${ProducerClientId}";
EOF
)
#echo -e "$ProducerOauthData" 
line=$(awk '/auto generated thorugh shell script/{ print NR; exit }' $PWD/kafka/config/producer.properties)
delete_from_file $line $PWD/kafka/config/producer.properties
echo -e "$ProducerOauthData" | cat >> $PWD/kafka/config/producer.properties


ConsumerEncodedVal=$(echo -n "$ConsumerClientId:$ConsumerClientSecret" | base64 | tr -d '\n')
CONSUMER_OAUTH_AUTHORIZATION="Basic%20${ConsumerEncodedVal}"

ConsumerOauthData=$(cat <<EOF
##################### auto generated thorugh shell script #####################
sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required OAUTH_LOGIN_SERVER=${ServerURL} OAUTH_LOGIN_ENDPOINT='/oauth2/default/v1/token' OAUTH_LOGIN_GRANT_TYPE=client_credentials OAUTH_LOGIN_SCOPE=kafka OAUTH_AUTHORIZATION='${CONSUMER_OAUTH_AUTHORIZATION}' OAUTH_INTROSPECT_SERVER=${ServerURL} OAUTH_INTROSPECT_ENDPOINT='/oauth2/default/v1/introspect' OAUTH_INTROSPECT_AUTHORIZATION='${CONSUMER_OAUTH_AUTHORIZATION}' unsecuredLoginStringClaim_sub="${ConsumerClientId}";
EOF
)
#echo -e "$ConsumerOauthData"
line=$(awk '/auto generated thorugh shell script/{ print NR; exit }' $PWD/kafka/config/consumer.properties)
delete_from_file $line $PWD/kafka/config/consumer.properties
echo -e "$ConsumerOauthData" | cat >> $PWD/kafka/config/consumer.properties

fail_by_rc docker build -t kafka .
fail_by_rc docker run -d --network host kafka

echo -e "--- waiting for docker container & certificate creation ---"
sleep 5
container_id=$(docker container ls  | grep "kafka" | awk '{print $1}')

echo "container id : $container_id"

echo "--- downloading ssl certificate to" $PWD"/kafkaCerts from container with id $container_id ---"

fail_by_rc rm -rf kafkaCerts
fail_by_rc mkdir -p kafkaCerts

fail_by_rc docker cp $container_id:/certs/client.crt.pem ${PWD}/kafkaCerts/client.crt.pem

fail_by_rc docker cp $container_id:/certs/client.key.pem ${PWD}/kafkaCerts/client.key.pem

fail_by_rc docker cp $container_id:/certs/rootCA.crt.pem ${PWD}/kafkaCerts/rootCA.crt.pem

echo -e "--- logging container logs ---"
docker logs --follow $container_id
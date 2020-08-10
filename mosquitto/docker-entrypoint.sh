#!/bin/bash

RMQ_HOST=${RMQ_HOST:-localhost}
START_MOSQUITTO_INDEX=${START_MOSQUITTO_INDEX:-0}
END_MOSQUITTO_INDEX=${END_MOSQUITTO_INDEX:-25}
MIN_MSG_SEND_DELAY_MS=${MIN_MSG_SEND_DELAY_MS:-100}
MAX_MSG_SEND_DELAY_MS=${MAX_MSG_SEND_DELAY_MS:-1000}
# it is internal number of mosquitto. It is used for calculation of port number.
INTERNAL_NUMBER=0
declare -A INSTANCES_PORTS

for COMMON_NUMBER in $(seq $START_MOSQUITTO_INDEX $END_MOSQUITTO_INDEX)
do
  CLOUDNODE_ID=$(echo "$(printf '0%.0s' $(seq 1 $((7-${#COMMON_NUMBER}))))$COMMON_NUMBER")
  PORT=$((1800 + $INTERNAL_NUMBER))
  INSTANCES_PORTS[$COMMON_NUMBER]=$PORT
  DATA_DIR="/opt/mosquitto/$COMMON_NUMBER/data/"
  CERTS_DIR="/opt/mosquitto/$COMMON_NUMBER/certs"
  mkdir -p $DATA_DIR
  mkdir -p $CERTS_DIR

  # Generate client cert
  openssl req -nodes -newkey rsa:2048 -keyout $CERTS_DIR/client.key -out $CERTS_DIR/client.csr -subj "/C=US/CN=cloudnode-$CLOUDNODE_ID.emqx-test.com"
  # Sign the client cert
  openssl x509 -req -days 5000 -in $CERTS_DIR/client.csr -CA /etc/ssl/mosquitto/CA.crt -CAkey /etc/ssl/mosquitto/CA.key -CAcreateserial -out $CERTS_DIR/client.crt

  # prepare config
  CONFIG_PATH="/opt/mosquitto/$COMMON_NUMBER/mosquitto.conf"
  sed "s|CLOUDNODE_ID|$CLOUDNODE_ID|g" /etc/mosquitto.conf > $CONFIG_PATH
  sed -i "s|RMQ_HOST|$RMQ_HOST|g" $CONFIG_PATH
  sed -i "s|CERTS_DIR|$CERTS_DIR|g" $CONFIG_PATH
  sed -i "s|DATA_DIR|$DATA_DIR|g" $CONFIG_PATH
  sed -i "s|MQTT_PORT|$PORT|g" $CONFIG_PATH

  chown -R mosquitto:mosquitto /opt/mosquitto/$COMMON_NUMBER/
  /usr/sbin/mosquitto -c $CONFIG_PATH &

  INTERNAL_NUMBER=$(($INTERNAL_NUMBER + 1))
done

# periodically send messages to the random mosquitto
declare -A MESSAGES_COUNTER
while true
do
  INSTANCE=$(shuf -i $START_MOSQUITTO_INDEX-$END_MOSQUITTO_INDEX -n 1)
  PORT=${INSTANCES_PORTS[$INSTANCE]}
  MSG=$(echo "{\"mosquitto\": $INSTANCE, \"message\": ${MESSAGES_COUNTER[$INSTANCE]:-1}}")
  mosquitto_pub -p $PORT -t endpoint/added -q 1 -m "$MSG"
  MESSAGES_COUNTER[$INSTANCE]=$((${MESSAGES_COUNTER[$INSTANCE]:-1} + 1))

  # simulate case when two mosquitto try to connect to EMQX with the same client id
  #INSTANCE=$(shuf -i $START_MOSQUITTO_INDEX-$END_MOSQUITTO_INDEX -n 1)
  #PID=$(ps aux | grep "/opt/mosquitto/$INSTANCE/mosquitto.conf" | grep -v grep | awk '{print $1}')
  #NEW_PORT=$(shuf -i 2000-3000 -n 1)
  #INSTANCES_PORTS[$INSTANCE]=$NEW_PORT
  #sed -i "s/port.*/port $NEW_PORT/" /opt/mosquitto/$INSTANCE/mosquitto.conf
  #/usr/sbin/mosquitto -c /opt/mosquitto/$INSTANCE/mosquitto.conf &
  #sleep 2 && kill $PID &

  # get delay time
  RANDOM_DELAY=$(shuf -i $MIN_MSG_SEND_DELAY_MS-$MAX_MSG_SEND_DELAY_MS -n 1)
  # get delay as float value
  DELAY=$(bc <<< "scale=2; $RANDOM_DELAY/1000")
  sleep $DELAY
done
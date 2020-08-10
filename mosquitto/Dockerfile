FROM eclipse-mosquitto:1.6.9

RUN apk update && apk add openssl bash bc

COPY CA.crt /etc/ssl/mosquitto/CA.crt
COPY CA.key /etc/ssl/mosquitto/CA.key
COPY mosquitto.conf /etc/mosquitto.conf
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

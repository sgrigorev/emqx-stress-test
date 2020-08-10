# emqx-stress-test

A set of scripts and tools for stress testing of emqx.
There is docker-compose.yaml file that can be used to start RabbitMQ, EMQX and mosquitto containers. EMQX is configured to connect to RabbitMQ and mosquito is configured to connect to EMQX.
Inside the mosquitto container actually will be created 100 mosquitto instances.After starting of all mosquitto processes it will be started a loop with periodically sending messages to the random mosquitto instance. Then messages are forwarded to RabbitMQ through EMQX.
The number of instances and the message sending delay are configurable through environment variables, see docker-compose.yaml.

### The issue with infinite resending messages

#### How to reproduce
1. Start RabbitMQ
```
$ docker-compose up -d rabbitmq
```
2. Open RabbitMQ web UI (http://localhost:15672/) and create an exchange with name "cloudnodes" and with type topic
3. Start EMQX
```
$ docker-compose up -d emqx
```
4. Start the mosquitto container
```
$ docker-compose up -d mosquitto
```
5. Wait for all clients to connect to EMQX (2-3 minutes) and then restart RabbitMQ
```
$ docker-compose restart rabbitmq
```
6. Check logs of the EMQX. There should be a lot of error messages after EMQX connects to the RabbitMQ.
```
$ docker logs --tail 10 emqx-stress-test -f
2020-08-10 14:50:56.173 [error] [Bridge] Can't be found from the inflight:1832
2020-08-10 14:50:56.173 [error] [Bridge] Can't be found from the inflight:1833
2020-08-10 14:50:56.173 [error] [Bridge] Can't be found from the inflight:1834
2020-08-10 14:50:56.173 [error] [Bridge] Can't be found from the inflight:1835
2020-08-10 14:50:56.174 [error] [Bridge] Can't be found from the inflight:1836
```
Messages sending rate to the "cloudnodes" exchange should also be very high. It can be checked in the RabbitMQ UI.
7. Restart the RabbitMQ container one more time if the problem is not reproduced.

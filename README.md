# kafka-elk-docker-compose
This repository deploys with *docker-compose* an ELK stack which has kafka cluster buffering the logs collection process. This repository tries to make your life easier while testing a similar architecture. It is highly discouraged to use this repository as a production ready solution of this stack.

## Setup

1.  [Install Docker engine](https://docs.docker.com/engine/installation/)
2.  [Install Docker compose](https://docs.docker.com/compose/install/)
3.  Clone this repository:
    ```
    git clone https://github.com/bosh-rebels/kafka-elk-spike.git
    ```
4. [Configure File Descriptors and MMap](https://www.elastic.co/guide/en/elasticsearch/guide/current/_file_descriptors_and_mmap.html)
To do so you have to type the following command:
    ```
    sysctl -w vm.max_map_count=262144
    ```
    Be aware that the previous sysctl setting vanishes when your machine restarts.
    If you want to make it permanent place `vm.max_map_count` setting in your `/etc/sysctl.conf`.
5. Create the elasticsearch volume:
    ```bash
    $ cd kafka-elk-spike
    $ mkdir esdata
    ```
    By default the *docker-compose.yml* uses *esdata* as the host volumen path name. If you want to use another name you have to edit the *docker-compose.yml* file and create your own structure.
6. Allocate enough memory to Docker in your local machine (Toolbar -> Docker icon -> Preferences -> Resources)


## Usage

Deploy your Kafka+ELK Stack using *docker-compose*:

```bash
$ docker-compose -f kafka-docker-compose up  ( -d optional)
$ docker-compose -f elk-docker-compose up  ( -d optional)
```

To pump message to Kafka we are suing '/kafka-console-producer.sh' utility

Message 

``` json
{"origin": "rep","index": "485aa9a8-0b15-49b0-a5da-1cb16200c640","timestamp_ns": 1530028516300126053,"tags": {    "source_id": "30ec7020-ddd2-40c1-9f23-389aeef147f1"},"timestamp": 1530028516300,"job": "diego_cell","deployment": "cf","logMessage": {    "environment_id": "prod3",    "timestamp_ns": 1530028516300126053,    "timestamp": 1530028516300,    "app": {        "org": "ca-apm-agent",        "guid": "30ec7020-ddd2-40c1-9f23-389aeef147f1",        "name": "ca-apm-nozzle",        "space": "ca-apm"    },    "source_instance": "0",    "source_type": "APP/PROC/WEB",    "message": "2018/06/26 15:55:16 Posting 2210 metrics"},"ip": "10.58.4.18"}
```

Login to Kafka container, copy above message into container and publish message 


``` bash
$ docker ps - to get runnning docker instancecs 
$ docker exec -it {kafka container id} bash  - to login to running kafka container in interactive mode
$ cd /opt/bitnami/kafka/bin
$ copy message into kafka container 
$ cat <<EOF > fullmessage-singleline.json <hit enter> and copy message in mext line
  {"origin": "rep","index": "485aa9a8-0b15-49b0-a5da-1cb16200c640","timestamp_ns": 1530028516300126053,"tags": {    "source_id": "30ec7020-ddd2-40c1-9f23-389aeef147f1"},"timestamp": 1530028516300,"job": "diego_cell","deployment": "cf","logMessage": {    "environment_id": "prod3",    "timestamp_ns": 1530028516300126053,    "timestamp": 1530028516300,    "app": {        "org": "ca-apm-agent",        "guid": "30ec7020-ddd2-40c1-9f23-389aeef147f1",        "name": "ca-apm-nozzle",        "space": "ca-apm"    },    "source_instance": "0",    "source_type": "APP/PROC/WEB",    "message": "2018/06/26 15:55:16 Posting 2210 metrics"},"ip": "10.58.4.18"}
  <hit enter and type EOF in next line>
  EOF
```

Run following command from within container to publish message to the log topic

```
$ cd /opt/bitnami/kafka/bin
$ ./kafka-console-producer.sh --broker-list localhost:9092 --topic log < ./fullmessage-singleline.json
```

After that you should be able to hit Kibana [http://localhost:5601](http://localhost:5601)

Before you see the log entries generated before you have to configure an index pattern in kibana. Make sure you configure it with these two options:
* Index name or pattern: payment-*
* Time-field name: @timestamp


## Transforming message from one format to another
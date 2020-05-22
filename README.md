# kafka-elk-spike
This repository deploys with *docker-compose* an ELK stack which has kafka single/cluster buffering the logs collection process. This repository tries to make your life easier while testing a similar architecture. all components kafa, zookeeper, logstash, elasticsearch and kibana can be spin up using single docker-compose, we have decided to split them in 3 groups( [kafka, zookeeper] , [elasticsearch, kibana], [logstash] ) to monitor logs/investigate issues seperately and reduce deployment time of logstash as we were playing with logstash mostly.

## Setup

1.  [Install Docker engine](https://docs.docker.com/engine/installation/)
2.  [Install Docker compose](https://docs.docker.com/compose/install/)
3.  Clone this repository:
    ```
    git clone https://github.com/bosh-rebels/kafka-elk-spike.git
    ```
4. If you are running on Linux -  [Configure File Descriptors and MMap](https://www.elastic.co/guide/en/elasticsearch/guide/current/_file_descriptors_and_mmap.html)
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
    By default the *elk-docker-compose.yml* uses *esdata* as the host volumen path name. If you want to use another name you have to edit the *elk-docker-compose.yml* file, update  volumes: section according to your structure.
    
6. Allocate enough memory to docker if you haven't done it already - Allocate memory(6-8GB) to Docker in your local machine (Toolbar -> Docker icon -> Preferences -> Resources)


## Usage

Deploy your Kafka+ELK Stack using *docker-compose*:

```bash
$ docker-compose -f kafka-docker-compose up  ( -d optional)
$ docker-compose -f elk-docker-compose up  ( -d optional)
$ docker-compose -f logstash-docker-compose up  ( -d optional)
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

* Message received by logstash has malformatted json, it has '=>' instead if ':', so to correct that format, we have to use 'mutate filter'
    
    ```
	mutate {
         replace => ["=>",":"]
	}
    ```

* TO restructure input json message to target format we are using 'Ruby filter plugin and external ruby script'

 ```
    ruby {
		path => "/usr/share/scripts/updatemessage.rb"
		script_params => {
			"source_field" => "message"
    	}   
     }
```

## Create elastic search index

We can create elastic search index based on data from message, we have to follow following instructions
* Extract data from incoming message and set in enent attribure e.g  env_id and app_name , we are setting these attributes inside Ruby plugin
* setup index property of elasticsearch output plugin

```
elasticsearch {
       hosts => ["<elasticsearch host ip>:9200"]
       index => "paymenthub-%{env_id}-%{app_name}-%{+YYYY.MM.dd}"
	   codec => "json"
  }
  ```

# docker-script-kafka-outbound
This is a script to quickly deploy containers for kafka, zookeeper, and the Aerospike Kafka Outbound connector.

The script will also configure the XDR settings dynamically using aerolab and asadm if a cluster is already running. Just pass the cluster name to the script when prompted.
## Quickstart
*[NOTE]* Ensure you have a cluster already with asd running within aerolab if you want the script to configure XDR connector automatically.

Run the `deploy-koconnector.sh` script which will create a `docker-compose.yml` and start the 3 containers.
```bash
./deploy-koconnector.sh
```
Once you are done with the containers you can stop them by simply running the following command in the same directory:
```bash
docker-compose down
```


## Configure Outbound Connector
Aerospike Kafka Outbound Connector settings are configured in the `aerospike-kafka-outbound.yaml` file. 
Additional details for configuration can be found [here](https://docs.aerospike.com/connect/kafka/from-asdb/configuring).


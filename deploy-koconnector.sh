cat << EOF > docker-compose.yml
version: "3"

networks:
  kafka-outbound:
    driver: bridge

services:
  zookeeper:
    image: docker.io/bitnami/zookeeper:3.8
    container_name: zookeeper
    networks:
      - kafka-outbound
    ports:
      - "2181:2181"
    volumes:
      - "zookeeper_data:/bitnami"
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes

  kafka:
    image: docker.io/bitnami/kafka:3.2
    container_name: kafka
    networks:
      - kafka-outbound
    ports:
      - "9092:9092"
    volumes:
      - "kafka_data:/bitnami"
    environment:
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - ALLOW_PLAINTEXT_LISTENER=yes
    depends_on:
      - zookeeper

  connector-out:
    image: aerospike/aerospike-kafka-outbound:5.0.0
    container_name: connector
    networks:
      - kafka-outbound
    ports:
      - "8080"
    volumes:
      - "$(pwd)/aerospike-kafka-outbound.yml:/etc/aerospike-kafka-outbound/aerospike-kafka-outbound.yml"
    depends_on:
      - kafka

volumes:
  zookeeper_data:
    driver: local
  kafka_data:
    driver: local

EOF

echo "Running docker-compose up -d"
docker-compose up -d


echo "Linking connector container to docker network"
docker network connect bridge connector

CONNECTOR_IP=$(docker inspect -f '{{.NetworkSettings.Networks.bridge.IPAddress}}' connector)

if [ -z "$CONNECTOR_IP" ]; then
	echo "Unable to get container IP for connector. Is it running?" && exit 1
fi


echo "Connector IP: $CONNECTOR_IP"
echo "If you already have an aerolab cluster we can configure the connector for you."
read -p "Automagically configure? [y/N]: " CONFIGURE_YN

if [[ "$CONFIGURE_YN" == "y" || "$CONFIGURE_YN" == "Y" ]]; then
	read -p "Please enter the aerolab cluster name: " CLUSTER_NAME
		if [ ! -z "$CLUSTER_NAME" ]; then
			CLUSTER_EXISTS=$(aerolab cluster-list | grep $CLUSTER_NAME)
			if [ ! -z "$CLUSTER_EXISTS" ]; then
				aerolab node-attach -n $CLUSTER_NAME -- asadm -e "enable; manage config xdr create dc kafka"
				aerolab node-attach -n $CLUSTER_NAME -- asadm -e "enable; manage config xdr dc kafka param connector to true"
				aerolab node-attach -n $CLUSTER_NAME -- asadm -e "enable; manage config xdr dc kafka add node $CONNECTOR_IP:8080"
				aerolab node-attach -n $CLUSTER_NAME -- asadm -e "enable; manage config xdr dc kafka add namespace bar"
			else
				echo "Unable to find cluster name: $CLUSTER_NAME" && exit 1
			fi
		fi
fi

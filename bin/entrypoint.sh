java \
  -DIP=127.0.0.1 \
  -Dvertx.metrics.options.enabled=true \
  -Dhazelcast.cluster.enabled=true \
  -Dhazelcast.cluster.hostname=127.0.0.1 \
  -D_hazelcast.client-mode=true \
  -Dhazelcast.cluster-config-file=$MICROSERVICE_HOME/cluster.xml \
  -Devergent.HMAC.key=Y9o7GiSU9bb8Uva9RU9n1SR0il0aksmi \
  -Devergent.AES.key=SAvBRCaDUErTuInK \
  -jar $MICROSERVICE_HOME/getCustomerDetailsService-1.2.0-SNAPSHOT-fat.jar

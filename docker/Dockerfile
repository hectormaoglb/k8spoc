FROM amazoncorretto:8
EXPOSE 8081
EXPOSE 9000
ENV MICROSERVICE_HOME "/opt/microservice"
RUN mkdir -p ${MICROSERVICE_HOME}
COPY target/getCustomerDetailsService-1.1.0-SNAPSHOT-fat.jar ${MICROSERVICE_HOME}
COPY cfg/cluster.xml ${MICROSERVICE_HOME}
COPY bin/entrypoint.sh ${MICROSERVICE_HOME}
RUN /bin/chmod 755 ${MICROSERVICE_HOME}/entrypoint.sh
ENTRYPOINT ${MICROSERVICE_HOME}/entrypoint.sh

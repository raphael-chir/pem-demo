#!/bin/bash

# PEM Server variables
export PEM_SERVER=192.168.56.88
export PEM_SERVER_PORT=5444
export PEM_SERVER_USER=pem
export PEM_SERVER_PASSWORD=pem

# Database to managed variables
export PEM_MONITORED_SERVER_IP_ADDR=192.168.56.90
export PEM_MONITORED_SERVER_SERVICE_NAME=edb-as-17
export PEM_MONITORED_SERVER_USER=pem
export PEM_MONITORED_SERVER_PORT=5444
export PEM_MONITORED_SERVER_PASSWORD=pem

dnf -y install edb-pem-agent

# Agent registration
/usr/edb/pem/agent/bin/pemworker  --register-agent \
                                  --pem-server ${PEM_SERVER} \
                                  --pem-port ${PEM_SERVER_PORT} \
                                  --pem-user ${PEM_SERVER_USER} \
                                  --batch-script-user root \
                                  --enable-heartbeat-connection

  # Register server
/usr/edb/pem/agent/bin/pemworker  --register-server \
                                  --server-addr ${PEM_MONITORED_SERVER_IP_ADDR} \
                                  --server-port ${PEM_MONITORED_SERVER_PORT} \
                                  --server-database postgres \
                                  --server-user ${PEM_MONITORED_SERVER_USER} \
                                  --server-service-name ${PEM_MONITORED_SERVER_SERVICE_NAME} \
                                  --display-name server-`hostname` \
                                  --pem-server ${PEM_SERVER} \
                                  --pem-port ${PEM_SERVER_PORT} \
                                  --pem-user ${PEM_SERVER_USER} \
                                  --asb-host-name ${PEM_MONITORED_SERVER_IP_ADDR} \
                                  --asb-host-port ${PEM_SERVER_PORT} \
                                  --asb-host-db postgres \
                                  --asb-host-user ${PEM_SERVER_USER} \
                                  --remote-monitoring yes

# Start PEM service
systemctl enable --now pemagent

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

# Unregister server
/usr/edb/pem/agent/bin/pemworker  --unregister-server \
                                  --server-addr ${PEM_MONITORED_SERVER_IP_ADDR} \
                                  --server-port ${PEM_MONITORED_SERVER_PORT} \
                                  --pem-user ${PEM_MONITORED_SERVER_USER}

# Unregister agent
/usr/edb/pem/agent/bin/pemworker --unregister-agent --pem-user ${PEM_SERVER_USER}

# Remove agent
dnf -y remove edb-pem-agent
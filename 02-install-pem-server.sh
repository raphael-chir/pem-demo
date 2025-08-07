#!/bin/bash

# Load token and PG version
export EDB_REPO_TOKEN=$(cat /vagrant/.edbtoken)
export PG_VERSION=17

# PEM
sudo dnf -y install edb-as${PG_VERSION}-server-sslutils
sudo dnf -y install edb-pem

# Install PEM server
sudo /usr/edb/pem/bin/configure-pem-server.sh \
-dbi /usr/edb/as${PG_VERSION} \
-ci 0.0.0.0/0 \
-p 5444 \
-sp dba \
-su dba \
-t 1 \
-ds edb-as-${PG_VERSION} \
-acp ~/.pem/ \
-scs /C=FR/ST=FR/L=PARIS/O=EDB/OU=EDB/CN=localhost/emailAddress=raphael.chir@enterprisedb.com


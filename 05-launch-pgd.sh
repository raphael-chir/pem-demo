#!/bin/bash
set -e

# Parse arguments
PORT=$1
ROLE=$2
LEADER_IP=$3
FOLLOWER_IP=$4
WITNESS_IP=$5

export PG_VERSION=17

INSTANCE_HOST=$(hostname -I | awk '{print $2}')
INSTANCE_HOST_SANITIZED=${INSTANCE_HOST//./-}
CLUSTER_NAME="pgd"
GROUP_NAME="dg1"
NODE_NAME=${CLUSTER_NAME}-node-${INSTANCE_HOST_SANITIZED}
export PGPASSWORD=secret

case "$ROLE" in
  leader)
    /usr/edb/as${PG_VERSION}/bin/pgd node ${NODE_NAME} setup \
    --pgdata /mnt/data${PORT}/ \
    --dsn "host=${INSTANCE_HOST} user=postgres port=${PORT} dbname=pgddb" \
    --group-name ${GROUP_NAME}
  ;;
  follower)
    /usr/edb/as${PG_VERSION}/bin/pgd node ${NODE_NAME} setup \
    --pgdata /mnt/data${PORT}/ \
    --dsn "host=${INSTANCE_HOST} user=postgres port=${PORT} dbname=pgddb" \
    --cluster-dsn "host=${LEADER_IP} user=postgres port=${PORT} dbname=pgddb"
  ;;
esac

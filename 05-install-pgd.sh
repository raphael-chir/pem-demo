#!/bin/bash
set -e

# Parse arguments
PORT=$1
ROLE=$2
LEADER_IP=$3
FOLLOWER_IP=$4
WITNESS_IP=$5

export PG_VERSION=17
export EDB_REPO_TOKEN=$(cat /vagrant/.edbtoken)

# Stop firewall
systemctl stop firewalld || true
systemctl disable firewalld

# Enable IPv6 (needed for default config and connection manager)
sysctl -w net.ipv6.conf.all.disable_ipv6=0
sysctl -w net.ipv6.conf.default.disable_ipv6=0

# Install EPAS
curl -1sLf "https://downloads.enterprisedb.com/${EDB_REPO_TOKEN}/enterprise/setup.rpm.sh" | bash
dnf -y install edb-as${PG_VERSION}-server \
    edb-as${PG_VERSION}-pgvector0 \
    edb-as${PG_VERSION}-server-sqlprofiler \
    edb-as${PG_VERSION}-server-edb_wait_states \
    edb-as${PG_VERSION}-system-stats3 \
    edb-as${PG_VERSION}-query-advisor \
    edb-as${PG_VERSION}-postgres-tuner1

# Install PGD Essential or Expanded
curl -1sSLf "https://downloads.enterprisedb.com/${EDB_REPO_TOKEN}/postgres_distributed/setup.rpm.sh" | bash
dnf install -y edb-pgd6-expanded-epas${PG_VERSION}

# Create loop device + mount (root)
MOUNT_POINT="/mnt/data${PORT}"
LOOP_FILE="/var/lib/data${PORT}.img"
SIZE_MB=1024
dd if=/dev/zero of=$LOOP_FILE bs=1M count=$SIZE_MB
mkfs.xfs $LOOP_FILE
mkdir -p $MOUNT_POINT
mount -o loop $LOOP_FILE $MOUNT_POINT
grep -q "$MOUNT_POINT" /etc/fstab || echo "$LOOP_FILE $MOUNT_POINT xfs loop 0 0" >> /etc/fstab
chown -R enterprisedb:enterprisedb $MOUNT_POINT

# Initialize pgd-cli configuration
mkdir -p /etc/edb/pgd-cli
cat <<EOF | sudo tee /etc/edb/pgd-cli/pgd-cli-config.yml
cluster:
  name: pgd
  endpoints:
    - host=${LEADER_IP}   dbname=pgddb port=${PORT} user=postgres
    - host=${FOLLOWER_IP} dbname=pgddb port=${PORT} user=postgres
    - host=${WITNESS_IP}  dbname=pgddb port=${PORT} user=postgres
EOF
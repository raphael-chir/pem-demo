#!/bin/bash
set -e

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instances) PORTS="$2"; shift 2;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

if [ -z "$PORTS" ]; then
  echo "Usage: $0 --instances <comma-separated-ports>"
  exit 1
fi

# Convert PORTS string to array (for multi-instance support)
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

# Install and start Barman
dnf -y install barman-cli

# Loop over ports to create instances
for PORT in "${PORT_ARRAY[@]}"; do

    DATA_DIR="/mnt/data${PORT}"

    # Create replication user for Barman
    sudo -u enterprisedb psql -d postgres -p $PORT <<EOF
CREATE USER barman WITH PASSWORD 'barman' REPLICATION;
EOF

    # Configure barman user to perform replication
    sed -i '$ a host    replication     barman          all                     md5' $DATA_DIR/pg_hba.conf
    sudo -u enterprisedb /usr/edb/as17/bin/pg_ctl -D $DATA_DIR reload

    # Create Barman configuration for the instance
    INSTANCE_HOST=$(hostname -I | awk '{print $2}')
    FILENAME="epas-${INSTANCE_HOST}-${PORT}.conf"

    ssh -i /vagrant/.vagrant/machines/barman/virtualbox/private_key \
        -o StrictHostKeyChecking=no vagrant@192.168.56.89 \
        "sudo tee /etc/barman.d/${FILENAME} > /dev/null <<EOF
[epas-${INSTANCE_HOST}-${PORT}]
description =  \"EPAS Server\"
conninfo = host=${INSTANCE_HOST} port=${PORT} user=dba password=dba dbname=postgres
streaming_conninfo = host=${INSTANCE_HOST} port=${PORT} user=barman password=barman dbname=postgres
backup_method = postgres
streaming_archiver = on
slot_name = barman
create_slot = auto
EOF
sudo chown barman:barman /etc/barman.d/${FILENAME}
sudo -u barman /usr/bin/barman cron
"

    # Launch a dataset
    sudo -u enterprisedb /usr/edb/as17/bin/pgbench -p $PORT -i -s 10 postgres
done



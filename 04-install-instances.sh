#!/bin/bash
set -e

# Parse arguments
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

export EDB_REPO_TOKEN=$(cat /vagrant/.edbtoken)
export PG_VERSION=17

# Stop firewall
systemctl stop firewalld || true
systemctl disable firewalld

# Install EPAS
curl -1sLf "https://downloads.enterprisedb.com/${EDB_REPO_TOKEN}/enterprise/setup.rpm.sh" | bash
dnf -y install edb-as${PG_VERSION}-server \
    edb-as${PG_VERSION}-pgvector0 \
    edb-as${PG_VERSION}-server-sqlprofiler \
    edb-as${PG_VERSION}-server-edb_wait_states \
    edb-as${PG_VERSION}-system-stats3 \
    edb-as${PG_VERSION}-query-advisor \
    edb-as${PG_VERSION}-postgres-tuner1

# Configure environment
cat >> /var/lib/edb/.bash_profile <<EOF
export PATH=\$PATH:/usr/edb/as${PG_VERSION}/bin
EOF
source /var/lib/edb/.bash_profile

# Loop over ports to create instances
for PORT in "${PORT_ARRAY[@]}"; do

  # Simulate a mount point with a quota
  mount_point="/mnt/data${PORT}"
  loop_file="/var/lib/data${PORT}.img"
  size_mb=1024
  dd if=/dev/zero of=$loop_file bs=1M count=$size_mb
  mkfs.xfs $loop_file
  mkdir -p $mount_point
  mount -o loop $loop_file $mount_point
  grep -q "$mount_point" /etc/fstab || echo "$loop_file $mount_point xfs loop 0 0" >> /etc/fstab
  chown enterprisedb:enterprisedb $mount_point

  # Initialize database cluster
  DATA_DIR=$mount_point
  sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/initdb -E UTF8 -D "$DATA_DIR"

  # PostgreSQL config
  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$DATA_DIR/postgresql.conf"
  sed -i "s/^#port = 5444/port = ${PORT}/" "$DATA_DIR/postgresql.conf"
  sed -i "s/^shared_preload_libraries.*/shared_preload_libraries = '\$libdir\/dbms_pipe,\$libdir\/edb_gen,\$libdir\/dbms_aq,\$libdir\/sql-profiler,\$libdir\/edb_wait_states,\$libdir\/pg_stat_statements,query_advisor,edb_pg_tuner'/" "$DATA_DIR/postgresql.conf"

  cat > "$DATA_DIR/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    all             all             0.0.0.0/0               md5
host    all             all             ::1/128                 ident
local   replication     all                                     peer
host    replication     all             0.0.0.0/0               md5
EOF

  # Start instance
  sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/pg_ctl -D "$DATA_DIR" -o "-p ${PORT}" -w start

  # Create extensions and users
  sudo -u enterprisedb psql -p ${PORT} -d postgres <<EOSQL
CREATE EXTENSION IF NOT EXISTS sql_profiler;
CREATE EXTENSION IF NOT EXISTS edb_wait_states;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS system_stats;
CREATE EXTENSION IF NOT EXISTS query_advisor;
CREATE EXTENSION IF NOT EXISTS edb_pg_tuner;

CREATE USER dba WITH PASSWORD 'dba' SUPERUSER;
CREATE USER pem WITH PASSWORD 'pem' SUPERUSER;
EOSQL

done

echo "✅ EPAS instances created successfully."

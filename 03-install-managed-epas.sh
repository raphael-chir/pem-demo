#!/bin/bash

# Stop & disable firewalld
systemctl stop firewalld.service || true
systemctl disable firewalld.service || true

# Load token and PG version
export EDB_REPO_TOKEN=$(cat /vagrant/.edbtoken)
export PG_VERSION=17

# Configure EDB repo
curl -1sLf "https://downloads.enterprisedb.com/${EDB_REPO_TOKEN}/enterprise/setup.rpm.sh" | sudo -E bash

# Install EPAS and extensions
dnf -y install edb-as${PG_VERSION}-server \
  edb-as${PG_VERSION}-pgvector0 \
  edb-as${PG_VERSION}-server-sqlprofiler \
  edb-as${PG_VERSION}-server-edb_wait_states \
  edb-as${PG_VERSION}-system-stats3 \
  edb-as${PG_VERSION}-query-advisor \
  edb-as${PG_VERSION}-postgres-tuner1

# Configure .bash_profile for enterprisedb
cat >> /var/lib/edb/.bash_profile <<EOF
export PATH=\$PATH:/usr/edb/as${PG_VERSION}/bin
export PGDATABASE=postgres
export PGDATA=/var/lib/edb/as${PG_VERSION}/data
EOF

# Load env vars
source /var/lib/edb/.bash_profile

# Initialize the database cluster
sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/initdb -E UTF8 -D "$PGDATA"

# PostgreSQL configuration
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$PGDATA/postgresql.conf"
sed -i "s/^shared_preload_libraries.*/shared_preload_libraries = '\$libdir\/dbms_pipe,\$libdir\/edb_gen,\$libdir\/dbms_aq,\$libdir\/sql-profiler,\$libdir\/edb_wait_states,\$libdir\/pg_stat_statements,query_advisor,edb_pg_tuner'/" "$PGDATA/postgresql.conf"

# Replace pg_hba.conf
cat > "$PGDATA/pg_hba.conf" <<'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    all             all             0.0.0.0/0               md5
host    all             all             ::1/128                 ident
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            ident
host    replication     all             ::1/128                 ident
EOF

# Start PostgreSQL
sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/pg_ctl -D "$PGDATA" -w start

# Create extensions
sudo -u enterprisedb psql -d postgres <<EOF
CREATE EXTENSION sql_profiler;
CREATE EXTENSION edb_wait_states;
CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION system_stats;
CREATE EXTENSION query_advisor;
CREATE EXTENSION edb_pg_tuner;

CREATE USER dba PASSWORD 'dba' SUPERUSER;
CREATE USER pem PASSWORD 'pem' SUPERUSER;
EOF

# Restart service
sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/pg_ctl -D "$PGDATA" -w restart

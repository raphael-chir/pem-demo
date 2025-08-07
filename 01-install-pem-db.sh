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
dnf -y install edb-as${PG_VERSION}-server 

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

# Services
sudo systemctl enable edb-as-${PG_VERSION}.service
sudo systemctl start edb-as-${PG_VERSION}.service

# Create superuser
sudo -u enterprisedb psql -d postgres <<EOF
CREATE USER dba PASSWORD 'dba' SUPERUSER;
CREATE USER pem PASSWORD 'pem' SUPERUSER;
EOF
#!/bin/bash
set -e

# Parse arguments
PORTS=$1
ROLE=$2
VIPS=$3
PRIMARY_IP=$4
REPLICA_IP=$5
WITNESS_IP=$6

# Convert PORTS string to array (for multi-instance support)
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
IFS=',' read -ra VIP_ARRAY <<< "$VIPS"

export EDB_REPO_TOKEN=$(cat /vagrant/.edbtoken)
# Usefull only for witness node but set for all for simplicity
curl -1sLf "https://downloads.enterprisedb.com/${EDB_REPO_TOKEN}/enterprise/setup.rpm.sh" | bash
export PG_VERSION=17
export EFM_VERSION=5.1

# Install EFM
dnf -y install java-21-openjdk
dnf -y install edb-efm51

# Loop over ports to configure base instance role
for i in "${!PORT_ARRAY[@]}"; do
  
  PORT="${PORT_ARRAY[$i]}"
  VIP="${VIP_ARRAY[$i]}"
  DATA_DIR="/mnt/data${PORT}"
  INSTANCE_HOST=$(hostname -I | awk '{print $2}')
  EFM_CLUSTER_NAME="efm-cluster-${PORT}"
  EFM_NODES_CONFIG_PATH="/etc/edb/efm-${EFM_VERSION}/${EFM_CLUSTER_NAME}.nodes"
  EFM_CONFIG_PATH="/etc/edb/efm-${EFM_VERSION}/${EFM_CLUSTER_NAME}.properties"
  echo "${ROLE} configuration for port ${PORT} on host ${INSTANCE_HOST} with data dir ${DATA_DIR} and VIP ${VIP}"
  # EFM encrypted password
  export EFMPASS=efm
  ENCRYPTED_PASSWORD=$(/usr/edb/efm-${EFM_VERSION}/bin/efm encrypt "$EFM_CLUSTER_NAME" --from-env)

  EFM_CLUSTER_NAME="efm-cluster-${PORT}"
  echo "${ROLE} configuration for cluster ${EFM_CLUSTER_NAME} on PG host ${INSTANCE_HOST}:${PORT} with data dir ${DATA_DIR}"
  echo "VIP : ${VIP}"
  echo "Primary IP : ${PRIMARY_IP}"
  echo "Replica IP : ${REPLICA_IP}"
  echo "Witness IP : ${WITNESS_IP}"

  # Configure pg_hba.conf for replication and efm user are not mandatory here due to permissive setup
  # but recommended for production setups
  # Warning 10 possible before conflicts if multiple instances on same host for port replication (admin port and bind address)
  
  # Common efm.nodes settings
  cat >> $EFM_NODES_CONFIG_PATH <<EOF
${PRIMARY_IP}:$((7800 + i))
${REPLICA_IP}:$((7800 + i))
${WITNESS_IP}:$((7800 + i))
EOF

  # Common efm.properties settings
  cat > $EFM_CONFIG_PATH <<EOF
# EFM properties for ${INSTANCE_HOST}-${PORT} cluster

# Database connection
db.user=efm
db.password.encrypted=${ENCRYPTED_PASSWORD}
db.port=${PORT}
db.database=postgres
db.service.owner=enterprisedb
db.service.name=
db.bin=/usr/edb/as${PG_VERSION}/bin
db.data.dir=${DATA_DIR}
db.config.dir=${DATA_DIR}

# JDBC settings
jdbc.sslmode=disable
jdbc.properties=

# Notification settings
user.email=dba@domain.com
from.email=efm@%h
notification.level=INFO
notification.text.prefix=Cluster EFM-${INSTANCE_HOST}-${PORT}

# Bind & external addresses
bind.address=${INSTANCE_HOST}:$((7800 + i))
external.address=${INSTANCE_HOST}
admin.port=$((7809 + i))

# VIP settings
virtual.ip=${VIP}
virtual.ip.interface=eth1
virtual.ip.prefix=24
virtual.ip.single=true
check.vip.before.promotion=true
check.vip.timeout=60
release.vip.background=true
release.vip.pre.wait=0
release.vip.post.wait=0

# Cluster behavior
is.witness=false
local.period=10
local.timeout=15
local.timeout.final=10
remote.timeout=10
node.timeout=50
encrypt.agent.messages=false
enable.stop.cluster=true
stop.isolated.primary=true
stop.failed.primary=true
primary.shutdown.as.failure=false
update.physical.slots.period=2
auto.allow.hosts=true
stable.nodes.file=false
db.reuse.connection.count=0
auto.failover=true
auto.reconfigure=true
auto.rewind=false
promotable=true
use.replay.tiebreaker=true
standby.restart.delay=0

# Restore & backup
restore.command=
backup.wal=false

# Synchronization
reconfigure.num.sync=false
reconfigure.num.sync.max=
reconfigure.sync.primary=false
check.num.sync.period=30
minimum.standbys=0
priority.standbys=
recovery.check.period=1
restart.connection.timeout=60
auto.resume.startup.period=0
auto.resume.failure.period=0

# Load balancer / pgpool
pgpool.enable=false
pcp.user=
pcp.host=
pcp.port=
pcp.pass.file=
pgpool.bin=
script.load.balancer.attach=
script.load.balancer.detach=
detach.on.agent.failure=false

# Fencing & promotion scripts
script.fence=
script.post.promotion=
script.resumed=
script.db.failure=
script.primary.isolated=
script.remote.pre.promotion=
script.remote.post.promotion=
script.custom.monitor=
custom.monitor.interval=
custom.monitor.timeout=
custom.monitor.safe.mode=

# Sudo commands
sudo.command=sudo
sudo.user.command=sudo -u %u

# Directories
lock.dir=/var/lock/efm-${EFM_VERSION}
pid.dir=/var/run/efm-${EFM_VERSION}
log.dir=/var/log/efm-${EFM_VERSION}

# Syslog
syslog.host=localhost
syslog.port=514
syslog.protocol=UDP
syslog.facility=LOCAL1
file.log.enabled=true
syslog.enabled=false

# Logging levels
jgroups.loglevel=INFO
efm.loglevel=INFO
jdbc.loglevel=INFO
jvm.options=-Xmx128m

# Ping server for network reachability
ping.server.ip=8.8.8.8
ping.server.command=/bin/ping -q -c3 -w5
EOF

  chown efm:efm ${EFM_CONFIG_PATH}
  chown efm:efm ${EFM_NODES_CONFIG_PATH}

  case "$ROLE" in
    primary|replica)

    # Users creation
    sudo -u enterprisedb psql -p ${PORT} -d postgres <<EOSQL

-- efm user to perform monitoring and failover (grant superuser for simplicity)
CREATE USER efm WITH PASSWORD 'efm' SUPERUSER;

-- replication user for streaming replication (init replica, primary_conninfo)
CREATE USER replicator WITH PASSWORD 'replicator' REPLICATION;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint,boolean) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text) TO replicator;
EOSQL

      if [ "$ROLE" == "primary" ]; then
        # Primary initial configuration
        sudo -u enterprisedb psql -p ${PORT} -d postgres <<EOSQL
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET max_wal_senders = 15;
SELECT * FROM pg_create_physical_replication_slot('demo_slot_${PORT}');
EOSQL

      elif [ "$ROLE" == "replica" ]; then
        # Replica initial configuration
        sudo -u enterprisedb psql -p ${PORT} -d postgres <<EOSQL
ALTER SYSTEM SET primary_slot_name='demo_slot_${PORT}';
EOSQL
        # Restore from primary using pg_basebackup, with a standby.signal, primary_conninfo and a slot 
        sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/pg_ctl -D "$DATA_DIR" -o "-p ${PORT}" -w stop
        rm -rf ${DATA_DIR}/*
        sudo -u enterprisedb bash -c "PGPASSWORD='replicator' /usr/edb/as${PG_VERSION}/bin/pg_basebackup \
          -h ${PRIMARY_IP} \
          -p ${PORT} \
          -U replicator \
          -D ${DATA_DIR} \
          -R -P -X stream"
      fi

      sudo -u enterprisedb /usr/edb/as${PG_VERSION}/bin/pg_ctl -D "$DATA_DIR" -o "-p ${PORT}" -w restart
      ;;

    witness)
      dnf -y install edb-as${PG_VERSION}-server
      sed -i "s@is.witness=false@is.witness=true@" ${EFM_CONFIG_PATH}
      ;;
    *)
      echo "Unrecognized instance role $ROLE"
      ;;
  esac

  sudo -u efm /usr/edb/efm-${EFM_VERSION}/bin/runefm.sh start "$EFM_CLUSTER_NAME"
done

echo "EFM Configuration completed on role: $ROLE"
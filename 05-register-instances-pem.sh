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

# Install and start PEM agent
dnf -y install edb-pem-agent

# PEM Server variables used for both agent and instances
export PEM_SERVER_PASSWORD=pem

# First step - Register agent
/usr/edb/pem/agent/bin/pemworker  --register-agent \
                                  --pem-server 192.168.56.88 \
                                  --pem-port 5444 \
                                  --pem-user pem \
                                  --batch-script-user root \
                                  --enable-heartbeat-connection

# Second step - Register instances
# Loop over instances to register them
for PORT in "${PORT_ARRAY[@]}"; do

  # Database managed variables
  export PEM_MONITORED_SERVER_PASSWORD=pem

  /usr/edb/pem/agent/bin/pemworker  --register-server \
                                    --pem-user pem \
                                    --server-addr $(hostname -I | awk '{print $2}') \
                                    --server-port $PORT \
                                    --server-database postgres \
                                    --server-user dba \
                                    --display-name "$(hostname)-$(hostname -I | awk '{print $2}')-${PORT}" \
                                    --asb-host-user pem \
                                    --remote-monitoring no
done

systemctl enable --now pemagent

echo "✅ PEM agent and servers registered successfully."
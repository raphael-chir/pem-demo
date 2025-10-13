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

# PEM Server variables
export PEM_SERVER_PASSWORD=pem

for PORT in "${PORT_ARRAY[@]}"; do

  export PEM_MONITORED_SERVER_PASSWORD=pem

  /usr/edb/pem/agent/bin/pemworker  --unregister-server \
                                    --pem-user pem \
                                    --asb-host-name $(hostname -I | awk '{print $2}') \
                                    --server-port $PORT
done

# Unregister agent and remove package
/usr/edb/pem/agent/bin/pemworker --unregister-agent --pem-user pem

dnf -y remove edb-pem-agent

echo "✅ PEM agent and servers unregistered successfully."

#!/bin/bash

# Stop & disable firewalld
systemctl stop firewalld.service || true
systemctl disable firewalld.service || true

# Set SELinux to permissive mode
setenforce 0

# Load token and PG version
export EDB_REPO_TOKEN=$(cat /vagrant/.edbtoken)

# Configure EDB repo
curl -1sLf "https://downloads.enterprisedb.com/${EDB_REPO_TOKEN}/enterprise/setup.rpm.sh" | sudo -E bash

dnf -y install barman barman-cli edb-as17-server-client rsync pg-backup-api httpd

# Create Barman user if not exists
if ! id -u barman >/dev/null 2>&1; then
    useradd -m -d /var/lib/barman -s /bin/bash barman
fi

# Configure .bash_profile for barman
tee /var/lib/barman/.bash_profile > /dev/null <<EOF
# ~/.bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User-specific environment and startup programs

# Set PATH to include custom bin directory
export PATH="/usr/edb/as17/bin/:$HOME/bin:$PATH"

# Alias definitions
alias ll='ls -lah'
alias grep='grep --color=auto'

# Enable color support for ls
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi
EOF


# Configure global Barman settings
tee /etc/barman.conf > /dev/null <<EOL
[barman]
barman_user = barman
barman_home = /var/lib/barman
path_prefix = /usr/edb/as17/bin
configuration_files_directory = /etc/barman.d
log_file = /var/log/barman/barman.log
compression = gzip
EOL

# Ensure configuration directory exists
mkdir -p /etc/barman.d
chown -R barman:barman /etc/barman.d
chown barman:barman /etc/barman.conf
barman -v

# Start backup api
systemctl enable --now pg-backup-api

# Expose pg-backup-api
tee /etc/httpd/conf.d/pgbapi.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerName 192.168.56.89

    ProxyPass "/" "http://localhost:7480/"
    ProxyPassReverse "/" "http://localhost:7480/"

    ErrorLog /var/log/httpd/pgbapi-error.log
    CustomLog /var/log/httpd/pgbapi-access.log combined
</VirtualHost>
EOL

systemctl enable --now httpd.service 

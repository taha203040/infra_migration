#!/bin/bash
# db.sh - Database Instance Bootstrap for Amazon Linux 2023
# AMI: ami-08e7e754b2c895da7 | Instance: t3.nano

exec > >(tee -a /var/log/db-init.log) 2>&1
echo "=== db.sh started at $(date -u +%FT%TZ) ==="

# 0. Add Swap (t3.nano = 512MB RAM; PostgreSQL benefits from swap)
if [ ! -f /swapfile ]; then
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 1. Update the instance
echo "--- Updating system ---"
dnf update -y

# 2. Install PostgreSQL
echo "--- Installing PostgreSQL ---"
dnf install -y postgresql-server postgresql-contrib

# 3. Initialize and enable PostgreSQL
echo "--- Initializing PostgreSQL ---"
postgresql-setup --initdb
systemctl enable postgresql
systemctl start postgresql

# 4. Configure to listen on all interfaces (SG restricts actual access)
PG_CONF="/var/lib/pgsql/data/postgresql.conf"
sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"

# Allow connections from VPC CIDR (adjust if your VPC CIDR differs)
echo "host    all             all             10.0.0.0/16             scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql

# 5. Verification
echo "--- Versions ---"
psql --version
systemctl is-active postgresql

echo "=== db.sh finished at $(date -u +%FT%TZ) ==="

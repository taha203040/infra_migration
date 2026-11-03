```bash
#!/bin/bash
# db.sh - Database Instance Bootstrap for Amazon Linux 2023
# AMI: ami-08e7e754b2c895da7 | Instance: t3.nano

set -Eeuo pipefail

exec > >(tee -a /var/log/db-init.log) 2>&1

echo "=== db.sh started at $(date -u +%FT%TZ) ==="

# 0. Add Swap
if [ ! -f /swapfile ]; then
  echo "--- Configuring swap ---"
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || \
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 1. Update instance
echo "--- Updating system ---"
dnf update -y

# 2. Install PostgreSQL 15 Server and Client
echo "--- Installing PostgreSQL 15 ---"
dnf install -y postgresql15-server postgresql15

# 3. Initialize PostgreSQL
echo "--- Initializing PostgreSQL 15 ---"

if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
  /usr/bin/postgresql-setup --initdb --unit postgresql-15
else
  echo "PostgreSQL data directory already initialized."
fi

# 4. Configure PostgreSQL
PG_CONF="/var/lib/pgsql/data/postgresql.conf"
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"

echo "--- Configuring PostgreSQL ---"

# Listen on all interfaces
if grep -qE '^[#[:space:]]*listen_addresses' "$PG_CONF"; then
  sed -i "s/^[#[:space:]]*listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
else
  echo "listen_addresses = '*'" >> "$PG_CONF"
fi

# Allow connections from the VPC CIDR
grep -qE '^host[[:space:]]+all[[:space:]]+all[[:space:]]+10\.0\.0\.0/16' "$PG_HBA" || \
  echo "host all all 10.0.0.0/16 scram-sha-256" >> "$PG_HBA"

# 5. Enable and start PostgreSQL
echo "--- Starting PostgreSQL 15 ---"
systemctl enable --now postgresql-15

# 6. Verify installation and service
echo "--- Verifying PostgreSQL ---"

psql --version
systemctl is-active --quiet postgresql-15

sudo -u postgres psql -c "SELECT version();"

ss -lntp | grep ':5432'

echo "=== db.sh finished at $(date -u +%FT%TZ) ==="
```
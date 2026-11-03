#!/bin/bash
# PostgreSQL 15 Bootstrap
# OS: Amazon Linux 2023
# Instance: t3.nano
# VPC CIDR: 10.0.0.0/16

set -Eeuo pipefail

# ==================================================
# 0. Root privileges and logging
# ==================================================

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run with sudo."
    exit 1
fi

exec > >(tee -a /var/log/db-init.log) 2>&1

echo "=========================================="
echo "Database bootstrap started: $(date -u +%FT%TZ)"
echo "=========================================="

PGDATA="/var/lib/pgsql/data"
PG_CONF="$PGDATA/postgresql.conf"
PG_HBA="$PGDATA/pg_hba.conf"

# ==================================================
# 1. Configure Swap
# ==================================================

echo "--- Configuring 1GB swap ---"

if [[ ! -f /swapfile ]]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
fi

if ! swapon --show | grep -q '/swapfile'; then
    swapon /swapfile
fi

if ! grep -qE '^/swapfile[[:space:]]' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ==================================================
# 2. Install PostgreSQL 15
# ==================================================

echo "--- Installing PostgreSQL 15 ---"

dnf install -y postgresql15-server postgresql15

# ==================================================
# 3. Initialize Database Cluster
# ==================================================

echo "--- Preparing PostgreSQL data directory ---"

if [[ -f "$PGDATA/PG_VERSION" ]]; then
    echo "Existing initialized cluster detected."
else
    # Preserve incomplete initialization files.
    if [[ -d "$PGDATA" ]] &&
       find "$PGDATA" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then

        BACKUP="${PGDATA}.incomplete.$(date +%Y%m%d%H%M%S)"

        echo "Moving incomplete data directory to $BACKUP"
        mv "$PGDATA" "$BACKUP"
    fi

    install -d -o postgres -g postgres -m 700 "$PGDATA"

    echo "--- Initializing PostgreSQL cluster ---"

    /usr/bin/postgresql-setup --initdb
fi

if [[ ! -f "$PGDATA/PG_VERSION" ]]; then
    echo "ERROR: PostgreSQL cluster initialization failed."
    exit 1
fi

chown -R postgres:postgres "$PGDATA"

# ==================================================
# 4. Configure PostgreSQL
# ==================================================

echo "--- Configuring PostgreSQL ---"

# Listen on network interfaces.
if grep -qE '^[#[:space:]]*listen_addresses[[:space:]]*=' "$PG_CONF"; then
    sed -i "s/^[#[:space:]]*listen_addresses[[:space:]]*=.*/listen_addresses = '*'/" "$PG_CONF"
else
    echo "listen_addresses = '*'" >> "$PG_CONF"
fi

# PostgreSQL port.
if grep -qE '^[#[:space:]]*port[[:space:]]*=' "$PG_CONF"; then
    sed -i "s/^[#[:space:]]*port[[:space:]]*=.*/port = 5432/" "$PG_CONF"
else
    echo "port = 5432" >> "$PG_CONF"
fi

# Allow connections from the VPC.
if ! grep -qE '^host[[:space:]]+all[[:space:]]+all[[:space:]]+10\.0\.0\.0/16' "$PG_HBA"; then
    echo "host all all 10.0.0.0/16 scram-sha-256" >> "$PG_HBA"
fi

chown postgres:postgres "$PG_CONF" "$PG_HBA"
chmod 600 "$PG_CONF" "$PG_HBA"

# ==================================================
# 5. Enable and Start PostgreSQL
# ==================================================

echo "--- Enabling PostgreSQL service ---"

systemctl enable postgresql
systemctl restart postgresql

# ==================================================
# 6. Wait for Database Readiness
# ==================================================

echo "--- Waiting for PostgreSQL readiness ---"

for attempt in {1..30}; do
    if runuser -u postgres -- pg_isready -q; then
        echo "PostgreSQL is ready."
        break
    fi

    if [[ "$attempt" -eq 30 ]]; then
        echo "ERROR: PostgreSQL failed to start."

        journalctl -u postgresql -n 50 --no-pager
        exit 1
    fi

    sleep 2
done

# ==================================================
# 7. Verify Installation
# ==================================================

echo "--- Verifying PostgreSQL ---"

psql --version

systemctl is-active --quiet postgresql

runuser -u postgres -- psql -c "SELECT version();"

echo "--- Listening on port 5432 ---"

ss -lntp | grep ':5432'

echo "=========================================="
echo "Database setup completed successfully."
echo "Finished: $(date -u +%FT%TZ)"
echo "=========================================="

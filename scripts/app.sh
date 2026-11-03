#!/bin/bash
# app.sh - App Instance Bootstrap for Amazon Linux 2023
# AMI: ami-08e7e754b2c895da7 | Instance: t3.nano
# Requires: Outbound internet (NAT or public subnet)

exec > >(tee -a /var/log/app-init.log) 2>&1
echo "=== app.sh started at $(date -u +%FT%TZ) ==="

# 1. Update the instance
echo "--- Updating system ---"
dnf update -y

# 2. Install Node.js (AL2023 default repo provides nodejs 18/20)
echo "--- Installing Node.js ---"
dnf install -y nodejs

# 3. Install Git
echo "--- Installing Git ---"
dnf install -y git

# 4. Verification
echo "--- Versions ---"
node --version
npm --version
git --version

echo "=== app.sh finished at $(date -u +%FT%TZ) ==="

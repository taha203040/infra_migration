#!/bin/bash
# k6.sh - Load Generator Bootstrap for Amazon Linux 2023
# AMI: ami-08e7e754b2c895da7 | Instance: t3.nano

exec > >(tee -a /var/log/k6-init.log) 2>&1
echo "=== k6.sh started at $(date -u +%FT%TZ) ==="

# 1. Update the instance
echo "--- Updating system ---"
dnf update -y

# 2. Install prerequisites
echo "--- Installing prerequisites ---"
dnf install -y curl tar

# 3. Install k6 via official RPM repository (x86_64)
echo "--- Installing k6 ---"
dnf install -y https://dl.k6.io/rpm/repo.rpm
dnf install -y k6

# 4. Verification
echo "--- k6 version ---"
k6 version

echo "=== k6.sh finished at $(date -u +%FT%TZ) ==="

```bash
#!/bin/bash

set -euo pipefail

# Configuration
REPO="taha203040/infra_migration"
TF_DIR="${TF_DIR:-.}"

echo "=== Terraform to GitHub Secrets ==="

# Check required tools
command -v terraform >/dev/null || {
    echo "Error: Terraform is not installed."
    exit 1
}

command -v gh >/dev/null || {
    echo "Error: GitHub CLI is not installed."
    exit 1
}

# Check GitHub authentication
gh auth status

# Enter Terraform directory
cd "$TF_DIR"

# Check Terraform initialization
if [ ! -d ".terraform" ]; then
    echo "Error: Terraform is not initialized. Run terraform init first."
    exit 1
fi

# Check Terraform outputs
terraform output >/dev/null

# Read Terraform output and store it as a GitHub secret
set_secret_from_output() {
    local SECRET_NAME="$1"
    local OUTPUT_NAME="$2"
    local VALUE

    echo "Reading Terraform output: $OUTPUT_NAME"

    VALUE=$(terraform output -raw "$OUTPUT_NAME")

    if [ -z "$VALUE" ]; then
        echo "Error: Output $OUTPUT_NAME is empty."
        exit 1
    fi

    printf '%s' "$VALUE" | gh secret set "$SECRET_NAME" -R "$REPO"

    echo "Updated secret: $SECRET_NAME"
}

echo "--- Configuring infrastructure secrets ---"

# Application EC2
set_secret_from_output APP_EC2_HOST app_public_ip
set_secret_from_output EC_APP_PRV app_private_ip

# Database EC2
set_secret_from_output DB_EC2_HOST database_public_ip
set_secret_from_output DB_PRV_IP database_private_ip

# K6 / Load Generator EC2
set_secret_from_output K6_EC2_HOST load_generator_public_ip

echo "--- Configuring EC2 username ---"

printf '%s' "ec2-user" | gh secret set EC2_USER -R "$REPO"

# Database password
echo "--- Configuring database password ---"

read -rsp "Enter database password: " DB_PASSWORD
echo

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: Database password cannot be empty."
    exit 1
fi

printf '%s' "$DB_PASSWORD" | gh secret set DB_PASSWORD -R "$REPO"
unset DB_PASSWORD

# SSH private key
echo "--- Configuring SSH private key ---"

read -rp "Enter path to your EC2 .pem file: " SSH_KEY_PATH

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Error: SSH key file not found."
    exit 1
fi

gh secret set EC2_SSH_KEY -R "$REPO" < "$SSH_KEY_PATH"

echo ""
echo "======================================"
echo "✅Successfully configured GitHub Secrets✅"
echo "======================================"
```

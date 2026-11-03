
#!/bin/bash

set -e

REPO="taha203040/infra_migration"

# Check GitHub CLI authentication
gh auth status

echo "Configuring GitHub Actions secrets..."

# Infrastructure IPs
gh secret set APP_EC2_HOST -R "$REPO" --body "13.61.196.232"
gh secret set DB_EC2_HOST -R "$REPO" --body "51.21.255.104"
gh secret set DB_PRV_IP -R "$REPO" --body "10.0.1.69"
gh secret set EC_APP_PRV -R "$REPO" --body "10.0.1.115"
gh secret set K6_EC2_HOST -R "$REPO" --body "13.50.4.91"

# EC2 configuration
gh secret set EC2_USER -R "$REPO" --body "ec2-user"

# Database password
read -rsp "Enter database password: " DB_PASSWORD
echo
gh secret set DB_PASSWORD -R "$REPO" --body "$DB_PASSWORD"
unset DB_PASSWORD

# SSH private key
read -rp "../migration_key.pem.pem file: " SSH_KEY_PATH

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "Error: SSH key file not found."
    exit 1
fi

gh secret set EC2_SSH_KEY -R "$REPO" < "$SSH_KEY_PATH"

echo "Successfully configured all repository secrets!"

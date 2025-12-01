#!/usr/bin/env bash
set -euo pipefail

DOMAIN="$1"
ENV="${2:-prod}"
TFVARS="terraform.tfvars"

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain> [environment]"
  exit 1
fi

# Create minimal tfvars for new domain (this repo is param-driven; adapt for single-domain)
cat > /tmp/onboard.tfvars <<EOF
domain = "${DOMAIN}"
environment = "${ENV}"
EOF

echo "Running terraform plan for onboarding domain ${DOMAIN}"
terraform init -upgrade
terraform plan -var-file=/tmp/onboard.tfvars
echo "If plan looks good, run: terraform apply -var-file=/tmp/onboard.tfvars"

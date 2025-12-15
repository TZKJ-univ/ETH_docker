#!/bin/bash
set -e

echo "Starting Validator Key Import..."
echo "You will be asked for:"
echo "1. A NEW password for the Prysm wallet (create one now or skip if reusing)."
echo "2. The keystore password you created during key generation."

# Run import command using the validator service configuration
# We map the keys directory in docker-compose, so we can access them at /keys
docker-compose run --rm validator \
  accounts import \
  --keys-dir=/keys \
  --wallet-dir=/data/wallet \
  --chain-config-file=/config/config.yaml

echo ""
echo "Import complete."
echo "Now ensuring the validator service is running..."
docker-compose up -d validator
docker-compose logs -f validator

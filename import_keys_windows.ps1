# PowerShell script to import validator keys
Write-Host "Starting Validator Key Import..."
Write-Host "You will be asked for:"
Write-Host "1. A NEW password for the Prysm wallet (create one now or skip if reusing)."
Write-Host "2. The keystore password you created during key generation."

# Run import command using the validator service configuration
docker-compose run --rm validator `
  accounts import `
  --keys-dir=/keys `
  --wallet-dir=/data/wallet `
  --chain-config-file=/config/config.yaml

Write-Host "Import complete."
Write-Host "Now ensuring the validator service is running..."
docker-compose up -d validator
docker-compose logs -f validator

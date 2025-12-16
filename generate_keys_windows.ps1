# PowerShell script to generate validator keys interactively
Write-Host "Starting validator key generation..."
Write-Host "Follow the prompts. You will need to create a password and write down your mnemonic."

docker run -it --rm `
  -v $PWD/validator_keys:/app/validator_keys `
  ghcr.io/ethstaker/ethstaker-deposit-cli:latest `
  new-mnemonic `
  --num_validators 1 `
  --mnemonic_language english `
  --chain ephemery

Write-Host "Key generation complete."
Write-Host "Please proceed to https://launchpad.ephemery.dev/ to deposit using the generated deposit_data-*.json file."

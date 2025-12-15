#!/bin/bash
set -e

# Load node variables
if [ -f "ephemery_config/nodevars_env.txt" ]; then
    source ephemery_config/nodevars_env.txt
else
    echo "Error: ephemery_config/nodevars_env.txt not found."
    exit 1
fi

echo "Start generating validator keys..."
echo "You will be asked to create a password and save your mnemonic."
echo "NOTE: When asked for 'Eth1 Withdrawal Address', you can enter your address:"
echo "0xb5be71904f0f4f59c4e389bfd9382c6b3208ed2d"
echo "(Make sure to rely on the CLI's validation or skip if unsure)"

mkdir -p validator_keys

# Run EthStaker deposit-cli
docker run -it --rm \
  -v $(pwd)/validator_keys:/app/validator_keys \
  ghcr.io/ethstaker/ethstaker-deposit-cli:latest \
  new-mnemonic \
  --num_validators=1 \
  --mnemonic_language=english \
  --chain=ephemery
  # Removed --eth1_withdrawal_address to avoid checksum errors. Enter manually if needed.

echo ""
echo "Keys generated in ./validator_keys"
echo "Next steps:"
echo "1. Upload 'deposit_data-*.json' to https://launchpad.ephemery.dev/"
echo "2. Run import script (to be created) to load keys into Prysm."

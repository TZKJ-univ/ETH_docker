#!/bin/bash
set -e

# Check and download configuration
if [ ! -f "ephemery_config/nodevars_env.txt" ]; then
    echo "Downloading latest Ephemery configuration..."
    curl -L -o testnet-all.tar.gz https://github.com/ephemery-testnet/ephemery-genesis/releases/latest/download/testnet-all.tar.gz
    mkdir -p ephemery_config
    tar -xzf testnet-all.tar.gz -C ephemery_config
    rm testnet-all.tar.gz
fi

# Create JWT secret if missing
if [ ! -f "data/jwtsecret" ]; then
    echo "Generating JWT secret..."
    mkdir -p data
    openssl rand -hex 32 | tr -d "\n" > data/jwtsecret
fi

# Load node variables
source ephemery_config/nodevars_env.txt

echo "Setting up Ephemery Testnet..."

# Create .env file for docker-compose
echo "Creating .env file..."
cat <<EOF > .env
EPHEMERY_BOOTNODES_GETH=$BOOTNODE_ENODE_LIST
EPHEMERY_BOOTNODE_PRYSM=$BOOTNODE_ENR
EOF

# Initialize Geth Genesis
echo "Initializing Geth Genesis..."
mkdir -p ethereum_data_ephemery/geth
docker run --rm \
    -v $(pwd)/ephemery_config:/config \
    -v $(pwd)/ethereum_data_ephemery/geth:/root/.ethereum \
    ethereum/client-go:stable \
    --datadir /root/.ethereum \
    init /config/genesis.json

echo "Starting containers..."
docker-compose up -d

echo "Ephemery setup complete. Check logs with 'docker-compose logs -f'"

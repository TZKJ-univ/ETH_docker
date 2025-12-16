# PowerShell script to setup Ephemery Testnet
$ErrorActionPreference = "Stop"

# 1. Download Configuration
if (-not (Test-Path "ephemery_config/nodevars_env.txt")) {
    Write-Host "Downloading latest Ephemery configuration..."
    $url = "https://github.com/ephemery-testnet/ephemery-genesis/releases/latest/download/testnet-all.tar.gz"
    $output = "testnet-all.tar.gz"
    Invoke-WebRequest -Uri $url -OutFile $output
    
    New-Item -ItemType Directory -Force -Path "ephemery_config" | Out-Null
    tar -xzf $output -C ephemery_config
    Remove-Item $output
}

# 2. Create JWT secret
if (-not (Test-Path "data/jwtsecret")) {
    Write-Host "Generating JWT secret..."
    New-Item -ItemType Directory -Force -Path "data" | Out-Null
    $randomHex = -join ((0..31) | ForEach-Object { "{0:x2}" -f (Get-Random -Max 256) })
    Set-Content -Path "data/jwtsecret" -Value $randomHex -NoNewline
}

# 3. Load node variables and create .env
Write-Host "Reading node variables..."
$envContent = Get-Content "ephemery_config/nodevars_env.txt"
$bootnodes_geth = ""
$bootnode_prysm = ""

foreach ($line in $envContent) {
    if ($line -match '^BOOTNODE_ENODE_LIST=(.*)') {
        $bootnodes_geth = $matches[1].Trim('"')
    }
    if ($line -match '^BOOTNODE_ENR=(.*)') {
        $bootnode_prysm = $matches[1].Trim('"')
    }
}

Write-Host "Creating .env file..."
$envFileContent = "EPHEMERY_BOOTNODES_GETH=$bootnodes_geth`nEPHEMERY_BOOTNODE_PRYSM=$bootnode_prysm"
Set-Content -Path ".env" -Value $envFileContent -Encoding Ascii

# 4. Initialize Geth Genesis
Write-Host "Initializing Geth Genesis..."
New-Item -ItemType Directory -Force -Path "ethereum_data_ephemery/geth" | Out-Null
$pwd = Get-Location
docker run --rm `
    -v "$($pwd)/ephemery_config:/config" `
    -v "$($pwd)/ethereum_data_ephemery/geth:/root/.ethereum" `
    ethereum/client-go:stable `
    --datadir /root/.ethereum `
    init /config/genesis.json

# 5. Start containers
Write-Host "Starting containers..."
docker-compose up -d

Write-Host "Ephemery setup complete. Check logs with 'docker-compose logs -f'"

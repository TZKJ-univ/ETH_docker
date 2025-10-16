# Ethereum Node Setup Script
# This script creates necessary directories and generates JWT secret

# Check for Docker and Docker Compose
try {
    docker --version | Out-Null
    docker-compose --version | Out-Null
}
catch {
    Write-Host "Error: Docker or Docker Compose is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Create necessary directories
$directories = @(
    "./data",
    "./ethereum_data",
    "./ethereum_data/geth",
    "./ethereum_data/beacon"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Generate JWT secret
$jwtPath = "./data/jwtsecret"
if (-not (Test-Path $jwtPath)) {
    Write-Host "Generating JWT secret..." -ForegroundColor Cyan
    
    # Generate 32 bytes of random hex
    $randomHex = (0..31 | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) }) -join ''
    
    # Save to file
    Set-Content -Path $jwtPath -Value $randomHex -NoNewline
    
    Write-Host "JWT secret generated: $jwtPath" -ForegroundColor Green
    Write-Host "Value: $randomHex"
}
else {
    $jwtContent = Get-Content -Path $jwtPath -Raw
    Write-Host "Using existing JWT secret: $jwtPath" -ForegroundColor Yellow
    Write-Host "Value: $jwtContent"
}

# Check Docker ports
function Test-PortInUse {
    param (
        [int] $Port
    )
    
    $result = $null
    try {
        $result = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    }
    catch {}
    
    return $null -ne $result
}

$portsToCheck = @(30305, 8565, 8566, 8552, 9001, 5052)
$portsInUse = @()

foreach ($port in $portsToCheck) {
    if (Test-PortInUse -Port $port) {
        $portsInUse += $port
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "Warning: The following ports are already in use:" -ForegroundColor Yellow
    foreach ($port in $portsInUse) {
        Write-Host " - $port" -ForegroundColor Yellow
    }
    Write-Host "Consider changing port settings in the docker-compose.yml file to avoid conflicts." -ForegroundColor Yellow
}

Write-Host "`nSetup complete. Run the following command to start your node:" -ForegroundColor Cyan
Write-Host "docker-compose up -d" -ForegroundColor White

Write-Host "`n--- Ethereum Node Management Commands ---" -ForegroundColor Cyan
Write-Host "Start: docker-compose up -d" -ForegroundColor White
Write-Host "Stop: docker-compose down" -ForegroundColor White
Write-Host "View logs: docker-compose logs" -ForegroundColor White
Write-Host "View execution client (Geth) logs: docker-compose logs geth" -ForegroundColor White
Write-Host "View consensus client (Teku) logs: docker-compose logs beacon" -ForegroundColor White
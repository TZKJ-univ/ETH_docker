# JWT Secret の作成
$dataDir = "d:\eth_testnet\data"
$jwtPath = "$dataDir\jwtsecret"

# ディレクトリがなければ作成
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force
}

# JWT Secret を生成 (32バイト = 64桁の16進数)
$randomBytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($randomBytes)
$jwtSecret = [System.BitConverter]::ToString($randomBytes) -replace '-',''

# ファイルに保存
Set-Content -Path $jwtPath -Value $jwtSecret -NoNewline

Write-Host "JWT Secret が作成されました: $jwtPath"
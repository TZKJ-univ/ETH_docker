# Ethereum ノードセットアップスクリプト
# このスクリプトは必要なディレクトリ構造を作成し、JWTシークレットを生成します

# 環境チェック
try {
    docker --version | Out-Null
    docker-compose --version | Out-Null
}
catch {
    Write-Host "エラー: Docker または Docker Compose がインストールされていないか、Pathに含まれていません。" -ForegroundColor Red
    Write-Host "Docker Desktop をインストールしてください。" -ForegroundColor Red
    exit 1
}

# 必要なディレクトリ構造を作成
$directories = @(
    "./data",
    "./ethereum_data",
    "./ethereum_data/geth",
    "./ethereum_data/beacon"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "ディレクトリを作成しました: $dir" -ForegroundColor Green
    }
}

# JWTシークレットを生成
$jwtPath = "./data/jwtsecret"
if (-not (Test-Path $jwtPath)) {
    Write-Host "JWTシークレットを生成しています..." -ForegroundColor Cyan
    
    # 32バイトのランダムな16進数文字列を生成
    $randomHex = (0..31 | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) }) -join ''
    
    # ファイルに保存
    Set-Content -Path $jwtPath -Value $randomHex -NoNewline
    
    Write-Host "JWTシークレットを生成しました: $jwtPath" -ForegroundColor Green
    Write-Host "値: $randomHex"
}
else {
    $jwtContent = Get-Content -Path $jwtPath -Raw
    Write-Host "既存のJWTシークレットを使用します: $jwtPath" -ForegroundColor Yellow
    Write-Host "値: $jwtContent"
}

# Dockerポートの使用状況をチェック
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
    Write-Host "警告: 以下のポートが既に使用されています:" -ForegroundColor Yellow
    foreach ($port in $portsInUse) {
        Write-Host " - $port" -ForegroundColor Yellow
    }
    Write-Host "競合を避けるために docker-compose.yml ファイルでポート設定を変更することをお勧めします。" -ForegroundColor Yellow
}

Write-Host "`nセットアップが完了しました。次のコマンドを実行してノードを起動してください:" -ForegroundColor Cyan
Write-Host "docker-compose up -d" -ForegroundColor White

Write-Host "`n--- Ethereumノードの管理コマンド ---" -ForegroundColor Cyan
Write-Host "起動: docker-compose up -d" -ForegroundColor White
Write-Host "停止: docker-compose down" -ForegroundColor White
Write-Host "ログ表示: docker-compose logs" -ForegroundColor White
Write-Host "実行クライアント (Geth) のログ表示: docker-compose logs geth" -ForegroundColor White
Write-Host "コンセンサスクライアント (Teku) のログ表示: docker-compose logs beacon" -ForegroundColor White
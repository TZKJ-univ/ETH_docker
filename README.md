# Ethereum フルノード (geth) を Docker Compose で立てる

これはローカルまたはサーバ上で Ethereum のフルノード（execution layer）とBeaconノード（consensus layer）をコンテナで動かすための構成です。Sepoliaテストネット対応で、異なる環境でも簡単にセットアップできるように設計されています。

## ファイル構成
- `docker-compose.yml` - Geth と Teku (Beacon) コンテナ定義
- `setup.bat` - Windows用セットアップヘルパー（PowerShellスクリプト実行用）
- `setup.ps1` - Windows用セットアップスクリプト
- `setup.sh` - Linux/macOS用セットアップスクリプト
- `restart_geth.sh` - Gethコンテナ48時間ごと自動再起動スクリプト
- `data/` - JWTシークレットなどの共有データ
- `ethereum_data/` - チェーンデータ保存用ディレクトリ

## 特徴
- Geth の stable イメージとTeku最新イメージを使用
- スナップ同期（syncmode: snap）で高速起動
- 永続ボリュームでチェーンデータを保持
- HTTP RPC、WebSocket、Auth RPCおよびBeacon APIを公開
- クロスプラットフォーム対応（Windows、Linux、macOS）

## クロスプラットフォームセットアップ方法

### Windows での実行手順：
1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) をインストール
2. このフォルダを任意の場所にコピー
3. `setup.bat` をダブルクリックまたは管理者として実行
4. 表示される指示に従って操作
5. `docker-compose up -d` でノードを起動

### Linux/macOS での実行手順：
1. Docker と Docker Compose をインストール
   ```bash
   # Ubuntu/Debian の例
   sudo apt update
   sudo apt install docker.io docker-compose
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker $USER  # ログアウト後再ログインが必要
   ```
2. このフォルダを任意の場所にコピー
3. セットアップスクリプトに実行権限を付与して実行
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
4. 表示される指示に従って操作
5. `docker-compose up -d` でノードを起動

## 使い方

### コンテナの基本操作
```bash
# ノードの起動
docker-compose up -d

# ノードの停止
docker-compose down

# ノードの再起動
docker-compose restart
```

### ログの確認

```bash
# すべてのコンテナのログを確認
docker-compose logs

# 実行レイヤー (Geth) のログをリアルタイムで確認
docker-compose logs -f geth

# コンセンサスレイヤー (Teku) のログをリアルタイムで確認
docker-compose logs -f beacon
```

### 同期状況の確認

以下は同期状況確認の例（HTTP RPC が Windowsでは 8565、Linux/macOSでは設定に応じたポートで待ち受けている想定）:

#### Windowsでの実行レイヤー同期確認（PowerShell）

```powershell
# 同期状況確認
$body = '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
Invoke-RestMethod -Uri http://localhost:8565 -Method Post -Body $body -ContentType 'application/json'

# 現在のブロック番号確認
$body = '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
Invoke-RestMethod -Uri http://localhost:8565 -Method Post -Body $body -ContentType 'application/json'
```

#### Linux/macOSでの実行レイヤー同期確認

```bash
# 同期状況確認
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8565

# 現在のブロック番号確認
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8565
```

戻り値が `false` の場合は同期済みです。同期中はオブジェクトを返します（startingBlock, currentBlock, highestBlock など）。

### コンセンサスレイヤー (Beacon) の確認

```bash
# Windows (PowerShell)
Invoke-RestMethod -Uri http://localhost:5052/eth/v1/node/syncing -Method Get

# Linux/macOS
curl http://localhost:5052/eth/v1/node/syncing
```

### ネットワーク情報の確認

```bash
# Windows (PowerShell)
$body = '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'
Invoke-RestMethod -Uri http://localhost:8565 -Method Post -Body $body -ContentType 'application/json'

# Linux/macOS
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://localhost:8565
```

### 応答の見方

- `eth_syncing` が `false` の場合: 同期済み
- `eth_blockNumber` の応答: 0x... の16進数で現在のブロック番号
- Sepoliaテストネットの `net_version`: "11155111"

## Gethコンテナの自動再起動（48時間ごと）

長時間稼働しているGethコンテナは、メモリリークやパフォーマンス低下を起こす場合があります。
`restart_geth.sh`スクリプトは、48時間ごとにGethコンテナを自動的に再起動します。

### 使い方

```bash
# 実行権限を付与
chmod +x restart_geth.sh

# バックグラウンドで実行（nohupで永続実行）
nohup ./restart_geth.sh > /dev/null 2>&1 &

# プロセスIDを確認（必要に応じて停止する場合）
ps aux | grep restart_geth.sh
```

### 停止方法

```bash
# プロセスを検索
ps aux | grep restart_geth.sh

# プロセスを停止（PIDを確認してから）
kill <PID>
```

### ログの確認

再起動の履歴は `./logs/geth_restart.log` に記録されます:

```bash
# 最新20行を表示
tail -20 ./logs/geth_restart.log

# リアルタイムでログを監視
tail -f ./logs/geth_restart.log
```

### systemdサービスとして登録（推奨）

システム起動時に自動的に実行するには、systemdサービスとして登録します:

1. サービスファイルを作成:
```bash
sudo nano /etc/systemd/system/geth-restart.service
```

2. 以下の内容を記述（パスは適切に変更してください）:
```ini
[Unit]
Description=Geth Container Auto Restart Service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/eth_testnet
ExecStart=/path/to/eth_testnet/restart_geth.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

3. サービスを有効化して起動:
```bash
sudo systemctl daemon-reload
sudo systemctl enable geth-restart.service
sudo systemctl start geth-restart.service

# ステータス確認
sudo systemctl status geth-restart.service
```

## トラブルシューティング

### 基本的な確認
- コンテナが起動していない: `docker-compose ps` を実行して状態を確認
- ログでエラーを確認: `docker-compose logs geth` または `docker-compose logs beacon`
- ポート競合がある場合: セットアップスクリプトの警告を確認し、必要に応じて `docker-compose.yml` のポート設定を変更

### よくある問題
- **同期が遅い**: ネットワーク環境やマシン性能によっては同期に時間がかかります（数時間〜数日）
- **ディスク容量不足**: Ethereum チェーンデータは数百GB以上必要になる場合があります
- **メモリ不足**: コンテナに十分なメモリが割り当てられていることを確認
- **Docker Desktop の設定**: Windows/Mac では十分なリソース（CPU/メモリ/ディスク）が割り当てられているか確認

## カスタマイズ

### 別のEthereumネットワークを使用する場合

Mainnet、Goerliなどの別のネットワークを使用したい場合は、以下のファイルを編集します：

1. `docker-compose.yml` の `command` セクションで、Gethの `--sepolia` フラグを変更:
   - メインネット: フラグを削除
   - Goerli: `--goerli` に変更

2. `docker-compose.yml` の Teku コマンドで、`--network=sepolia` を変更:
   - メインネット: `--network=mainnet`
   - Goerli: `--network=goerli`

3. チェックポイント同期URLも該当ネットワークのものに更新

### 別のコンセンサスクライアントを使用する場合

Teku以外のコンセンサスクライアント（Lighthouse, Prysm, Nimbus, Lodestar）を使いたい場合は、`docker-compose.yml`の `beacon` サービスの設定を変更してください。各クライアントの詳細な設定は公式ドキュメントを参照してください。

## データの移行と保存

このセットアップでは、すべてのデータは `ethereum_data/` ディレクトリに保存されます。別のマシンに移行する場合は、このディレクトリをコピーするだけで、同期状態を維持できます。

## ライセンス

このプロジェクトはオープンソースで、自由に使用・変更・配布できます。

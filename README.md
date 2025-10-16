# Ethereum フルノード (geth) を Docker Compose で立てる

これはローカルまたはサーバ上で Ethereum のフルノード（execution layer）とBeaconノード（consensus layer）をコンテナで動かすための構成です。Sepoliaテストネット対応で、異なる環境でも簡単にセットアップできるように設計されています。

## ファイル構成
- `docker-compose.yml` - Geth と Teku (Beacon) コンテナ定義
- `setup.bat` - Windows用セットアップヘルパー（PowerShellスクリプト実行用）
- `setup.ps1` - Windows用セットアップスクリプト
- `setup.sh` - Linux/macOS用セットアップスクリプト
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

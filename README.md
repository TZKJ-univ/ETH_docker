# Ethereum フルノード (geth) を Docker Compose で立てる

これはローカルまたはサーバ上で Ethereum のフルノード（execution layer）をコンテナで動かすための最小構成です。バリデータは含まれません。

ファイル:
- `docker-compose.yml` - geth コンテナ定義と永続ボリューム

特徴:
- Geth の stable イメージを使用
- フル同期（syncmode: full）で起動
- 永続ボリュームでチェーンデータを保持
- HTTP RPC (8545) と WebSocket (8546) を公開

注意:
- `--gcmode archive` によりディスク使用量が大きくなります。不要なら `--gcmode=full` に変更してください。
- フルノードの同期には時間がかかります（数時間〜数日、ネットワーク状況・マシン性能による）。

使い方（PowerShell）:

1) 起動

```powershell
cd D:\eth_testnet
docker compose up -d
```

2) コンテナログを確認

```powershell
docker compose logs -f geth
```

3) 同期状況を確認 (RPC)

以下は PowerShell での例（HTTP RPC が 8545 で待ち受けている想定）:

```powershell
$body = '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
Invoke-RestMethod -Uri http://localhost:8545 -Method Post -Body $body -ContentType 'application/json'
```

戻り値が `false` の場合は同期済みです。同期中はオブジェクトを返します（startingBlock, currentBlock, highestBlock など）。

簡易的なブロック番号確認:

```powershell
$body = '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
Invoke-RestMethod -Uri http://localhost:8545 -Method Post -Body $body -ContentType 'application/json'
```

4) RPC を使った簡単な確認（例: net_version）:

```powershell
$body = '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'
Invoke-RestMethod -Uri http://localhost:8545 -Method Post -Body $body -ContentType 'application/json'
```

検証: 期待される応答の例

- `eth_syncing` が `false` の場合（同期済み）: HTTP 200 で JSON の result: false
- `eth_blockNumber` は 0x... の 16 進数で現在のブロック番号を返す

トラブルシューティングのヒント:

- コンテナが起動していない場合: `docker compose ps` を実行して状態を確認
- ログで errors/warnings を確認: `docker compose logs geth`
- ポート競合がある場合は `docker compose down` して `docker-compose.yml` のポート設定を変更してください

オプション: ビーコンノード（非バリデータ）について

このリポジトリには Beacon/Consensus 層のクライアントは含めていませんが、メインネットでフルノードを運用するには Beacon ノード（および必要ならバリデータ）を別コンテナで接続するのが一般的です。Beacon ノードを追加する場合のヒント:

- Lighthouse, Prysm, Teku などのクライアントを使う
- Beacon ノードは execution client (geth) の HTTP または IPC エンドポイントに接続して、engine API を通じて通信します
- バリデータを使わないで Beacon ノードだけを立てることも可能（スラッシュは発生しない）

簡単な追加例（概要）:

- docker-compose.yml に `beacon` サービスを追加
- 環境変数で `ETH1` / `EXECUTION_ENDPOINT=http://geth:8545` のように指定

必要なら、Beacon ノードの具体的な docker-compose テンプレートも追加します（要望があれば対応します）。

ライセンス: このファイルは自由に使ってください。

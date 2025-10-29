#!/bin/bash
# Geth実行コンテナ48時間ごと再起動スクリプト
# 使用方法: バックグラウンドで実行 (nohup ./restart_geth.sh &)

# 設定
INTERVAL_HOURS=48  # 48時間ごとに再起動
CONTAINER_NAME="geth-fullnode"
LOG_FILE="./logs/geth_restart.log"

# 色の設定
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ログディレクトリを作成
mkdir -p ./logs

# ログ関数
log_message() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[$timestamp]${NC} $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

log_error() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[$timestamp] エラー:${NC} $message"
    echo "[$timestamp] エラー: $message" >> "$LOG_FILE"
}

# Gethコンテナを再起動
restart_geth_container() {
    log_message "Gethコンテナの再起動を開始します..."
    
    local status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
    
    if [ -z "$status" ]; then
        log_error "コンテナ '$CONTAINER_NAME' が見つかりません"
        return 1
    fi
    
    log_message "現在の状態: $status"
    
    if docker restart "$CONTAINER_NAME"; then
        log_message "Gethコンテナの再起動に成功しました"
        sleep 5
        local new_status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        log_message "再起動後の状態: $new_status"
        return 0
    else
        log_error "コンテナの再起動に失敗しました"
        return 1
    fi
}

# メイン処理
log_message "=========================================="
log_message "Geth自動再起動スクリプト開始"
log_message "再起動間隔: $INTERVAL_HOURS 時間"
log_message "=========================================="

# 無限ループで48時間ごとに再起動
while true; do
    log_message "次回再起動: $INTERVAL_HOURS 時間後"
    
    # 48時間待機（172800秒）
    sleep $((INTERVAL_HOURS * 3600))
    
    # 再起動実行
    restart_geth_container
done

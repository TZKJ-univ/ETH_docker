#!/bin/bash
# Ethereum ノードセットアップスクリプト（Linux/macOS用）

# 色の設定
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Docker確認
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}エラー: Docker または Docker Compose がインストールされていません。${NC}"
    echo -e "${RED}https://docs.docker.com/get-docker/ からインストールしてください。${NC}"
    exit 1
fi

# ディレクトリ作成
directories=("./data" "./ethereum_data" "./ethereum_data/geth" "./ethereum_data/beacon")

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}ディレクトリを作成しました: $dir${NC}"
    fi
done

# JWTシークレット作成
JWT_PATH="./data/jwtsecret"
if [ ! -f "$JWT_PATH" ]; then
    echo -e "${CYAN}JWTシークレットを生成しています...${NC}"
    
    # 32バイトのランダム16進数を生成
    RANDOM_HEX=$(hexdump -n 32 -e '1/1 "%02x"' /dev/urandom)
    
    # ファイルに保存（改行なし）
    echo -n "$RANDOM_HEX" > "$JWT_PATH"
    
    echo -e "${GREEN}JWTシークレットを生成しました: $JWT_PATH${NC}"
    echo -e "値: $RANDOM_HEX"
else
    JWT_CONTENT=$(cat "$JWT_PATH")
    echo -e "${YELLOW}既存のJWTシークレットを使用します: $JWT_PATH${NC}"
    echo -e "値: $JWT_CONTENT"
fi

# ポートチェック（Linux/macOS版）
check_port() {
    if command -v lsof &> /dev/null; then
        lsof -i :$1 &> /dev/null
        return $?
    elif command -v netstat &> /dev/null; then
        netstat -tuln | grep ":$1 " &> /dev/null
        return $?
    else
        # ツールがない場合はチェックをスキップ
        return 1
    fi
}

PORTS=(30305 8565 8566 8552 9001 5052)
PORTS_IN_USE=()

for port in "${PORTS[@]}"; do
    if check_port $port; then
        PORTS_IN_USE+=($port)
    fi
done

if [ ${#PORTS_IN_USE[@]} -gt 0 ]; then
    echo -e "${YELLOW}警告: 以下のポートが既に使用されています:${NC}"
    for port in "${PORTS_IN_USE[@]}"; do
        echo -e "${YELLOW} - $port${NC}"
    done
    echo -e "${YELLOW}競合を避けるために docker-compose.yml ファイルでポート設定を変更することをお勧めします。${NC}"
fi

echo -e "\n${CYAN}セットアップが完了しました。次のコマンドを実行してノードを起動してください:${NC}"
echo "docker-compose up -d"

echo -e "\n${CYAN}--- Ethereumノードの管理コマンド ---${NC}"
echo "起動: docker-compose up -d"
echo "停止: docker-compose down"
echo "ログ表示: docker-compose logs"
echo "実行クライアント (Geth) のログ表示: docker-compose logs geth"
echo "コンセンサスクライアント (Teku) のログ表示: docker-compose logs beacon"
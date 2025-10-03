#!/bin/bash

# APIベースURL
# BASE_URL="http://48.218.233.183:9080/api/v1"
BASE_URL="http://130.33.167.204"

# ログファイル
LOG_FILE="api_monitoring.log"

# 色付きログ出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# APIリクエスト実行関数
make_request() {
    local endpoint=$1
    local description=$2
    
    log "Testing: $description"
    response=$(curl -s -w "\n%{http_code}" -H "apikey: gyZy82qfU2P8T192lUeHHmCqmlE40yjq" "$BASE_URL$endpoint")
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ SUCCESS${NC} - $endpoint (HTTP $http_code)"
        log "SUCCESS - $endpoint - HTTP $http_code"
    else
        echo -e "${RED}✗ FAILED${NC} - $endpoint (HTTP $http_code)"
        log "FAILED - $endpoint - HTTP $http_code"
    fi
    
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo "---"
}

# メイン監視ループ
main() {
    log "========== API Monitoring Started =========="
    
    # 全製品リスト取得
    make_request "/products" "Get all products"
    
    # 特定の製品詳細取得 (ID: 0, 1, 2)
    for id in 0 1 2; do
        make_request "/products/$id" "Get product details (ID: $id)"
    done
    
    # 製品レビュー取得
    for id in 0 1 2; do
        make_request "/products/$id/reviews" "Get product reviews (ID: $id)"
    done
    
    # 製品評価取得
    for id in 0 1 2; do
        make_request "/products/$id/ratings" "Get product ratings (ID: $id)"
    done
    
    log "========== API Monitoring Completed =========="
}

# スクリプト引数処理
if [ "$1" == "--loop" ]; then
    # 定期実行モード (デフォルト: 60秒間隔)
    INTERVAL=${2:-60}
    echo "Starting periodic monitoring (interval: ${INTERVAL}s)"
    echo "Press Ctrl+C to stop..."
    
    while true; do
        main
        echo -e "${YELLOW}Waiting ${INTERVAL} seconds...${NC}"
        sleep "$INTERVAL"
    done
else
    # 1回のみ実行
    main
fi

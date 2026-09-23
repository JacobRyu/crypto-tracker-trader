#!/bin/bash
# Redis テストデータ生成スクリプト
# 使い方: ./scripts/seed-redis.sh

set -e

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"

echo "=== Redis テストデータ生成 ==="
echo "接続先: ${REDIS_HOST}:${REDIS_PORT}"
echo ""

# Redis接続テスト
if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
  echo "エラー: Redisに接続できません"
  echo "Redisが起動していることを確認してください"
  exit 1
fi

echo "✓ Redis接続成功"
echo ""

# =====================================================
# 1. 価格キャッシュ（有効期限 60 秒）
# =====================================================
echo "--- 価格キャッシュ ---"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'price:BTC' '{"id":1,"symbol":"BTC","price_usd":"67500.00000000","source":"coingecko","fetched_at":"2026-09-23T12:00:00Z"}' EX 60
echo "✓ price:BTC"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'price:ETH' '{"id":2,"symbol":"ETH","price_usd":"3500.00000000","source":"coingecko","fetched_at":"2026-09-23T12:00:00Z"}' EX 60
echo "✓ price:ETH"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'price:SOL' '{"id":3,"symbol":"SOL","price_usd":"180.50000000","source":"coingecko","fetched_at":"2026-09-23T12:00:00Z"}' EX 60
echo "✓ price:SOL"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'price:DOGE' '{"id":4,"symbol":"DOGE","price_usd":"0.12000000","source":"coingecko","fetched_at":"2026-09-23T12:00:00Z"}' EX 60
echo "✓ price:DOGE"

echo ""

# =====================================================
# 2. ポートフォリオサマリキャッシュ（有効期限 300 秒）
# =====================================================
echo "--- ポートフォリオサマリキャッシュ ---"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'portfolio:summary:1' '{"user_id":1,"total_usd":"50500.00000000","wallet_usd":"8200.00000000","exchange_usd":"42300.00000000","defi_usd":"0.00000000","by_symbol":[{"symbol":"ETH","total_qty":"2.00000000","price_usd":"3500.00000000","value_usd":"7000.00000000","pct_share":"13.86"}],"by_source":[{"source":"wallet:ethereum","value_usd":"8200.00000000","pct_share":"16.24"},{"source":"exchange:binance","value_usd":"42300.00000000","pct_share":"83.76"}],"computed_at":"2026-09-23T12:00:00Z"}' EX 300
echo "✓ portfolio:summary:1"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'portfolio:summary:2' '{"user_id":2,"total_usd":"28500.00000000","wallet_usd":"8500.00000000","exchange_usd":"20000.00000000","defi_usd":"0.00000000","by_symbol":[{"symbol":"ETH","total_qty":"2.50000000","price_usd":"3500.00000000","value_usd":"8750.00000000","pct_share":"30.70"}],"by_source":[{"source":"wallet:ethereum","value_usd":"8500.00000000","pct_share":"29.82"},{"source":"exchange:coinbase","value_usd":"20000.00000000","pct_share":"70.18"}],"computed_at":"2026-09-23T12:00:00Z"}' EX 300
echo "✓ portfolio:summary:2"

echo ""

# =====================================================
# 3. ウォレットアセットキャッシュ（有効期限 120 秒）
# =====================================================
echo "--- ウォレットアセットキャッシュ ---"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'wallet:1:1:assets' '[{"id":1,"wallet_id":1,"chain":"ethereum","token_address":"0x0000000000000000000000000000000000000000","symbol":"ETH","balance":"1500000000000000000","updated_at":"2026-09-23T11:55:00Z"},{"id":2,"wallet_id":1,"chain":"ethereum","token_address":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","symbol":"USDC","balance":"5000000000","updated_at":"2026-09-23T11:55:00Z"}]' EX 120
echo "✓ wallet:1:1:assets"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'wallet:1:2:assets' '[{"id":3,"wallet_id":2,"chain":"polygon","token_address":"0x0000000000000000000000000000000000001010","symbol":"MATIC","balance":"20000000000000000000","updated_at":"2026-09-23T11:55:00Z"}]' EX 120
echo "✓ wallet:1:2:assets"

echo ""

# =====================================================
# 4. 取引所残高キャッシュ（有効期限 120 秒）
# =====================================================
echo "--- 取引所残高キャッシュ ---"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'exchange:balances:1' '[{"id":1,"credential_id":1,"user_id":1,"symbol":"BTC","free_balance":"0.50000000","locked_balance":"0.00000000","updated_at":"2026-09-23T11:50:00Z"},{"id":2,"credential_id":1,"user_id":1,"symbol":"USDT","free_balance":"10000.00000000","locked_balance":"5000.00000000","updated_at":"2026-09-23T11:50:00Z"},{"id":3,"credential_id":1,"user_id":1,"symbol":"ETH","free_balance":"2.00000000","locked_balance":"0.50000000","updated_at":"2026-09-23T11:50:00Z"}]' EX 120
echo "✓ exchange:balances:1"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'exchange:balances:2' '[{"id":4,"credential_id":2,"user_id":2,"symbol":"ETH","free_balance":"2.00000000","locked_balance":"0.00000000","updated_at":"2026-09-23T11:45:00Z"},{"id":5,"credential_id":2,"user_id":2,"symbol":"BTC","free_balance":"0.10000000","locked_balance":"0.00000000","updated_at":"2026-09-23T11:45:00Z"}]' EX 120
echo "✓ exchange:balances:2"

echo ""

# =====================================================
# 5. セッションキャッシュ（有効期限 3600 秒）
# =====================================================
echo "--- セッションキャッシュ ---"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'session:user:1' '{"user_id":1,"username":"alice","email":"alice@example.com","created_at":"2026-09-23T12:00:00Z"}' EX 3600
echo "✓ session:user:1"

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET 'session:user:2' '{"user_id":2,"username":"bob","email":"bob@example.com","created_at":"2026-09-23T12:00:00Z"}' EX 3600
echo "✓ session:user:2"

echo ""

# =====================================================
# サマリー
# =====================================================
echo "=== 完了 ==="
echo "格納されたキー:"
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" KEYS "*" | head -20
echo ""
echo "合計キー数: $(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DBSIZE | awk '{print $2}')"

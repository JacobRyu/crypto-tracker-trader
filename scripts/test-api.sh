#!/bin/bash
# API テストデータ生成スクリプト
# 使い方: ./scripts/test-api.sh

set -e

API_BASE="${API_BASE:-http://localhost:8081}"
OUTPUT_DIR="${OUTPUT_DIR:-.test-output}"

echo "=== API テストデータ生成 ==="
echo "APIエンドポイント: ${API_BASE}"
echo "出力先: ${OUTPUT_DIR}"
echo ""

# 出力ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# =====================================================
# 1. ヘルスチェック
# =====================================================
echo "--- 1. ヘルスチェック ---"
HEALTH=$(curl -s "${API_BASE}/health")
echo "レスポンス: $HEALTH"
echo ""

# =====================================================
# 2. ユーザー登録（alice）
# =====================================================
echo "--- 2. ユーザー登録 (alice) ---"
ALICE_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "email": "alice@example.com",
    "password": "securepass123"
  }')
echo "レスポンス: $ALICE_RESPONSE"

# トークン抽出
ALICE_TOKEN=$(echo "$ALICE_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
echo "$ALICE_TOKEN" > "$OUTPUT_DIR/alice_token.txt"
echo "✓ トークン保存: $OUTPUT_DIR/alice_token.txt"
echo ""

# =====================================================
# 3. ユーザー登録（bob）
# =====================================================
echo "--- 3. ユーザー登録 (bob) ---"
BOB_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "bob",
    "email": "bob@example.com",
    "password": "securepass456"
  }')
echo "レスポンス: $BOB_RESPONSE"

# トークン抽出
BOB_TOKEN=$(echo "$BOB_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
echo "$BOB_TOKEN" > "$OUTPUT_DIR/bob_token.txt"
echo "✓ トークン保存: $OUTPUT_DIR/bob_token.txt"
echo ""

# =====================================================
# 4. ログイン（alice）
# =====================================================
echo "--- 4. ログイン (alice) ---"
LOGIN_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "securepass123"
  }')
echo "レスポンス: $LOGIN_RESPONSE"
echo ""

# =====================================================
# 5. ウォレット追加（alice）
# =====================================================
echo "--- 5. ウォレット追加 (alice) ---"
if [ -n "$ALICE_TOKEN" ]; then
  WALLET_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/wallets" \
    -H "Authorization: Bearer $ALICE_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "chain": "ethereum",
      "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18",
      "label": "Main ETH Wallet"
    }')
  echo "レスポンス: $WALLET_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 6. ウォレット一覧取得（alice）
# =====================================================
echo "--- 6. ウォレット一覧取得 (alice) ---"
if [ -n "$ALICE_TOKEN" ]; then
  WALLETS_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/wallets" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $WALLETS_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 7. 価格取得（BTC）
# =====================================================
echo "--- 7. 価格取得 (BTC) ---"
if [ -n "$ALICE_TOKEN" ]; then
  PRICE_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/prices/BTC" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $PRICE_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 8. 価格履歴取得（ETH）
# =====================================================
echo "--- 8. 価格履歴取得 (ETH) ---"
if [ -n "$ALICE_TOKEN" ]; then
  HISTORY_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/prices/ETH/history?limit=10" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $HISTORY_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 9. 価格同期トリガー
# =====================================================
echo "--- 9. 価格同期トリガー ---"
if [ -n "$ALICE_TOKEN" ]; then
  SYNC_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/prices/sync" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $SYNC_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 10. ポートフォリオサマリー取得
# =====================================================
echo "--- 10. ポートフォリオサマリー取得 ---"
if [ -n "$ALICE_TOKEN" ]; then
  SUMMARY_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/portfolio/summary" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $SUMMARY_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 11. ポートフォリオ割当取得
# =====================================================
echo "--- 11. ポートフォリオ割当取得 ---"
if [ -n "$ALICE_TOKEN" ]; then
  ALLOCATION_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/portfolio/allocation" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $ALLOCATION_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 12. ポートフォリオ履歴取得
# =====================================================
echo "--- 12. ポートフォリオ履歴取得 ---"
if [ -n "$ALICE_TOKEN" ]; then
  PORTFOLIO_HISTORY_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/portfolio/history" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $PORTFOLIO_HISTORY_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 13. 取引所クレデンシャル追加
# =====================================================
echo "--- 13. 取引所クレデンシャル追加 (binance) ---"
if [ -n "$ALICE_TOKEN" ]; then
  EXCHANGE_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/exchanges" \
    -H "Authorization: Bearer $ALICE_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "exchange": "binance",
      "api_key": "test-api-key-12345",
      "api_secret": "test-api-secret-67890"
    }')
  echo "レスポンス: $EXCHANGE_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 14. 取引所クレデンシャル一覧取得
# =====================================================
echo "--- 14. 取引所クレデンシャル一覧取得 ---"
if [ -n "$ALICE_TOKEN" ]; then
  EXCHANGES_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/exchanges" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $EXCHANGES_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 15. 取引所残高取得
# =====================================================
echo "--- 15. 取引所残高取得 ---"
if [ -n "$ALICE_TOKEN" ]; then
  BALANCES_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/exchanges/balances" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $BALANCES_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 16. DeFi ポジション取得
# =====================================================
echo "--- 16. DeFi ポジション取得 ---"
if [ -n "$ALICE_TOKEN" ]; then
  DEFI_RESPONSE=$(curl -s -X GET "${API_BASE}/api/v1/defi/positions" \
    -H "Authorization: Bearer $ALICE_TOKEN")
  echo "レスポンス: $DEFI_RESPONSE"
else
  echo "スキップ: トークンがありません"
fi
echo ""

# =====================================================
# 17. メトリクス取得
# =====================================================
echo "--- 17. メトリクス取得 ---"
METRICS_RESPONSE=$(curl -s "${API_BASE}/metrics")
echo "レスポンス（最初の5行）:"
echo "$METRICS_RESPONSE" | head -5
echo ""

# =====================================================
# サマリー
# =====================================================
echo "=== 完了 ==="
echo "トークンファイル:"
ls -la "$OUTPUT_DIR"/*.txt 2>/dev/null || echo "  なし"
echo ""
echo "APIリクエスト実行回数: 17"

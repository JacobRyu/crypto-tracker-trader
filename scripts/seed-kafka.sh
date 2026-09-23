#!/bin/bash
# Kafka テストデータ生成スクリプト
# 使い方: ./scripts/seed-kafka.sh

set -e

KAFKA_BROKER="${KAFKA_BROKER:-localhost:9092}"
TOPIC="${KAFKA_TOPIC:-price-events}"

echo "=== Kafka テストデータ生成 ==="
echo "ブローカー: ${KAFKA_BROKER}"
echo "トピック: ${TOPIC}"
echo ""

# Kafka接続テスト
if ! kafka-topics --bootstrap-server "$KAFKA_BROKER" --list > /dev/null 2>&1; then
  echo "エラー: Kafkaに接続できません"
  echo "Kafkaが起動していることを確認してください"
  exit 1
fi

echo "✓ Kafka接続成功"
echo ""

# トピック存在確認（なければ作成）
if ! kafka-topics --bootstrap-server "$KAFKA_BROKER" --list | grep -q "^${TOPIC}$"; then
  echo "トピック '${TOPIC}' を作成します..."
  kafka-topics --bootstrap-server "$KAFKA_BROKER" \
    --create \
    --topic "$TOPIC" \
    --partitions 3 \
    --replication-factor 1
  echo "✓ トピック作成完了"
fi

echo ""

# =====================================================
# 1. 価格イベントメッセージ
# =====================================================
echo "--- 価格イベントメッセージ ---"

# タイムスタンプ生成（Unix秒）
NOW=$(date +%s)
HOUR_AGO=$((NOW - 3600))
MIN_AGO=$((NOW - 300))

# BTC 価格イベント
echo '{"symbol":"BTC","price_usd":"67500.00000000","source":"coingecko","timestamp":'$NOW'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
BTC:{"symbol":"BTC","price_usd":"67500.00000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ BTC 価格イベント (現在)"

# ETH 価格イベント
echo '{"symbol":"ETH","price_usd":"3500.00000000","source":"coingecko","timestamp":'$NOW'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
ETH:{"symbol":"ETH","price_usd":"3500.00000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ ETH 価格イベント (現在)"

# SOL 価格イベント
echo '{"symbol":"SOL","price_usd":"180.50000000","source":"coingecko","timestamp":'$NOW'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
SOL:{"symbol":"SOL","price_usd":"180.50000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ SOL 価格イベント (現在)"

# DOGE 価格イベント
echo '{"symbol":"DOGE","price_usd":"0.12000000","source":"coingecko","timestamp":'$NOW'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
DOGE:{"symbol":"DOGE","price_usd":"0.12000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ DOGE 価格イベント (現在)"

# BNB 価格イベント
echo '{"symbol":"BNB","price_usd":"580.00000000","source":"coingecko","timestamp":'$NOW'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
BNB:{"symbol":"BNB","price_usd":"580.00000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ BNB 価格イベント (現在)"

echo ""

# =====================================================
# 2. 過去の価格イベント（1時間前）
# =====================================================
echo "--- 過去の価格イベント ---"

echo '{"symbol":"BTC","price_usd":"67200.00000000","source":"coingecko","timestamp":'$HOUR_AGO'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
BTC:{"symbol":"BTC","price_usd":"67200.00000000","source":"coingecko","timestamp":$HOUR_AGO}
EOF
echo "✓ BTC 価格イベント (1時間前)"

echo '{"symbol":"ETH","price_usd":"3480.00000000","source":"coingecko","timestamp":'$HOUR_AGO'}' | \
  kafka-console-producer --bootstrap-server "$KAFKA_BROKER" --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
ETH:{"symbol":"ETH","price_usd":"3480.00000000","source":"coingecko","timestamp":$HOUR_AGO}
EOF
echo "✓ ETH 価格イベント (1時間前)"

echo ""

# =====================================================
# 3. メッセージ確認
# =====================================================
echo "--- メッセージ確認 ---"
echo "直近5件のメッセージ:"
timeout 2 kafka-console-consumer --bootstrap-server "$KAFKA_BROKER" \
  --topic "$TOPIC" \
  --from-beginning \
  --max-messages 10 2>/dev/null || true

echo ""

# =====================================================
# サマリー
# =====================================================
echo "=== 完了 ==="
echo "送信されたメッセージ: 7件"
echo "  - BTC: 2件 (現在, 1時間前)"
echo "  - ETH: 2件 (現在, 1時間前)"
echo "  - SOL: 1件 (現在)"
echo "  - DOGE: 1件 (現在)"
echo "  - BNB: 1件 (現在)"

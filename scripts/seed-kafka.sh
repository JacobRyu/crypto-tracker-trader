#!/bin/bash
# Kafka テストデータ生成スクリプト（Pod内kubectl exec）
# 使い方: ./scripts/seed-kafka.sh

set -e

NAMESPACE="${NAMESPACE:-ctt-dev}"
TOPIC="${KAFKA_TOPIC:-price-events}"
KAFKA_BIN="/opt/kafka/bin"

echo "=== Kafka テストデータ生成 ==="
echo "名前空間: ${NAMESPACE}"
echo "トピック: ${TOPIC}"
echo ""

# Kafkaポッド名を取得
KAFKA_POD=$(kubectl get pods -n "$NAMESPACE" -l app=kafka -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$KAFKA_POD" ]; then
  echo "エラー: Kafkaポッドが見つかりません"
  echo "Podが起動していることを確認してください: kubectl get pods -n $NAMESPACE"
  exit 1
fi

echo "対象ポッド: ${KAFKA_POD}"
echo ""

# Kafka接続テスト
if ! kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
  echo "エラー: Kafkaに接続できません"
  exit 1
fi

echo "✓ Kafka接続成功"
echo ""

# トピック存在確認（なければ作成）
if ! kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server localhost:9092 --list 2>/dev/null | grep -q "^${TOPIC}$"; then
  echo "トピック '${TOPIC}' を作成します..."
  kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server localhost:9092 \
    --create \
    --topic "$TOPIC" \
    --partitions 3 \
    --replication-factor 1
  echo "✓ トピック作成完了"
fi

echo ""

# タイムスタンプ生成（Unix秒）
NOW=$(date +%s)
HOUR_AGO=$((NOW - 3600))

# =====================================================
# 1. 価格イベントメッセージ
# =====================================================
echo "--- 価格イベントメッセージ ---"

# BTC
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
BTC:{"symbol":"BTC","price_usd":"67500.00000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ BTC 価格イベント (現在)"

# ETH
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
ETH:{"symbol":"ETH","price_usd":"3500.00000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ ETH 価格イベント (現在)"

# SOL
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
SOL:{"symbol":"SOL","price_usd":"180.50000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ SOL 価格イベント (現在)"

# DOGE
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
DOGE:{"symbol":"DOGE","price_usd":"0.12000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ DOGE 価格イベント (現在)"

# BNB
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
BNB:{"symbol":"BNB","price_usd":"580.00000000","source":"coingecko","timestamp":$NOW}
EOF
echo "✓ BNB 価格イベント (現在)"

echo ""

# =====================================================
# 2. 過去の価格イベント（1時間前）
# =====================================================
echo "--- 過去の価格イベント ---"

kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
BTC:{"symbol":"BTC","price_usd":"67200.00000000","source":"coingecko","timestamp":$HOUR_AGO}
EOF
echo "✓ BTC 価格イベント (1時間前)"

kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --property parse.key=true --property key.separator=: <<EOF
ETH:{"symbol":"ETH","price_usd":"3480.00000000","source":"coingecko","timestamp":$HOUR_AGO}
EOF
echo "✓ ETH 価格イベント (1時間前)"

echo ""

# =====================================================
# 3. メッセージ確認
# =====================================================
echo "--- メッセージ確認 ---"
echo "トピック一覧:"
kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server localhost:9092 --list 2>/dev/null || echo "  (取得不可)"

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

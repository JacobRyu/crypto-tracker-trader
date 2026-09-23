#!/bin/bash
# テストデータ生成メインスクリプト
# 使い方: ./scripts/generate-test-data.sh [--postgres] [--redis] [--kafka] [--api] [--all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${NAMESPACE:-ctt-dev}"

# オプション解析
POSTGRES=false
REDIS=false
KAFKA=false
API=false
ALL=false

if [ $# -eq 0 ]; then
  ALL=true
fi

while [ $# -gt 0 ]; do
  case $1 in
    --postgres)
      POSTGRES=true
      shift
      ;;
    --redis)
      REDIS=true
      shift
      ;;
    --kafka)
      KAFKA=true
      shift
      ;;
    --api)
      API=true
      shift
      ;;
    --all)
      ALL=true
      shift
      ;;
    *)
      echo "不明なオプション: $1"
      echo "使い方: $0 [--postgres] [--redis] [--kafka] [--api] [--all]"
      exit 1
      ;;
  esac
done

if [ "$ALL" = true ]; then
  POSTGRES=true
  REDIS=true
  KAFKA=true
  API=true
fi

echo "=========================================="
echo "  テストデータ生成スクリプト"
echo "=========================================="
echo ""
echo "名前空間: ${NAMESPACE}"
echo ""
echo "実行内容:"
[ "$POSTGRES" = true ] && echo "  ✓ PostgreSQL テストデータ"
[ "$REDIS" = true ] && echo "  ✓ Redis テストデータ"
[ "$KAFKA" = true ] && echo "  ✓ Kafka テストメッセージ"
[ "$API" = true ] && echo "  ✓ API テストリクエスト"
echo ""

# ポッドの状態確認
echo "--- ポッドの状態確認 ---"
kubectl get pods -n "$NAMESPACE" -l "app in (postgres,redis,kafka)" --no-headers 2>/dev/null || echo "警告: ポッドが見つかりません"
echo ""

# =====================================================
# 1. PostgreSQL
# =====================================================
if [ "$POSTGRES" = true ]; then
  echo "=========================================="
  echo "  1. PostgreSQL テストデータ生成"
  echo "=========================================="
  echo ""

  bash "$SCRIPT_DIR/seed-postgres.sh"
  echo ""
fi

# =====================================================
# 2. Redis
# =====================================================
if [ "$REDIS" = true ]; then
  echo "=========================================="
  echo "  2. Redis テストデータ生成"
  echo "=========================================="
  echo ""

  bash "$SCRIPT_DIR/seed-redis.sh"
  echo ""
fi

# =====================================================
# 3. Kafka
# =====================================================
if [ "$KAFKA" = true ]; then
  echo "=========================================="
  echo "  3. Kafka テストメッセージ生成"
  echo "=========================================="
  echo ""

  bash "$SCRIPT_DIR/seed-kafka.sh"
  echo ""
fi

# =====================================================
# 4. API
# =====================================================
if [ "$API" = true ]; then
  echo "=========================================="
  echo "  4. API テストリクエスト"
  echo "=========================================="
  echo ""

  bash "$SCRIPT_DIR/test-api.sh"
  echo ""
fi

# =====================================================
# 完了サマリー
# =====================================================
echo "=========================================="
echo "  完了サマリー"
echo "=========================================="
echo ""
echo "生成されたデータ:"
[ "$POSTGRES" = true ] && echo "  PostgreSQL: 3ユーザー, 4ウォレット, 6アセット, 10価格データ"
[ "$REDIS" = true ] && echo "  Redis: 4価格, 2ポートフォリオ, 2ウォレット, 2取引所残高, 2セッション"
[ "$KAFKA" = true ] && echo "  Kafka: 7価格イベントメッセージ"
[ "$API" = true ] && echo "  API: 17リクエスト実行"
echo ""
echo "次のステップ:"
echo "  1. ポートフォリーズ: ./scripts/port-forward.sh"
echo "  2. Grafanaで確認: http://localhost:3000"
echo ""

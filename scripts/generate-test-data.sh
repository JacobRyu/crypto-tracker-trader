#!/bin/bash
# テストデータ生成メインスクリプト
# 使い方: ./scripts/generate-test-data.sh [--postgres] [--redis] [--kafka] [--api] [--all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
echo "実行内容:"
[ "$POSTGRES" = true ] && echo "  ✓ PostgreSQL テストデータ"
[ "$REDIS" = true ] && echo "  ✓ Redis テストデータ"
[ "$KAFKA" = true ] && echo "  ✓ Kafka テストメッセージ"
[ "$API" = true ] && echo "  ✓ API テストリクエスト"
echo ""

# =====================================================
# 1. PostgreSQL
# =====================================================
if [ "$POSTGRES" = true ]; then
  echo "=========================================="
  echo "  1. PostgreSQL テストデータ生成"
  echo "=========================================="
  echo ""

  # PostgreSQL接続テスト
  if ! psql -h localhost -U ctt -d crypto -c "SELECT 1" > /dev/null 2>&1; then
    echo "警告: PostgreSQLに接続できません"
    echo "手動で実行してください: psql -h localhost -U ctt -d crypto -f $SCRIPT_DIR/seed-postgres.sql"
  else
    echo "✓ PostgreSQL接続成功"
    psql -h localhost -U ctt -d crypto -f "$SCRIPT_DIR/seed-postgres.sql"
    echo "✓ PostgreSQL テストデータ生成完了"
  fi
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
  echo "✓ Redis テストデータ生成完了"
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
  echo "✓ Kafka テストメッセージ生成完了"
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
  echo "✓ API テストリクエスト完了"
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
echo "  1. アプリケーションを起動: go run ./cmd/server"
echo "  2. ポートフォリーズ: ./scripts/port-forward.sh"
echo "  3. Grafanaで確認: http://localhost:3000"
echo ""

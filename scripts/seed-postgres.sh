#!/bin/bash
# PostgreSQL テストデータ生成スクリプト（Pod内kubectl exec）
# 使い方: ./scripts/seed-postgres.sh

set -e

NAMESPACE="${NAMESPACE:-ctt-dev}"
DB_USER="${DB_USER:-ctt}"
DB_NAME="${DB_NAME:-crypto}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/seed-postgres.sql"

echo "=== PostgreSQL テストデータ生成 ==="
echo "名前空間: ${NAMESPACE}"
echo "DB: ${DB_NAME} (user: ${DB_USER})"
echo ""

# PostgreSQLポッド名を取得
POSTGRES_POD=$(kubectl get pods -n "$NAMESPACE" -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POSTGRES_POD" ]; then
  echo "エラー: PostgreSQLポッドが見つかりません"
  echo "Podが起動していることを確認してください: kubectl get pods -n $NAMESPACE"
  exit 1
fi

echo "対象ポッド: ${POSTGRES_POD}"
echo ""

# PostgreSQL接続テスト
if ! kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
  echo "エラー: PostgreSQLに接続できません"
  exit 1
fi

echo "✓ PostgreSQL接続成功"
echo ""

# SQLファイル存在チェック
if [ ! -f "$SQL_FILE" ]; then
  echo "エラー: SQLファイルが見つかりません: $SQL_FILE"
  exit 1
fi

echo "SQL実行中..."
kubectl exec -i -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d "$DB_NAME" < "$SQL_FILE"

echo ""
echo "✓ PostgreSQL テストデータ生成完了"
echo ""

# データ確認
echo "--- データ確認 ---"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'user_wallets', COUNT(*) FROM user_wallets
UNION ALL
SELECT 'user_assets', COUNT(*) FROM user_assets
UNION ALL
SELECT 'portfolio_snapshots', COUNT(*) FROM portfolio_snapshots
UNION ALL
SELECT 'asset_prices', COUNT(*) FROM asset_prices
UNION ALL
SELECT 'exchange_credentials', COUNT(*) FROM exchange_credentials
UNION ALL
SELECT 'exchange_balances', COUNT(*) FROM exchange_balances
UNION ALL
SELECT 'defi_positions', COUNT(*) FROM defi_positions;
"

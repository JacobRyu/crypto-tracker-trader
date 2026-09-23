-- PostgreSQL テストデータ生成スクリプト
-- 使い方: psql -h localhost -U ctt -d crypto -f scripts/seed-postgres.sql

-- 既存データをクリーンアップ（オプション）
-- TRUNCATE TABLE portfolio_assets, portfolio_snapshots, exchange_balances, exchange_credentials, user_defi_positions, user_assets, user_wallets, user_auth_providers, user_credentials, users, asset_prices CASCADE;

-- =====================================================
-- 1. ユーザーテーブル
-- =====================================================
INSERT INTO users (id, username, email, is_active, created_at, updated_at) VALUES
(1, 'alice', 'alice@example.com', TRUE, NOW() - INTERVAL '30 days', NOW()),
(2, 'bob', 'bob@example.com', TRUE, NOW() - INTERVAL '15 days', NOW()),
(3, 'charlie', 'charlie@example.com', FALSE, NOW() - INTERVAL '7 days', NOW())
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  email = EXCLUDED.email,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- =====================================================
-- 2. ユーザー認証テーブル
-- =====================================================
INSERT INTO user_credentials (id, user_id, password_hash, mfa_enabled, created_at, updated_at) VALUES
(1, 1, '$2a$10$dummyhashforalice123456789012345678901234567890', FALSE, NOW() - INTERVAL '30 days', NOW()),
(2, 2, '$2a$10$dummyhashforbob123456789012345678901234567890123', TRUE, NOW() - INTERVAL '15 days', NOW()),
(3, 3, '$2a$10$dummyhashforcharlie123456789012345678901234567', FALSE, NOW() - INTERVAL '7 days', NOW())
ON CONFLICT (id) DO UPDATE SET
  password_hash = EXCLUDED.password_hash,
  mfa_enabled = EXCLUDED.mfa_enabled,
  updated_at = NOW();

-- =====================================================
-- 3. ウォレットテーブル
-- =====================================================
INSERT INTO user_wallets (id, user_id, chain, address, label, created_at, updated_at) VALUES
(1, 1, 'ethereum', '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18', 'Main ETH Wallet', NOW() - INTERVAL '25 days', NOW()),
(2, 1, 'polygon', '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18', 'Polygon Wallet', NOW() - INTERVAL '20 days', NOW()),
(3, 2, 'ethereum', '0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B', 'Trading Wallet', NOW() - INTERVAL '10 days', NOW()),
(4, 3, 'ethereum', '0x1234567890abcdef1234567890abcdef12345678', 'Test Wallet', NOW() - INTERVAL '5 days', NOW())
ON CONFLICT (user_id, chain, address) DO UPDATE SET
  label = EXCLUDED.label,
  updated_at = NOW();

-- =====================================================
-- 4. ユーザーアセットテーブル
-- =====================================================
INSERT INTO user_assets (id, wallet_id, chain, token_address, symbol, balance, updated_at) VALUES
(1, 1, 'ethereum', '0x0000000000000000000000000000000000000000', 'ETH', 1500000000000000000, NOW()),
(2, 1, 'ethereum', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', 'USDC', 5000000000, NOW()),
(3, 2, 'polygon', '0x0000000000000000000000000000000000001010', 'MATIC', 20000000000000000000, NOW()),
(4, 3, 'ethereum', '0x0000000000000000000000000000000000000000', 'ETH', 500000000000000000, NOW()),
(5, 3, 'ethereum', '0x6B175474E89094C44Da98b954EedeAC495271d0F', 'DAI', 1000000000000000000000, NOW()),
(6, 4, 'ethereum', '0x0000000000000000000000000000000000000000', 'ETH', 2000000000000000000, NOW())
ON CONFLICT (id) DO UPDATE SET
  balance = EXCLUDED.balance,
  updated_at = NOW();

-- =====================================================
-- 5. ポートフォリオスナップショットテーブル
-- =====================================================
INSERT INTO portfolio_snapshots (id, user_id, timestamp, total_value) VALUES
(1, 1, NOW() - INTERVAL '7 days', 125000.00000000),
(2, 1, NOW() - INTERVAL '1 day', 132000.00000000),
(3, 2, NOW() - INTERVAL '3 days', 85000.00000000),
(4, 3, NOW() - INTERVAL '2 days', 45000.00000000)
ON CONFLICT (id) DO UPDATE SET
  total_value = EXCLUDED.total_value;

-- =====================================================
-- 6. ポートフォリオアセットテーブル
-- =====================================================
INSERT INTO portfolio_assets (id, snapshot_id, asset_id, quantity, value) VALUES
(1, 1, 'ETH', 1.50000000, 3000.00000000),
(2, 1, 'USDC', 5000.000000, 5000.00000000),
(3, 2, 'ETH', 1.50000000, 3200.00000000),
(4, 2, 'USDC', 5000.000000, 5000.00000000),
(5, 3, 'ETH', 0.50000000, 1666.66666667),
(6, 3, 'DAI', 1000.000000, 1000.00000000),
(7, 4, 'ETH', 2.00000000, 6000.00000000)
ON CONFLICT (id) DO UPDATE SET
  quantity = EXCLUDED.quantity,
  value = EXCLUDED.value;

-- =====================================================
-- 7. 価格データテーブル
-- =====================================================
INSERT INTO asset_prices (id, symbol, price_usd, source, fetched_at) VALUES
(1, 'BTC', 67500.00000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(2, 'ETH', 3500.00000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(3, 'BTC', 67200.00000000, 'coingecko', NOW() - INTERVAL '1 hour'),
(4, 'ETH', 3480.00000000, 'coingecko', NOW() - INTERVAL '1 hour'),
(5, 'SOL', 180.50000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(6, 'DOGE', 0.12000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(7, 'BNB', 580.00000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(8, 'USDC', 1.00000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(9, 'USDT', 1.00000000, 'coingecko', NOW() - INTERVAL '5 minutes'),
(10, 'ADA', 0.45000000, 'coingecko', NOW() - INTERVAL '5 minutes')
ON CONFLICT (id) DO UPDATE SET
  price_usd = EXCLUDED.price_usd,
  fetched_at = EXCLUDED.fetched_at;

-- =====================================================
-- 8. 取引所クレデンシャルテーブル
-- =====================================================
INSERT INTO exchange_credentials (id, user_id, exchange, api_key_encrypted, api_secret_encrypted, is_active, created_at, updated_at) VALUES
(1, 1, 'binance', E'\\x0102030405060708090a0b0c0d0e0f10', E'\\x1112131415161718191a1b1c1d1e1f20', TRUE, NOW() - INTERVAL '20 days', NOW()),
(2, 2, 'coinbase', E'\\x2122232425262728292a2b2c2d2e2f30', E'\\x3132333435363738393a3b3c3d3e3f40', TRUE, NOW() - INTERVAL '10 days', NOW()),
(3, 1, 'kraken', E'\\x4142434445464748494a4b4c4d4e4f50', E'\\x5152535455565758595a5b5c5d5e5f60', FALSE, NOW() - INTERVAL '5 days', NOW())
ON CONFLICT (id) DO UPDATE SET
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- =====================================================
-- 9. 取引所残高テーブル
-- =====================================================
INSERT INTO exchange_balances (id, credential_id, user_id, symbol, free_balance, locked_balance, updated_at) VALUES
(1, 1, 1, 'BTC', 0.50000000, 0.00000000, NOW() - INTERVAL '10 minutes'),
(2, 1, 1, 'USDT', 10000.00000000, 5000.00000000, NOW() - INTERVAL '10 minutes'),
(3, 1, 1, 'ETH', 2.00000000, 0.50000000, NOW() - INTERVAL '10 minutes'),
(4, 2, 2, 'ETH', 2.00000000, 0.00000000, NOW() - INTERVAL '30 minutes'),
(5, 2, 2, 'BTC', 0.10000000, 0.00000000, NOW() - INTERVAL '30 minutes'),
(6, 3, 1, 'SOL', 10.00000000, 0.00000000, NOW() - INTERVAL '1 hour')
ON CONFLICT (id) DO UPDATE SET
  free_balance = EXCLUDED.free_balance,
  locked_balance = EXCLUDED.locked_balance,
  updated_at = NOW();

-- =====================================================
-- 10. DeFiポジションテーブル
-- =====================================================
INSERT INTO user_defi_positions (id, wallet_id, protocol, position_type, position_json, updated_at) VALUES
(1, 1, 'uniswap-v3', 'liquidity_pool', '{"token0":"ETH","token1":"USDC","fee":3000,"ticksLower":-887220,"ticksUpper":887220,"liquidity":"123456789000000"}'::jsonb, NOW() - INTERVAL '1 hour'),
(2, 1, 'aave-v3', 'lending', '{"asset":"USDC","deposit":"5000.0","borrowed":"0","healthFactor":"999"}'::jsonb, NOW() - INTERVAL '2 hours'),
(3, 3, 'lido', 'staking', '{"stETH":"0.5","reward":"0.01"}'::jsonb, NOW() - INTERVAL '3 hours'),
(4, 3, 'uniswap-v3', 'liquidity_pool', '{"token0":"ETH","token1":"DAI","fee":500,"ticksLower":-887220,"ticksUpper":887220,"liquidity":"50000000000000"}'::jsonb, NOW() - INTERVAL '4 hours')
ON CONFLICT (id) DO UPDATE SET
  position_json = EXCLUDED.position_json,
  updated_at = NOW();

-- =====================================================
-- 完了メッセージ
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE 'テストデータの挿入が完了しました';
  RAISE NOTICE ' users: 3件';
  RAISE NOTICE ' user_credentials: 3件';
  RAISE NOTICE ' user_wallets: 4件';
  RAISE NOTICE ' user_assets: 6件';
  RAISE NOTICE ' portfolio_snapshots: 4件';
  RAISE NOTICE ' portfolio_assets: 7件';
  RAISE NOTICE ' asset_prices: 10件';
  RAISE NOTICE ' exchange_credentials: 3件';
  RAISE NOTICE ' exchange_balances: 6件';
  RAISE NOTICE ' user_defi_positions: 4件';
END $$;

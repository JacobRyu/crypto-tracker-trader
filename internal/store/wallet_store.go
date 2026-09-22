package store

import (
	"context"
	"fmt"
	"time"

	"crypto-tracker-trader/internal/model"

	"github.com/jackc/pgx/v4/pgxpool"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

var walletTracer = otel.Tracer("crypto-tracker-trader/wallet-store")

// WalletStore implements WalletStoreInterface for PostgreSQL.
type WalletStore struct {
	db *pgxpool.Pool
}

// NewWalletStore creates a new WalletStore.
func NewWalletStore(db *pgxpool.Pool) *WalletStore {
	return &WalletStore{db: db}
}

// CreateWallet inserts a new wallet row and sets the generated ID on the struct.
func (s *WalletStore) CreateWallet(ctx context.Context, wallet *model.UserWallet) error {
	ctx, span := walletTracer.Start(ctx, "db.user_wallets.insert",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "INSERT"),
			attribute.String("db.sql.table", "user_wallets"),
		),
	)
	defer span.End()

	wallet.CreatedAt = time.Now()
	wallet.UpdatedAt = time.Now()
	err := s.db.QueryRow(ctx,
		`INSERT INTO user_wallets (user_id, chain, address, label, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
		wallet.UserID, wallet.Chain, wallet.Address, wallet.Label,
		wallet.CreatedAt, wallet.UpdatedAt,
	).Scan(&wallet.ID)
	if err != nil {
		return fmt.Errorf("create wallet: %w", err)
	}
	return nil
}

// GetWalletsByUserID returns all wallets belonging to the given user.
func (s *WalletStore) GetWalletsByUserID(ctx context.Context, userID uint64) ([]model.UserWallet, error) {
	ctx, span := walletTracer.Start(ctx, "db.user_wallets.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "user_wallets"),
		),
	)
	defer span.End()

	rows, err := s.db.Query(ctx,
		`SELECT id, user_id, chain, address, label, created_at, updated_at
		 FROM user_wallets WHERE user_id = $1 ORDER BY created_at DESC`,
		userID,
	)
	if err != nil {
		return nil, fmt.Errorf("query wallets: %w", err)
	}
	defer rows.Close()

	var wallets []model.UserWallet
	for rows.Next() {
		var w model.UserWallet
		if err := rows.Scan(&w.ID, &w.UserID, &w.Chain, &w.Address, &w.Label, &w.CreatedAt, &w.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan wallet: %w", err)
		}
		wallets = append(wallets, w)
	}
	return wallets, rows.Err()
}

// GetWalletByID returns a single wallet by its primary key.
func (s *WalletStore) GetWalletByID(ctx context.Context, id uint64) (*model.UserWallet, error) {
	ctx, span := walletTracer.Start(ctx, "db.user_wallets.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "user_wallets"),
		),
	)
	defer span.End()

	var w model.UserWallet
	err := s.db.QueryRow(ctx,
		`SELECT id, user_id, chain, address, label, created_at, updated_at
		 FROM user_wallets WHERE id = $1`,
		id,
	).Scan(&w.ID, &w.UserID, &w.Chain, &w.Address, &w.Label, &w.CreatedAt, &w.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("get wallet by id: %w", err)
	}
	return &w, nil
}

// DeleteWallet removes a wallet only if it belongs to the given user.
// Returns an error if the wallet does not exist or does not belong to the user.
func (s *WalletStore) DeleteWallet(ctx context.Context, walletID, userID uint64) error {
	ctx, span := walletTracer.Start(ctx, "db.user_wallets.delete",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "DELETE"),
			attribute.String("db.sql.table", "user_wallets"),
		),
	)
	defer span.End()

	tag, err := s.db.Exec(ctx,
		`DELETE FROM user_wallets WHERE id = $1 AND user_id = $2`,
		walletID, userID,
	)
	if err != nil {
		return fmt.Errorf("delete wallet: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// GetAssetsByWalletID returns all token assets for the given wallet.
func (s *WalletStore) GetAssetsByWalletID(ctx context.Context, walletID uint64) ([]model.UserAsset, error) {
	ctx, span := walletTracer.Start(ctx, "db.user_assets.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "user_assets"),
		),
	)
	defer span.End()

	rows, err := s.db.Query(ctx,
		`SELECT id, wallet_id, chain, token_address, symbol, balance, updated_at
		 FROM user_assets WHERE wallet_id = $1 ORDER BY symbol`,
		walletID,
	)
	if err != nil {
		return nil, fmt.Errorf("query assets: %w", err)
	}
	defer rows.Close()

	var assets []model.UserAsset
	for rows.Next() {
		var a model.UserAsset
		if err := rows.Scan(&a.ID, &a.WalletID, &a.Chain, &a.TokenAddr, &a.Symbol, &a.Balance, &a.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan asset: %w", err)
		}
		assets = append(assets, a)
	}
	return assets, rows.Err()
}

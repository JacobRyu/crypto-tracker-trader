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

var exchangeTracer = otel.Tracer("crypto-tracker-trader/exchange-store")

// ExchangeStore handles persistence for exchange credentials and balances.
type ExchangeStore struct {
	pool *pgxpool.Pool
}

func NewExchangeStore(pool *pgxpool.Pool) *ExchangeStore {
	return &ExchangeStore{pool: pool}
}

func (s *ExchangeStore) CreateCredential(ctx context.Context, cred *model.ExchangeCredential) error {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_credentials.insert",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "INSERT"),
			attribute.String("db.sql.table", "exchange_credentials"),
		),
	)
	defer span.End()

	const q = `
		INSERT INTO exchange_credentials (user_id, exchange, api_key_encrypted, api_secret_encrypted, is_active, created_at)
		VALUES ($1, $2, $3, $4, TRUE, NOW())
		RETURNING id, created_at`
	return s.pool.QueryRow(ctx, q,
		cred.UserID, cred.Exchange, cred.APIKeyEncrypted, cred.APISecretEncrypted,
	).Scan(&cred.ID, &cred.CreatedAt)
}

func (s *ExchangeStore) GetCredentialsByUserID(ctx context.Context, userID uint64) ([]model.ExchangeCredential, error) {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_credentials.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "exchange_credentials"),
		),
	)
	defer span.End()

	const q = `
		SELECT id, user_id, exchange, api_key_encrypted, api_secret_encrypted, is_active, created_at
		FROM exchange_credentials
		WHERE user_id = $1
		ORDER BY created_at DESC`
	rows, err := s.pool.Query(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("exchange store: query credentials: %w", err)
	}
	defer rows.Close()

	var creds []model.ExchangeCredential
	for rows.Next() {
		var c model.ExchangeCredential
		if err := rows.Scan(&c.ID, &c.UserID, &c.Exchange, &c.APIKeyEncrypted, &c.APISecretEncrypted, &c.IsActive, &c.CreatedAt); err != nil {
			return nil, err
		}
		creds = append(creds, c)
	}
	return creds, rows.Err()
}

func (s *ExchangeStore) GetCredentialByID(ctx context.Context, id uint64) (*model.ExchangeCredential, error) {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_credentials.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "exchange_credentials"),
		),
	)
	defer span.End()

	const q = `
		SELECT id, user_id, exchange, api_key_encrypted, api_secret_encrypted, is_active, created_at
		FROM exchange_credentials WHERE id = $1`
	var c model.ExchangeCredential
	err := s.pool.QueryRow(ctx, q, id).Scan(
		&c.ID, &c.UserID, &c.Exchange, &c.APIKeyEncrypted, &c.APISecretEncrypted, &c.IsActive, &c.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("exchange store: get credential: %w", err)
	}
	return &c, nil
}

func (s *ExchangeStore) GetAllActiveCredentials(ctx context.Context) ([]model.ExchangeCredential, error) {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_credentials.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "exchange_credentials"),
		),
	)
	defer span.End()

	const q = `
		SELECT id, user_id, exchange, api_key_encrypted, api_secret_encrypted, is_active, created_at
		FROM exchange_credentials WHERE is_active = TRUE`
	rows, err := s.pool.Query(ctx, q)
	if err != nil {
		return nil, fmt.Errorf("exchange store: query active credentials: %w", err)
	}
	defer rows.Close()

	var creds []model.ExchangeCredential
	for rows.Next() {
		var c model.ExchangeCredential
		if err := rows.Scan(&c.ID, &c.UserID, &c.Exchange, &c.APIKeyEncrypted, &c.APISecretEncrypted, &c.IsActive, &c.CreatedAt); err != nil {
			return nil, err
		}
		creds = append(creds, c)
	}
	return creds, rows.Err()
}

func (s *ExchangeStore) DeleteCredential(ctx context.Context, id, userID uint64) error {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_credentials.delete",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "DELETE"),
			attribute.String("db.sql.table", "exchange_credentials"),
		),
	)
	defer span.End()

	const q = `DELETE FROM exchange_credentials WHERE id = $1 AND user_id = $2`
	tag, err := s.pool.Exec(ctx, q, id, userID)
	if err != nil {
		return fmt.Errorf("exchange store: delete credential: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// UpsertBalances inserts or updates exchange balances for a credential.
func (s *ExchangeStore) UpsertBalances(ctx context.Context, credentialID, userID uint64, balances []model.ExchangeBalance) error {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_balances.upsert",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "INSERT"),
			attribute.String("db.sql.table", "exchange_balances"),
		),
	)
	defer span.End()

	const q = `
		INSERT INTO exchange_balances (credential_id, user_id, symbol, free_balance, locked_balance, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (credential_id, symbol) DO UPDATE SET
			free_balance = EXCLUDED.free_balance,
			locked_balance = EXCLUDED.locked_balance,
			updated_at = EXCLUDED.updated_at`

	now := time.Now()
	for _, b := range balances {
		if _, err := s.pool.Exec(ctx, q,
			credentialID, userID, b.Symbol, b.FreeBalance, b.LockedBalance, now,
		); err != nil {
			return fmt.Errorf("exchange store: upsert balance %s: %w", b.Symbol, err)
		}
	}
	return nil
}

func (s *ExchangeStore) GetBalancesByUserID(ctx context.Context, userID uint64) ([]model.ExchangeBalance, error) {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_balances.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "exchange_balances"),
		),
	)
	defer span.End()

	const q = `
		SELECT id, credential_id, user_id, symbol, free_balance, locked_balance, updated_at
		FROM exchange_balances WHERE user_id = $1
		ORDER BY symbol`
	rows, err := s.pool.Query(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("exchange store: query balances: %w", err)
	}
	defer rows.Close()

	var balances []model.ExchangeBalance
	for rows.Next() {
		var b model.ExchangeBalance
		if err := rows.Scan(&b.ID, &b.CredentialID, &b.UserID, &b.Symbol, &b.FreeBalance, &b.LockedBalance, &b.UpdatedAt); err != nil {
			return nil, err
		}
		balances = append(balances, b)
	}
	return balances, rows.Err()
}

func (s *ExchangeStore) GetBalancesByCredentialID(ctx context.Context, credentialID uint64) ([]model.ExchangeBalance, error) {
	ctx, span := exchangeTracer.Start(ctx, "db.exchange_balances.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "exchange_balances"),
		),
	)
	defer span.End()

	const q = `
		SELECT id, credential_id, user_id, symbol, free_balance, locked_balance, updated_at
		FROM exchange_balances WHERE credential_id = $1
		ORDER BY symbol`
	rows, err := s.pool.Query(ctx, q, credentialID)
	if err != nil {
		return nil, fmt.Errorf("exchange store: query balances by cred: %w", err)
	}
	defer rows.Close()

	var balances []model.ExchangeBalance
	for rows.Next() {
		var b model.ExchangeBalance
		if err := rows.Scan(&b.ID, &b.CredentialID, &b.UserID, &b.Symbol, &b.FreeBalance, &b.LockedBalance, &b.UpdatedAt); err != nil {
			return nil, err
		}
		balances = append(balances, b)
	}
	return balances, rows.Err()
}

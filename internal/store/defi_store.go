package store

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"crypto-tracker-trader/internal/model"

	"github.com/jackc/pgx/v4/pgxpool"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"gorm.io/datatypes"
)

var defiTracer = otel.Tracer("crypto-tracker-trader/defi-store")

// DefiStore handles persistence for user DeFi positions.
type DefiStore struct {
	pool *pgxpool.Pool
}

func NewDefiStore(pool *pgxpool.Pool) *DefiStore {
	return &DefiStore{pool: pool}
}

// UpsertPosition inserts or updates a DeFi position.
// Uniqueness is keyed on (wallet_id, protocol, position_type).
func (s *DefiStore) UpsertPosition(ctx context.Context, pos *model.UserDefiPosition) error {
	ctx, span := defiTracer.Start(ctx, "db.user_defi_positions.upsert",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "INSERT"),
			attribute.String("db.sql.table", "user_defi_positions"),
		),
	)
	defer span.End()

	data, err := json.Marshal(pos.PositionJSON)
	if err != nil {
		return fmt.Errorf("defi store: marshalling position json: %w", err)
	}
	const q = `
		INSERT INTO user_defi_positions (wallet_id, protocol, position_type, position_json, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (wallet_id, protocol, position_type) DO UPDATE SET
			position_json = EXCLUDED.position_json,
			updated_at    = EXCLUDED.updated_at
		RETURNING id`
	return s.pool.QueryRow(ctx, q,
		pos.WalletID, pos.Protocol, pos.PositionType, data, time.Now(),
	).Scan(&pos.ID)
}

func (s *DefiStore) GetPositionsByWalletID(ctx context.Context, walletID uint64) ([]model.UserDefiPosition, error) {
	ctx, span := defiTracer.Start(ctx, "db.user_defi_positions.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "user_defi_positions"),
		),
	)
	defer span.End()

	const q = `
		SELECT id, wallet_id, protocol, position_type, position_json, updated_at
		FROM user_defi_positions WHERE wallet_id = $1
		ORDER BY protocol, position_type`
	return s.queryPositions(ctx, q, walletID)
}

func (s *DefiStore) GetPositionsByUserID(ctx context.Context, userID uint64) ([]model.UserDefiPosition, error) {
	ctx, span := defiTracer.Start(ctx, "db.user_defi_positions.select",
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.operation", "SELECT"),
			attribute.String("db.sql.table", "user_defi_positions"),
		),
	)
	defer span.End()

	const q = `
		SELECT dp.id, dp.wallet_id, dp.protocol, dp.position_type, dp.position_json, dp.updated_at
		FROM user_defi_positions dp
		JOIN user_wallets w ON w.id = dp.wallet_id
		WHERE w.user_id = $1
		ORDER BY dp.protocol, dp.position_type`
	return s.queryPositions(ctx, q, userID)
}

func (s *DefiStore) queryPositions(ctx context.Context, query string, arg interface{}) ([]model.UserDefiPosition, error) {
	rows, err := s.pool.Query(ctx, query, arg)
	if err != nil {
		return nil, fmt.Errorf("defi store: query: %w", err)
	}
	defer rows.Close()

	var positions []model.UserDefiPosition
	for rows.Next() {
		var p model.UserDefiPosition
		var raw []byte
		if err := rows.Scan(&p.ID, &p.WalletID, &p.Protocol, &p.PositionType, &raw, &p.UpdatedAt); err != nil {
			return nil, err
		}
		p.PositionJSON = datatypes.JSON(raw)
		positions = append(positions, p)
	}
	return positions, rows.Err()
}

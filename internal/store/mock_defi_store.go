package store

import (
	"context"

	"crypto-tracker-trader/internal/model"

	"github.com/stretchr/testify/mock"
)

type MockDefiStore struct {
	mock.Mock
}

func (m *MockDefiStore) UpsertPosition(ctx context.Context, pos *model.UserDefiPosition) error {
	return m.Called(ctx, pos).Error(0)
}

func (m *MockDefiStore) GetPositionsByWalletID(ctx context.Context, walletID uint64) ([]model.UserDefiPosition, error) {
	args := m.Called(ctx, walletID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.UserDefiPosition), args.Error(1)
}

func (m *MockDefiStore) GetPositionsByUserID(ctx context.Context, userID uint64) ([]model.UserDefiPosition, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.UserDefiPosition), args.Error(1)
}

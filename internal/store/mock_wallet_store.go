package store

import (
	"context"

	"crypto-tracker-trader/internal/model"

	"github.com/stretchr/testify/mock"
)

// MockWalletStore is a testify mock for WalletStoreInterface.
type MockWalletStore struct {
	mock.Mock
}

func (m *MockWalletStore) CreateWallet(ctx context.Context, wallet *model.UserWallet) error {
	args := m.Called(ctx, wallet)
	return args.Error(0)
}

func (m *MockWalletStore) GetWalletsByUserID(ctx context.Context, userID uint64) ([]model.UserWallet, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.UserWallet), args.Error(1)
}

func (m *MockWalletStore) GetWalletByID(ctx context.Context, id uint64) (*model.UserWallet, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.UserWallet), args.Error(1)
}

func (m *MockWalletStore) DeleteWallet(ctx context.Context, walletID, userID uint64) error {
	args := m.Called(ctx, walletID, userID)
	return args.Error(0)
}

func (m *MockWalletStore) GetAssetsByWalletID(ctx context.Context, walletID uint64) ([]model.UserAsset, error) {
	args := m.Called(ctx, walletID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.UserAsset), args.Error(1)
}

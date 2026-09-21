package store

import (
	"context"

	"crypto-tracker-trader/internal/model"

	"github.com/stretchr/testify/mock"
)

type MockExchangeStore struct {
	mock.Mock
}

func (m *MockExchangeStore) CreateCredential(ctx context.Context, cred *model.ExchangeCredential) error {
	return m.Called(ctx, cred).Error(0)
}

func (m *MockExchangeStore) GetCredentialsByUserID(ctx context.Context, userID uint64) ([]model.ExchangeCredential, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.ExchangeCredential), args.Error(1)
}

func (m *MockExchangeStore) GetCredentialByID(ctx context.Context, id uint64) (*model.ExchangeCredential, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.ExchangeCredential), args.Error(1)
}

func (m *MockExchangeStore) GetAllActiveCredentials(ctx context.Context) ([]model.ExchangeCredential, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.ExchangeCredential), args.Error(1)
}

func (m *MockExchangeStore) DeleteCredential(ctx context.Context, id, userID uint64) error {
	return m.Called(ctx, id, userID).Error(0)
}

func (m *MockExchangeStore) UpsertBalances(ctx context.Context, credentialID, userID uint64, balances []model.ExchangeBalance) error {
	return m.Called(ctx, credentialID, userID, balances).Error(0)
}

func (m *MockExchangeStore) GetBalancesByUserID(ctx context.Context, userID uint64) ([]model.ExchangeBalance, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.ExchangeBalance), args.Error(1)
}

func (m *MockExchangeStore) GetBalancesByCredentialID(ctx context.Context, credentialID uint64) ([]model.ExchangeBalance, error) {
	args := m.Called(ctx, credentialID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.ExchangeBalance), args.Error(1)
}

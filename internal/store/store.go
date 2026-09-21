package store

import (
	"context"

	"crypto-tracker-trader/internal/model"
)

type PortfolioStoreInterface interface {
	AddSnapshot(ctx context.Context, snapshot model.PortfolioSnapshot) error
	GetHistory(ctx context.Context) ([]model.PortfolioSnapshot, error)
	Close()
}

type WalletStoreInterface interface {
	CreateWallet(ctx context.Context, wallet *model.UserWallet) error
	GetWalletsByUserID(ctx context.Context, userID uint64) ([]model.UserWallet, error)
	GetWalletByID(ctx context.Context, id uint64) (*model.UserWallet, error)
	DeleteWallet(ctx context.Context, walletID, userID uint64) error
	GetAssetsByWalletID(ctx context.Context, walletID uint64) ([]model.UserAsset, error)
}

type PriceStoreInterface interface {
	SavePrice(ctx context.Context, symbol, priceUSD, source string) error
	GetLatestPrice(ctx context.Context, symbol string) (*model.AssetPrice, error)
	GetPriceHistory(ctx context.Context, symbol string, limit int) ([]model.AssetPrice, error)
}

type ExchangeStoreInterface interface {
	CreateCredential(ctx context.Context, cred *model.ExchangeCredential) error
	GetCredentialsByUserID(ctx context.Context, userID uint64) ([]model.ExchangeCredential, error)
	GetCredentialByID(ctx context.Context, id uint64) (*model.ExchangeCredential, error)
	GetAllActiveCredentials(ctx context.Context) ([]model.ExchangeCredential, error)
	DeleteCredential(ctx context.Context, id, userID uint64) error
	UpsertBalances(ctx context.Context, credentialID, userID uint64, balances []model.ExchangeBalance) error
	GetBalancesByUserID(ctx context.Context, userID uint64) ([]model.ExchangeBalance, error)
	GetBalancesByCredentialID(ctx context.Context, credentialID uint64) ([]model.ExchangeBalance, error)
}

type DefiStoreInterface interface {
	UpsertPosition(ctx context.Context, pos *model.UserDefiPosition) error
	GetPositionsByWalletID(ctx context.Context, walletID uint64) ([]model.UserDefiPosition, error)
	GetPositionsByUserID(ctx context.Context, userID uint64) ([]model.UserDefiPosition, error)
}

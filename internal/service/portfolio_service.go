package service

import (
	"context"

	"crypto-tracker-trader/internal/model"
	"crypto-tracker-trader/internal/store"
)

// PortfolioService implements the PortfolioManager interface.
type PortfolioService struct {
	portfolioStore store.PortfolioStoreInterface
}

func NewPortfolioService(portfolioStore store.PortfolioStoreInterface) PortfolioManager {
	return &PortfolioService{
		portfolioStore: portfolioStore,
	}
}

func (s *PortfolioService) GetPortfolioHistory(ctx context.Context) ([]model.PortfolioSnapshot, error) {
	return s.portfolioStore.GetHistory(ctx)
}

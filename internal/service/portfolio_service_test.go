package service

import (
	"context"
	"testing"
	"time"

	"crypto-tracker-trader/internal/model"
	"crypto-tracker-trader/internal/store"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestPortfolioService(t *testing.T) {
	mockStore := new(store.MockPortfolioStore)
	portfolioService := NewPortfolioService(mockStore)

	// Mock data
	snapshot := model.PortfolioSnapshot{
		Timestamp: time.Now(),
		Assets: []model.PortfolioAsset{
			{AssetID: "BTC", Quantity: "1", Value: "50000"},
		},
		TotalValue: "50000",
	}
	snapshots := []model.PortfolioSnapshot{snapshot}

	mockStore.On("GetHistory", mock.Anything).Return(snapshots, nil)

	// Test GetPortfolioHistory
	history, err := portfolioService.GetPortfolioHistory(context.Background())
	assert.NoError(t, err)
	assert.Len(t, history, 1)
	assert.Equal(t, snapshot.TotalValue, history[0].TotalValue)

	mockStore.AssertExpectations(t)
}

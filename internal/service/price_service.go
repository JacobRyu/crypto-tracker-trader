package service

import (
	"context"
	"fmt"
	"log"
	"time"

	"crypto-tracker-trader/internal/event"
	"crypto-tracker-trader/internal/metrics"
	"crypto-tracker-trader/internal/model"
	"crypto-tracker-trader/internal/store"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

const defaultPriceSyncInterval = 60 * time.Second

// PriceService orchestrates price fetching from an external provider and
// persisting the results. It also runs a background sync loop.
type PriceService struct {
	fetcher    PriceFetcher
	priceStore store.PriceStoreInterface
	source     string
	kafka      *event.KafkaProducer
}

// NewPriceService creates a new PriceService.
// source identifies the data provider (e.g. "coingecko").
func NewPriceService(fetcher PriceFetcher, priceStore store.PriceStoreInterface, source string, kafka *event.KafkaProducer) *PriceService {
	if source == "" {
		source = "coingecko"
	}
	return &PriceService{fetcher: fetcher, priceStore: priceStore, source: source, kafka: kafka}
}

// FetchAndSave fetches current prices for the given symbols and persists them.
func (s *PriceService) FetchAndSave(ctx context.Context, symbols []string) error {
	ctx, span := tracer.Start(ctx, "price_service.FetchAndSave",
		trace.WithAttributes(
			attribute.Int("symbol.count", len(symbols)),
			attribute.String("source", s.source),
		),
	)
	defer span.End()

	prices, err := s.fetcher.FetchPrices(ctx, symbols)
	if err != nil {
		return fmt.Errorf("fetch prices: %w", err)
	}
	for symbol, priceUSD := range prices {
		if err := s.priceStore.SavePrice(ctx, symbol, priceUSD, s.source); err != nil {
			log.Printf("PriceService: failed to save price for %s: %v", symbol, err)
			continue
		}

		// Publish to Kafka.
		if s.kafka != nil {
			evt := event.PriceEvent{
				Symbol:    symbol,
				PriceUSD:  priceUSD,
				Source:    s.source,
				Timestamp: time.Now().Unix(),
			}
			if err := s.kafka.PublishPriceEvent(ctx, evt); err != nil {
				log.Printf("PriceService: failed to publish Kafka event for %s: %v", symbol, err)
			}
		}

		// Increment Prometheus metrics.
		metrics.PriceUpdatesTotal.WithLabelValues(symbol, s.source).Inc()
	}
	return nil
}

// GetLatestPrice returns the most recent price for the given symbol.
func (s *PriceService) GetLatestPrice(ctx context.Context, symbol string) (*model.AssetPrice, error) {
	ctx, span := tracer.Start(ctx, "price_service.GetLatestPrice",
		trace.WithAttributes(
			attribute.String("symbol", symbol),
		),
	)
	defer span.End()

	price, err := s.priceStore.GetLatestPrice(ctx, symbol)
	if err != nil {
		return nil, fmt.Errorf("get latest price: %w", err)
	}
	return price, nil
}

// GetPriceHistory returns recent price records for the given symbol.
func (s *PriceService) GetPriceHistory(ctx context.Context, symbol string, limit int) ([]model.AssetPrice, error) {
	ctx, span := tracer.Start(ctx, "price_service.GetPriceHistory",
		trace.WithAttributes(
			attribute.String("symbol", symbol),
			attribute.Int("limit", limit),
		),
	)
	defer span.End()

	prices, err := s.priceStore.GetPriceHistory(ctx, symbol, limit)
	if err != nil {
		return nil, fmt.Errorf("get price history: %w", err)
	}
	if prices == nil {
		prices = []model.AssetPrice{}
	}
	return prices, nil
}

// StartSync launches a background goroutine that calls FetchAndSave on the
// given interval until ctx is cancelled.
// It performs an immediate fetch on start, then ticks at each interval.
func (s *PriceService) StartSync(ctx context.Context, symbols []string, interval time.Duration) {
	if interval <= 0 {
		interval = defaultPriceSyncInterval
	}
	go func() {
		// Fetch immediately on startup.
		if err := s.FetchAndSave(ctx, symbols); err != nil {
			log.Printf("PriceService: initial sync error: %v", err)
		}

		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				log.Println("PriceService: background sync stopped")
				return
			case <-ticker.C:
				if err := s.FetchAndSave(ctx, symbols); err != nil {
					log.Printf("PriceService: sync error: %v", err)
				}
			}
		}
	}()
}

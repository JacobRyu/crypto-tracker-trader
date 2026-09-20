package event

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPriceEvent_Marshal(t *testing.T) {
	event := PriceEvent{
		Symbol:    "BTC",
		PriceUSD:  "50000.00",
		Source:    "coingecko",
		Timestamp: 1234567890,
	}

	data, err := json.Marshal(event)
	assert.NoError(t, err)
	assert.Contains(t, string(data), "BTC")
}

func TestPriceEvent_Unmarshal(t *testing.T) {
	event := PriceEvent{
		Symbol:    "ETH",
		PriceUSD:  "3000.00",
		Source:    "coingecko",
		Timestamp: 1234567890,
	}

	data, err := json.Marshal(event)
	assert.NoError(t, err)

	var decoded PriceEvent
	err = json.Unmarshal(data, &decoded)
	assert.NoError(t, err)
	assert.Equal(t, event, decoded)
}

func TestPriceEvent_EmptySymbol(t *testing.T) {
	event := PriceEvent{
		Symbol:    "",
		PriceUSD:  "100.00",
		Source:    "test",
		Timestamp: 1234567890,
	}

	data, err := json.Marshal(event)
	assert.NoError(t, err)
	assert.Contains(t, string(data), "price_usd")
}

func TestPriceEvent_JSONRoundTrip(t *testing.T) {
	events := []PriceEvent{
		{Symbol: "BTC", PriceUSD: "50000.00", Source: "coingecko", Timestamp: 1000},
		{Symbol: "ETH", PriceUSD: "3000.00", Source: "coingecko", Timestamp: 2000},
		{Symbol: "SOL", PriceUSD: "150.00", Source: "coingecko", Timestamp: 3000},
	}

	for _, original := range events {
		data, err := json.Marshal(original)
		assert.NoError(t, err)

		var decoded PriceEvent
		err = json.Unmarshal(data, &decoded)
		assert.NoError(t, err)
		assert.Equal(t, original, decoded)
	}
}

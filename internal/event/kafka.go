package event

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/segmentio/kafka-go"
)

type PriceEvent struct {
	Symbol    string `json:"symbol"`
	PriceUSD  string `json:"price_usd"`
	Source    string `json:"source"`
	Timestamp int64  `json:"timestamp"`
}

type KafkaProducer struct {
	writer *kafka.Writer
}

func NewKafkaProducer(broker, topic string) *KafkaProducer {
	writer := &kafka.Writer{
		Addr:     kafka.TCP(broker),
		Topic:    topic,
		Balancer: &kafka.LeastBytes{},
	}
	return &KafkaProducer{writer: writer}
}

func (p *KafkaProducer) PublishPriceEvent(ctx context.Context, event PriceEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal price event: %w", err)
	}

	return p.writer.WriteMessages(ctx, kafka.Message{
		Key:   []byte(event.Symbol),
		Value: data,
	})
}

func (p *KafkaProducer) Close() error {
	return p.writer.Close()
}

type PriceEventHandler func(event PriceEvent) error

type KafkaConsumer struct {
	reader  *kafka.Reader
	handler PriceEventHandler
}

func NewKafkaConsumer(broker, topic, groupID string, handler PriceEventHandler) *KafkaConsumer {
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:  []string{broker},
		Topic:    topic,
		GroupID:  groupID,
		MinBytes: 10e3,
		MaxBytes: 10e6,
	})
	return &KafkaConsumer{reader: reader, handler: handler}
}

func (c *KafkaConsumer) Start(ctx context.Context) {
	go func() {
		for {
			msg, err := c.reader.ReadMessage(ctx)
			if err != nil {
				if ctx.Err() != nil {
					return
				}
				log.Printf("Kafka read error: %v", err)
				continue
			}

			var event PriceEvent
			if err := json.Unmarshal(msg.Value, &event); err != nil {
				log.Printf("Failed to unmarshal price event: %v", err)
				continue
			}

			if err := c.handler(event); err != nil {
				log.Printf("Failed to handle price event: %v", err)
			}
		}
	}()
}

func (c *KafkaConsumer) Close() error {
	return c.reader.Close()
}

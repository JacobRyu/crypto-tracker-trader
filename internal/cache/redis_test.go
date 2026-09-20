package cache

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestRedisClient_SetGet(t *testing.T) {
	client, err := NewRedisClient("localhost", "6379", "", 0)
	if err != nil {
		t.Skip("Redis not available, skipping test")
	}
	defer client.Close()

	ctx := context.Background()
	err = client.Set(ctx, "test:key", "test-value", 10*time.Second)
	assert.NoError(t, err)

	val, err := client.Get(ctx, "test:key")
	assert.NoError(t, err)
	assert.Equal(t, "test-value", val)
}

func TestRedisClient_Del(t *testing.T) {
	client, err := NewRedisClient("localhost", "6379", "", 0)
	if err != nil {
		t.Skip("Redis not available, skipping test")
	}
	defer client.Close()

	ctx := context.Background()
	err = client.Set(ctx, "test:del-key", "to-delete", 10*time.Second)
	assert.NoError(t, err)

	err = client.Del(ctx, "test:del-key")
	assert.NoError(t, err)

	_, err = client.Get(ctx, "test:del-key")
	assert.Error(t, err)
}

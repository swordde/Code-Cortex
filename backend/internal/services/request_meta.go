package services

import (
	"context"

	"github.com/google/uuid"
)

type requestIDContextKey struct{}

func WithRequestID(ctx context.Context, requestID string) context.Context {
	if requestID == "" {
		return ctx
	}
	return context.WithValue(ctx, requestIDContextKey{}, requestID)
}

func RequestIDFromContext(ctx context.Context) string {
	v := ctx.Value(requestIDContextKey{})
	if id, ok := v.(string); ok {
		return id
	}
	return ""
}

func EnsureRequestID(id string) string {
	if id != "" {
		return id
	}
	return uuid.NewString()
}

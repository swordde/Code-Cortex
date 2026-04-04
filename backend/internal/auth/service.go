package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"sync"
	"time"

	"cortex/backend/internal/models"
)

type Service struct {
	mu          sync.RWMutex
	signatures  map[string]models.VoiceSignature
	secretBytes []byte
}

func NewService(secret string) *Service {
	return &Service{
		signatures:  make(map[string]models.VoiceSignature),
		secretBytes: []byte(secret),
	}
}

func (s *Service) StoreVoiceSignature(userID, signatureHash string) models.VoiceSignature {
	s.mu.Lock()
	defer s.mu.Unlock()

	sig := models.VoiceSignature{
		UserID:        userID,
		SignatureHash: signatureHash,
		CreatedAt:     time.Now().UTC(),
	}
	s.signatures[userID] = sig
	return sig
}

func (s *Service) CreateActivationToken(userID string, ttl time.Duration) string {
	expires := time.Now().UTC().Add(ttl).Unix()
	payload := fmt.Sprintf("%s:%d", userID, expires)

	mac := hmac.New(sha256.New, s.secretBytes)
	_, _ = mac.Write([]byte(payload))
	signature := hex.EncodeToString(mac.Sum(nil))

	token := fmt.Sprintf("%s:%s", payload, signature)
	return base64.RawURLEncoding.EncodeToString([]byte(token))
}

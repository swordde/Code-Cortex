package dispatch

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"time"

	"cortex/backend/internal/models"
)

type Dispatcher struct {
	flutterURL       string
	quickShellSocket string
	httpClient       *http.Client
}

func NewDispatcher(flutterURL, quickShellSocket string) *Dispatcher {
	return &Dispatcher{
		flutterURL:       flutterURL,
		quickShellSocket: quickShellSocket,
		httpClient: &http.Client{
			Timeout: 2 * time.Second,
		},
	}
}

func (d *Dispatcher) Dispatch(n models.Notification, result models.ClassificationResult) error {
	payload := map[string]any{
		"notification": n,
		"result":       result,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	var errs []error

	if d.flutterURL != "" {
		req, err := http.NewRequest(http.MethodPost, d.flutterURL, bytes.NewReader(body))
		if err != nil {
			errs = append(errs, fmt.Errorf("flutter dispatch request build failed: %w", err))
		} else {
			req.Header.Set("Content-Type", "application/json")
			resp, err := d.httpClient.Do(req)
			if err != nil {
				errs = append(errs, fmt.Errorf("flutter dispatch failed: %w", err))
			} else {
				_ = resp.Body.Close()
				if resp.StatusCode < 200 || resp.StatusCode >= 300 {
					errs = append(errs, fmt.Errorf("flutter dispatch non-2xx: %d", resp.StatusCode))
				}
			}
		}
	}

	if d.quickShellSocket != "" {
		conn, err := net.DialTimeout("unix", d.quickShellSocket, 1500*time.Millisecond)
		if err != nil {
			errs = append(errs, fmt.Errorf("quickshell socket dispatch failed: %w", err))
		} else {
			_, writeErr := conn.Write(append(body, '\n'))
			_ = conn.Close()
			if writeErr != nil {
				errs = append(errs, fmt.Errorf("quickshell socket write failed: %w", writeErr))
			}
		}
	}

	return errors.Join(errs...)
}

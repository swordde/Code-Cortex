package main

import (
	"context"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"cortex/backend/internal/ai"
	"cortex/backend/internal/analytics"
	"cortex/backend/internal/auth"
	"cortex/backend/internal/config"
	"cortex/backend/internal/dispatch"
	"cortex/backend/internal/modes"
	"cortex/backend/internal/orchestrator"
	"cortex/backend/internal/rules"
	"cortex/backend/internal/server"
)

func main() {
	cfg := config.FromEnv()

	rulesEngine := rules.NewEngine()
	modeManager := modes.NewManager()
	aiClient := ai.NewClient(cfg.AIEndpoint)
	orc := orchestrator.New(aiClient, rulesEngine, modeManager, cfg.ClassificationTries)
	dispatcher := dispatch.NewDispatcher(cfg.FlutterDispatchURL, cfg.QuickShellSocket)
	authService := auth.NewService(cfg.ActivationSecret)

	analyticsWriter, err := analytics.NewWriter(cfg.SQLitePath)
	if err != nil {
		log.Fatalf("failed to initialize analytics sqlite: %v", err)
	}
	defer func() {
		_ = analyticsWriter.Close()
	}()

	api := server.NewAPI(orc, rulesEngine, modeManager, dispatcher, authService, analyticsWriter)

	httpServer := &http.Server{
		Addr:         cfg.ListenAddr,
		Handler:      api.Routes(),
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("cortex backend listening on %s", cfg.ListenAddr)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("http server failed: %v", err)
		}
	}()

	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = httpServer.Shutdown(shutdownCtx)
	log.Println("cortex backend shutdown complete")
}

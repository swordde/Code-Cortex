package main

import (
	"context"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"cortex/backend/internal/config"
	"cortex/backend/internal/server"
	"cortex/backend/internal/services"
	"cortex/backend/internal/store"
)

func main() {
	cfg := config.Load()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	mongoStore, err := store.NewMongoStore(ctx, cfg.MongoURI, cfg.MongoDBName, cfg.MongoTimeout, cfg.MongoInsecure)
	if err != nil {
		log.Fatalf("failed connecting MongoDB: %v", err)
	}
	defer func() {
		closeCtx, closeCancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer closeCancel()
		_ = mongoStore.Close(closeCtx)
	}()

	dispatcher := services.NewPushDispatcher(cfg.UnixSocketPath)
	aiProxy := services.NewAIProxyService(cfg.AIServiceURL, cfg.AITimeoutSec)
	voiceRuntime := services.NewVoiceAssistantRuntimeService(aiProxy)
	modelStatus := services.NewModelStatusService(aiProxy)
	modelStatus.Start(context.Background())
	classifier := services.NewClassifierService(cfg.AIServiceURL, cfg.AITimeoutSec)
	feedback := services.NewFeedbackService(cfg.AIServiceURL, cfg.AITimeoutSec)
	analyticsService := services.NewAnalyticsService(mongoStore)
	modeManager := services.NewModeManager(mongoStore, dispatcher)
	if err := modeManager.Init(context.Background()); err != nil {
		log.Fatalf("failed to initialize mode manager: %v", err)
	}
	cortexService := services.NewCortexService(mongoStore, dispatcher, cfg.AIServiceURL, cfg.AITimeoutSec)

	api := server.NewAPI(cfg, mongoStore, classifier, feedback, analyticsService, modeManager, cortexService, aiProxy, modelStatus, dispatcher)

	httpServer := &http.Server{
		Addr:         cfg.Port,
		Handler:      api.Routes(),
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("cortex backend listening on %s", cfg.Port)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("http server failed: %v", err)
		}
	}()

	voiceRuntime.Start(ctx)

	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = httpServer.Shutdown(shutdownCtx)
	log.Println("cortex backend shutdown complete")
}

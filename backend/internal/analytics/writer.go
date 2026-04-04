package analytics

import (
	"context"
	"database/sql"
	"time"

	_ "modernc.org/sqlite"

	"cortex/backend/internal/models"
)

type Event struct {
	Notification models.Notification
	Result       models.ClassificationResult
}

type Writer struct {
	db     *sql.DB
	queue  chan Event
	cancel context.CancelFunc
}

func NewWriter(sqlitePath string) (*Writer, error) {
	db, err := sql.Open("sqlite", sqlitePath)
	if err != nil {
		return nil, err
	}

	stmt := `
CREATE TABLE IF NOT EXISTS analytics_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,
    platform TEXT,
    app TEXT,
    sender TEXT,
    title TEXT,
    content TEXT,
    ai_label TEXT,
    final_label TEXT,
    mode TEXT,
    overridden_by TEXT,
    reason TEXT
);`

	if _, err := db.Exec(stmt); err != nil {
		_ = db.Close()
		return nil, err
	}

	ctx, cancel := context.WithCancel(context.Background())
	w := &Writer{
		db:     db,
		queue:  make(chan Event, 256),
		cancel: cancel,
	}
	go w.loop(ctx)
	return w, nil
}

func (w *Writer) Enqueue(event Event) {
	select {
	case w.queue <- event:
	default:
		// Intentionally drop when overloaded to keep ingestion low-latency.
	}
}

func (w *Writer) Close() error {
	w.cancel()
	time.Sleep(50 * time.Millisecond)
	close(w.queue)
	return w.db.Close()
}

func (w *Writer) loop(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case ev, ok := <-w.queue:
			if !ok {
				return
			}
			_, _ = w.db.Exec(
				`INSERT INTO analytics_events(created_at, platform, app, sender, title, content, ai_label, final_label, mode, overridden_by, reason)
                 VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
				time.Now().UTC().Format(time.RFC3339),
				ev.Notification.Platform,
				ev.Notification.App,
				ev.Notification.Sender,
				ev.Notification.Title,
				ev.Notification.Content,
				ev.Result.AILabel,
				ev.Result.FinalLabel,
				ev.Result.Mode,
				ev.Result.OverriddenBy,
				ev.Result.Reason,
			)
		}
	}
}

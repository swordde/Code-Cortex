package services

import (
	"encoding/json"
	"net"
	"runtime"
	"sync"
	"time"

	"cortex/backend/internal/models"

	"github.com/gorilla/websocket"
)

type PushDispatcher struct {
	mu             sync.RWMutex
	connections    map[*websocket.Conn]struct{}
	unixSocketPath string
}

func NewPushDispatcher(unixSocketPath string) *PushDispatcher {
	return &PushDispatcher{connections: map[*websocket.Conn]struct{}{}, unixSocketPath: unixSocketPath}
}

func (d *PushDispatcher) AddConn(conn *websocket.Conn) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.connections[conn] = struct{}{}
}

func (d *PushDispatcher) RemoveConn(conn *websocket.Conn) {
	d.mu.Lock()
	defer d.mu.Unlock()
	delete(d.connections, conn)
	_ = conn.Close()
}

func (d *PushDispatcher) DispatchNotification(n *models.Notification) {
	msg := models.NotificationMessage{Type: "NEW_NOTIFICATION", Payload: *n}
	d.broadcastJSON(msg)
}

func (d *PushDispatcher) DispatchModeChanged(mode string) {
	msg := models.ModeChangedMessage{Type: "MODE_CHANGED", Payload: map[string]any{"mode": mode}}
	d.broadcastJSON(msg)
}

func (d *PushDispatcher) DispatchCortexAction(entry *models.CortexActivityEntry) {
	msg := models.CortexActionMessage{Type: "CORTEX_ACTION", Payload: *entry}
	d.broadcastJSON(msg)
}

func (d *PushDispatcher) broadcastJSON(v any) {
	body, err := json.Marshal(v)
	if err != nil {
		return
	}
	d.mu.RLock()
	conns := make([]*websocket.Conn, 0, len(d.connections))
	for c := range d.connections {
		conns = append(conns, c)
	}
	d.mu.RUnlock()

	for _, conn := range conns {
		_ = conn.SetWriteDeadline(time.Now().Add(1500 * time.Millisecond))
		if err := conn.WriteMessage(websocket.TextMessage, body); err != nil {
			d.RemoveConn(conn)
		}
	}
	_ = d.writeUnixSocket(body)
}

func (d *PushDispatcher) writeUnixSocket(body []byte) error {
	if runtime.GOOS != "linux" || d.unixSocketPath == "" {
		return nil
	}
	conn, err := net.DialTimeout("unix", d.unixSocketPath, 1200*time.Millisecond)
	if err != nil {
		return err
	}
	defer conn.Close()
	_, err = conn.Write(append(body, '\n'))
	return err
}

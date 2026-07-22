package sse

import "sync"

// Hub mantiene el conjunto de clientes SSE conectados y les hace broadcast.
type Hub struct {
	mu      sync.RWMutex
	clients map[chan []byte]struct{}
}

func NewHub() *Hub {
	return &Hub{clients: make(map[chan []byte]struct{})}
}

// Subscribe registra un canal de cliente y lo devuelve.
func (h *Hub) Subscribe() chan []byte {
	ch := make(chan []byte, 8)
	h.mu.Lock()
	h.clients[ch] = struct{}{}
	h.mu.Unlock()
	return ch
}

// Unsubscribe elimina el canal del cliente y lo cierra.
func (h *Hub) Unsubscribe(ch chan []byte) {
	h.mu.Lock()
	delete(h.clients, ch)
	h.mu.Unlock()
	close(ch)
}

// Broadcast envía data a todos los clientes suscritos. No bloquea si un canal está lleno.
func (h *Hub) Broadcast(data []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for ch := range h.clients {
		select {
		case ch <- data:
		default:
		}
	}
}

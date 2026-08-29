package llmclient

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCompletar_UsaEndpointNativoSiResponde(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/completion" {
			t.Fatalf("esperaba /completion, got %s", r.URL.Path)
		}
		json.NewEncoder(w).Encode(map[string]string{"content": "respuesta nativa"})
	}))
	defer srv.Close()

	texto, err := Completar(context.Background(), srv.URL, "sistema", "pregunta")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if texto != "respuesta nativa" {
		t.Errorf("esperaba 'respuesta nativa', got %q", texto)
	}
}

func TestCompletar_CaeAChatCompletionsSiNativoFalla(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/completion":
			w.WriteHeader(http.StatusNotFound)
		case "/v1/chat/completions":
			json.NewEncoder(w).Encode(map[string]any{
				"choices": []map[string]any{
					{"message": map[string]string{"content": "respuesta chat"}},
				},
			})
		default:
			t.Fatalf("ruta inesperada: %s", r.URL.Path)
		}
	}))
	defer srv.Close()

	texto, err := Completar(context.Background(), srv.URL, "sistema", "pregunta")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if texto != "respuesta chat" {
		t.Errorf("esperaba 'respuesta chat', got %q", texto)
	}
}

func TestCompletar_ErrorSiAmbosFallan(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer srv.Close()

	_, err := Completar(context.Background(), srv.URL, "sistema", "pregunta")
	if err == nil {
		t.Fatal("esperaba error, got nil")
	}
}

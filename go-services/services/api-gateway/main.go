package main

import (
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
)

func main() {
	phpBackendURL := getEnv("PHP_BACKEND_URL", "http://php-api")
	frontendURL := getEnv("FRONTEND_URL", "http://frontend")

	phpProxy := createReverseProxy(phpBackendURL)
	frontendProxy := createReverseProxy(frontendURL)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path

		switch {
		case strings.HasPrefix(path, "/api/"):
			// Route /api/* to PHP backend
			r.URL.Path = strings.TrimPrefix(path, "/api")
			phpProxy.ServeHTTP(w, r)
		case path == "/health":
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("OK\n"))
		default:
			// Route everything else to frontend
			frontendProxy.ServeHTTP(w, r)
		}
	})

	log.Println("Starting API Gateway on :8080")
	log.Printf("  /api/* -> %s", phpBackendURL)
	log.Printf("  /*     -> %s", frontendURL)
	if err := http.ListenAndServe(":80", nil); err != nil {
		log.Fatal(err)
	}
}

func createReverseProxy(targetURL string) *httputil.ReverseProxy {
	target, err := url.Parse(targetURL)
	if err != nil {
		log.Fatalf("Failed to parse URL %s: %v", targetURL, err)
	}
	return httputil.NewSingleHostReverseProxy(target)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

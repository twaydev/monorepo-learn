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
	phpURL := getEnv("PHP_BACKEND_URL", "http://php-api")
	rustURL := getEnv("RUST_BACKEND_URL", "http://rust-api")
	goURL := getEnv("GO_BACKEND_URL", "http://go-api")
	frontendURL := getEnv("FRONTEND_URL", "http://frontend")

	phpProxy := createReverseProxy(phpURL)
	rustProxy := createReverseProxy(rustURL)
	goProxy := createReverseProxy(goURL)
	frontendProxy := createReverseProxy(frontendURL)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path

		switch {
		case strings.HasPrefix(path, "/services/php-apis"):
			// Route /services/php-apis/* to PHP backend
			r.URL.Path = strings.TrimPrefix(path, "/services/php-apis")
			phpProxy.ServeHTTP(w, r)
		case strings.HasPrefix(path, "/services/rust-apis"):
			// Route /services/rust-apis/* to Rust backend
			r.URL.Path = strings.TrimPrefix(path, "/services/rust-apis")
			rustProxy.ServeHTTP(w, r)
		case strings.HasPrefix(path, "/services/go-apis"):
			// Route /services/go-apis/* to Go backend
			r.URL.Path = strings.TrimPrefix(path, "/services/go-apis")
			goProxy.ServeHTTP(w, r)
		case path == "/health":
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("OK\n"))
		default:
			// Route everything else to frontend
			frontendProxy.ServeHTTP(w, r)
		}
	})

	log.Println("Starting API Gateway on :80")
	log.Printf("  /services/php-apis/* -> %s", phpURL)
	log.Printf("  /services/rust-apis/* -> %s", rustURL)
	log.Printf("  /services/go-apis/* -> %s", goURL)
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

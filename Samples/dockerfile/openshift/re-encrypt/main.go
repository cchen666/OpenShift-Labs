package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"log"
	"net/http"
)

// Handler function that returns the client IP address
func clientIPHandler(w http.ResponseWriter, r *http.Request) {
	clientIP := r.RemoteAddr
	fmt.Fprintf(w, "Client IP: %s\n", clientIP)
}

func main() {
	// Command-line flag to enable or disable TLS
	insecure := flag.Bool("insecure", false, "disable TLS and use HTTP")
	flag.Parse()

	// Paths to the certificate and key files
	certFile := "/etc/tls/tls.crt"
	keyFile := "/etc/tls/tls.key"

	// Create a new HTTP server
	server := &http.Server{
		Addr:    ":30888",
		Handler: http.HandlerFunc(clientIPHandler),
	}

	if *insecure {
		// Start the HTTP server
		log.Println("Starting HTTP server on port 30888...")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("failed to start HTTP server: %v", err)
		}
	} else {
		// Load the certificate and key pair
		cert, err := tls.LoadX509KeyPair(certFile, keyFile)
		if err != nil {
			log.Fatalf("failed to load certificate and key pair: %v", err)
		}

		// Configure TLS
		server.TLSConfig = &tls.Config{
			Certificates: []tls.Certificate{cert},
		}

		// Start the HTTPS server
		log.Println("Starting TLS HTTPS server on port 30888...")
		if err := server.ListenAndServeTLS(certFile, keyFile); err != nil && err != http.ErrServerClosed {
			log.Fatalf("failed to start HTTPS server: %v", err)
		}
	}
}

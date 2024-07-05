package main

import (
	"fmt"
	"net"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Get the IP addresses of the machine
		addrs, err := net.InterfaceAddrs()
		if err != nil {
			http.Error(w, "Unable to get IP address", http.StatusInternalServerError)
			return
		}

		// Iterate over the addresses and find the non-loopback IP address
		var ip string
		for _, addr := range addrs {
			if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
				if ipNet.IP.To4() != nil {
					ip = ipNet.IP.String()
					break
				}
			}
		}

		if ip == "" {
			http.Error(w, "No IP address found", http.StatusInternalServerError)
			return
		}

		// Print the IP address to the response
		fmt.Fprintf(w, "Pod IP: %s\n", ip)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Starting server on port %s...\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Printf("Error starting server: %v\n", err)
	}
}

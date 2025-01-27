package main

import (
	"fmt"
	"log"
	"os"
)

func main() {
	// File paths
	filePath := "testfile.txt"
	tempPath := "testfile.tmp"

	// Create a temporary file
	if err := os.WriteFile(tempPath, []byte("New content"), 0644); err != nil {
		log.Fatalf("Failed to create temporary file: %v", err)
	}
	fmt.Println("Temporary file created.")

	// Perform the Rename operation
	if err := os.Rename(tempPath, filePath); err != nil {
		log.Fatalf("Failed to rename file: %v", err)
	}
	fmt.Println("File renamed.")
}

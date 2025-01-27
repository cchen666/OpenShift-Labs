package main

import (
	"fmt"
	"log"
	"os"

	"github.com/fsnotify/fsnotify"
)

func main() {
	// Create a new watcher
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatalf("Failed to create watcher: %v", err)
	}
	defer watcher.Close()

	// File to monitor
	filePath := "testfile.txt"

	// Add the file to the watcher
	if err := watcher.Add(filePath); err != nil {
		log.Fatalf("Failed to add file to watcher: %v", err)
	}

	fmt.Printf("Monitoring file [%s] for Remove events...\n", filePath)

	// Start a goroutine to handle events
	for {
		select {
		case event, ok := <-watcher.Events:
			if !ok {
				return
			}
			// Log the event
			fmt.Printf("Event: %s\n", event)
			if event.Op.Has(fsnotify.Remove) {
				fmt.Printf("File [%s] has been removed.\n", filePath)
				// Check if the file still exists after a short delay
				if _, err := os.Stat(filePath); os.IsNotExist(err) {
					fmt.Printf("File [%s] no longer exists. Exiting...\n", filePath)
					return
				} else {
					fmt.Printf("File [%s] still exists. Ignoring Remove event.\n", filePath)
				}
				//time.Sleep(10000 * time.Millisecond)
			}
		case err, ok := <-watcher.Errors:
			if !ok {
				return
			}
			log.Printf("Watcher error: %v", err)
		}
	}
}

package main

import (
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/fsnotify/fsnotify"
)

func main() {
	dir, _ := os.Getwd()
	crt := filepath.Join(dir, "tls/tls.crt")
	key := filepath.Join(dir, "tls/tls.key")

	w, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer w.Close()

	for i := 0; i < 1; i++ {
		_ = w.Add(crt)
		_ = w.Add(key)

		_ = os.Remove(crt)
		time.Sleep(10 * time.Millisecond)
		_ = os.Remove(key)
		_, _ = os.Create(crt)
		_, _ = os.Create(key)
	}
	for i := 0; i < 1; i++ {
		_ = w.Add(crt)
		_ = w.Add(key)

		_ = os.Remove(crt)
		_ = os.Remove(key)
		_, _ = os.Create(crt)
		_, _ = os.Create(key)
	}
	done := time.After(1 * time.Second)
	for {
		select {
		case ev := <-w.Events:
			log.Printf("%-7s  %s", ev.Op, ev.Name)
		case err := <-w.Errors:
			log.Printf("ERROR   %v", err)
		case <-done:
			log.Printf("timeout - stop")
			return
		}
	}
}

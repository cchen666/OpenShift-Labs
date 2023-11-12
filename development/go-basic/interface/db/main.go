//Wrong sample, need revise

package main

import (
	"fmt"
	"sync"
)

// DatabaseConnection represents a generic database connection
type DatabaseConnection interface {
	Query(query string) string
}

// MySQLDatabaseConnection represents a MySQL database connection
type MySQLDatabaseConnection struct {
	ID int
}

// Query performs a database query for MySQL
func (db *MySQLDatabaseConnection) Query(query string) string {
	return fmt.Sprintf("MySQL Query from DB %d: %s", db.ID, query)
}

// PostgreSQLDatabaseConnection represents a PostgreSQL database connection
type PostgreSQLDatabaseConnection struct {
	ID int
}

// Query performs a database query for PostgreSQL
func (db *PostgreSQLDatabaseConnection) Query(query string) string {
	return fmt.Sprintf("PostgreSQL Query from DB %d: %s", db.ID, query)
}

// ConnectionPool represents a pool of database connections
type ConnectionPool struct {
	MaxConnections int
	Connections    []DatabaseConnection
	mu             sync.Mutex
}

// NewConnectionPool creates a new connection pool
func NewConnectionPool(maxConnections int) *ConnectionPool {
	return &ConnectionPool{
		MaxConnections: maxConnections,
		Connections:    make([]DatabaseConnection, maxConnections),
	}
}

func (pool *ConnectionPool) GetConnection() DatabaseConnection {
	pool.mu.Lock()
	defer pool.mu.Unlock()

	// Simulate obtaining a connection from the pool
	for i, conn := range pool.Connections {
		if conn == nil {
			if i%2 == 0 {
				pool.Connections[i] = &MySQLDatabaseConnection{ID: i + 1}
			} else {
				pool.Connections[i] = &PostgreSQLDatabaseConnection{ID: i + 1}
			}
			return pool.Connections[i]
		}
	}
	return nil // No available connections
}

// ReleaseConnection releases a database connection back to the pool
func (pool *ConnectionPool) ReleaseConnection(db DatabaseConnection) {
	pool.mu.Lock()
	defer pool.mu.Unlock()

	// Simulate releasing a connection
	for i, conn := range pool.Connections {
		if conn == db {
			pool.Connections[i] = nil // Mark connection as available
			return
		}
	}
}

func main() {
	pool := NewConnectionPool(3)

	// Get and use a MySQL database connection
	db1 := pool.GetConnection()
	fmt.Println(db1.Query("SELECT * FROM users"))

	// Release the connection back to the pool
	pool.ReleaseConnection(db1)

	// Get and use a PostgreSQL database connection
	db2 := pool.GetConnection()
	fmt.Println(db2.Query("INSERT INTO orders VALUES (1, 'product')"))

	// Release the second connection back to the pool
	pool.ReleaseConnection(db2)
}

package main

import (
	"net/http"
	"os"

	"github.com/labstack/echo"
)

func getIP(c echo.Context) error {
	ip, ok := os.LookupEnv("POD_IP")
	if !ok {
		return c.String(http.StatusNotFound, "POD_IP env not found")
	}
	return c.String(http.StatusOK, ip)
}

func main() {
	e := echo.New()
	e.GET("/", getIP)
	e.Logger.Fatal(e.Start(":1323"))
}

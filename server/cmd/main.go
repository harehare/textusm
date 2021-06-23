package main

import (
	"os"

	server "github.com/harehare/textusm/pkg/app"
)

func main() {
	os.Exit(server.Run())
}

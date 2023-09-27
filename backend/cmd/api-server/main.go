package main

import (
	"os"

	backend "github.com/harehare/textusm/internal/app"
)

func main() {
	os.Exit(backend.Run())
}

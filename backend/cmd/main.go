package main

import (
	"os"

	backend "github.com/harehare/textusm/pkg/app"
)

func main() {
	os.Exit(backend.Run())
}

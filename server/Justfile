alias g := generate

go := "go"
module := "github.com/harehare/textusm"
run := go + " run"
fmt := go + " fmt"
test := go + " test"
generate := go + " generate"
lint := "staticcheck"
sec := "gosec"
main := "cmd/main.go"
target := "./..."

setup:
  {{ go }} get honnef.co/go/tools/cmd/staticcheck
  {{ go }} get github.com/securego/gosec/v2/cmd/gosec

run:
	{{ run }} {{ main }}

generate:
	{{ generate }} {{ target }}

test:
	{{ test }} {{ target }}

fmt:
  {{ fmt }}

lint:
	{{ lint }} {{ module }}
	{{ sec }} {{ target }}

clean:
	{{ go }} mod tidy

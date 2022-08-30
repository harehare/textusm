FROM golang:1.19 as builder

WORKDIR /go/src/app
COPY . /go/src/app/

RUN go mod download
RUN GOOS="linux" GOARCH="amd64" go build -o dist/textusm cmd/main.go

FROM gcr.io/distroless/static-debian11:nonroot-amd64
COPY --from=builder --chown=nonroot:nonroot /go/src/app/dist/textusm /
CMD ["/textusm"]

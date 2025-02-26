FROM golang:1.24 as builder

WORKDIR /go/src/app
COPY . /go/src/app/

RUN go mod download
RUN CGO_ENABLED=0 go build -o dist/textusm cmd/api-server/main.go

FROM gcr.io/distroless/static-debian11:nonroot
COPY --from=builder --chown=nonroot:nonroot /go/src/app/dist/textusm /
CMD ["/textusm"]

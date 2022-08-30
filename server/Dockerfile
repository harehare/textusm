FROM golang:1.19.0-alpine3.16 as builder

WORKDIR /go/src/app
COPY . /go/src/app/

RUN apk add just
RUN just build-linux

FROM gcr.io/distroless/static-debian11
COPY --from=builder /go/src/app/dist/textusm /
USER nonroot
CMD ["./textusm"]

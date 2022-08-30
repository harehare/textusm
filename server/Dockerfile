FROM golang:1.19.0-alpine3.16 as builder

WORKDIR /go/src/app
COPY . /go/src/app/

RUN apk add just
RUN just build-linux

FROM gcr.io/distroless/static-debian11:nonroot
WORKDIR /usr/app
COPY --from=builder --chown=nonroot:nonroot /go/src/app/dist/textusm .
CMD ["/usr/app/textusm"]

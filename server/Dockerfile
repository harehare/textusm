FROM golang:1.16-alpine3.14 as builder

WORKDIR /go/src/app
ADD . /go/src/app

RUN apk add just
RUN just build

FROM gcr.io/distroless/static-debian10
COPY --from=builder /go/src/app/textusm /
CMD ["/textusm"]

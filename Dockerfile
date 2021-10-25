FROM node:slim AS web-builder
WORKDIR /app
COPY web .
RUN npm i
RUN npm run generate-elm-constants
RUN npm i -g elm
RUN npm run prod

FROM golang:alpine as server-builder
WORKDIR /go/src/app
COPY server/* /go/src/app
COPY --from=web-builder /app/dist /go/src/app
RUN apk add just
RUN just build

FROM gcr.io/distroless/static-debian10
COPY --from=server-builder /go/src/app/textusm /
ENV EMBED_WEB_RESOURCE 1
RUN adduser -D textusm && chown -R textusm /go/src/app/
USER textusm
CMD ["/textusm"]

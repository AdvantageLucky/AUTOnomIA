FROM golang:1.26-bookworm AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /out/server ./cmd/server

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /out/server ./server
COPY migrations ./migrations
COPY web/admin ./web/admin
RUN mkdir -p ./web/uploads/visitantes ./web/uploads/caras

EXPOSE 8080

ENTRYPOINT ["./server"]

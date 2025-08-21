FROM golang:1.22 as builder
WORKDIR /src

# Copy the entire repository (build context should be repo root)
COPY . .

# Build the gateway binary
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags "-s -w -buildid=" -a -o /out/gateway ./external/gateway/cmd/gateway

FROM cgr.dev/chainguard/static:latest
COPY --from=builder /out/gateway /gateway
USER 65532:65532
EXPOSE 8080 50051
ENTRYPOINT ["/gateway"]
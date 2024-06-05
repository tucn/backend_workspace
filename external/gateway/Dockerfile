FROM golang:1.20.1-buster as builder
WORKDIR /app
COPY . .

WORKDIR /app/sample/gobackend
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags=-buildid= -mod vendor -a -o ./gobackend -v ./cmd/gobackend

FROM cgr.dev/chainguard/static@sha256:69c1e79431374847fbc21d74dc632e717040a1a7d795f7128ca73e7b8c028eae
COPY --from=builder /app/sample/gobackend/gobackend .
ENTRYPOINT ["./gobackend"]
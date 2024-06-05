package main

import (
	"context"

	gateway "github.com/tucn/backend_workspace/api/gen/go/gateway"
)

type VersionServiceServer struct {
	gateway.UnsafeVersionServiceServer
}

func newVersionServiceServer() *VersionServiceServer {
	return &VersionServiceServer{}
}

func (v *VersionServiceServer) GetVersion(ctx context.Context, req *gateway.VersionRequest) (*gateway.VersionResponse, error) {
	version := "1.0.0"
	return &gateway.VersionResponse{Version: version}, nil
}

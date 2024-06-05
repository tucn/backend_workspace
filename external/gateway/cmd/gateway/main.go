package main

import (
	"github.com/tucn/backend_workspace/core"
	"google.golang.org/grpc"

	pb "github.com/tucn/backend_workspace/api/gen/go/gateway"
)

func main() {
	grpcAddress := ":50051"
	httpAddress := ":8080"

	versionSvc := newVersionServiceServer()
	server := core.NewCore(
		grpcAddress,
		httpAddress,
		[]core.ServerMode{core.ServerModeGRPC, core.ServerModeHTTP},
		func(s *grpc.Server) {
			pb.RegisterVersionServiceServer(s, versionSvc)
		},
		pb.RegisterVersionServiceHandlerFromEndpoint,
	)

	server.Serve()
}

package core

import (
	"context"
	"io/fs"
	"log"
	"mime"
	"net"
	"net/http"
	"strings"
	"sync"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	swagger "github.com/tucn/backend_workspace/api/gen"
	"google.golang.org/grpc"
)

// ServerMode specifies the server mode (e.g. "HTTP", "GRPC").
type ServerMode string

const (
	// ServerModeHTTP specifies the HTTP server mode.
	ServerModeHTTP ServerMode = "HTTP"
	// ServerModeGRPC specifies the gRPC server mode.
	ServerModeGRPC ServerMode = "GRPC"
)

type Core struct {
	GRPCAddress      string
	HTTPAddress      string
	Mode             []ServerMode
	RegisterGRPCFunc func(*grpc.Server)
	RegisterHTTPFunc func(context.Context, *runtime.ServeMux, string, []grpc.DialOption) error
}

// NewCore creates a new core server instance with the provided configuration.
// The server will register the VersionService gRPC and HTTP handlers.
// The GRPCAddress and HTTPAddress fields specify the addresses to listen on for gRPC and HTTP requests, respectively.
// The Mode field specifies the server mode (e.g. "dev", "prod").
// The RegisterGRPCFunc field is a callback that allows registering additional gRPC services on the server.
// The RegisterHTTPFunc field is a callback that allows registering additional HTTP handlers on the server.
func NewCore(grpcAddress, httpAddress string, mode []ServerMode,
	registerGRPCFunc func(*grpc.Server), registerHTTPFunc func(context.Context, *runtime.ServeMux, string, []grpc.DialOption) error) *Core {
	return &Core{
		GRPCAddress:      grpcAddress,
		HTTPAddress:      httpAddress,
		Mode:             mode,
		RegisterGRPCFunc: registerGRPCFunc,
		RegisterHTTPFunc: registerHTTPFunc,
	}
}

// Serve starts the gRPC and HTTP servers.
func (c *Core) Serve() {
	// Create a map to store unique modes
	modes := make(map[ServerMode]struct{})

	// Iterate over c.Mode and add unique modes to the map
	for _, m := range c.Mode {
		modes[m] = struct{}{}
	}

	var wg sync.WaitGroup

	// Iterate over the unique modes and start the corresponding servers
	for m := range modes {
		wg.Add(1)
		switch m {
		case ServerModeGRPC:
			go func() {
				defer wg.Done()
				if err := c.startGRPCServer(); err != nil {
					log.Fatalf("Failed to start gRPC server: %v", err)
				}
			}()
		case ServerModeHTTP:
			go func() {
				defer wg.Done()
				if err := c.startHTTPServer(); err != nil {
					log.Fatalf("Failed to start HTTP server: %v", err)
				}
			}()
		}
	}

	// Wait for all servers to finish
	wg.Wait()
}

func (c *Core) startGRPCServer() error {
	lis, err := net.Listen("tcp", c.GRPCAddress)
	if err != nil {
		return err
	}

	grpcServer := grpc.NewServer()
	c.RegisterGRPCFunc(grpcServer)

	log.Printf("Starting gRPC server at %s", c.GRPCAddress)
	return grpcServer.Serve(lis)
}

// getOpenAPIHandler serves an OpenAPI UI.
// Adapted from https://github.com/philips/grpc-gateway-example/blob/a269bcb5931ca92be0ceae6130ac27ae89582ecc/cmd/serve.go#L63
func getOpenAPIHandler() http.Handler {
	mime.AddExtensionType(".svg", "image/svg+xml")
	// Use subdirectory in embedded files
	subFS, err := fs.Sub(swagger.OpenAPI, "openapiv2")
	if err != nil {
		panic("couldn't create sub filesystem: " + err.Error())
	}
	return http.FileServer(http.FS(subFS))
}

func (c *Core) startHTTPServer() error {
	ctx := context.Background()
	mux := runtime.NewServeMux()
	opts := []grpc.DialOption{grpc.WithInsecure()}

	if err := c.RegisterHTTPFunc(ctx, mux, c.GRPCAddress, opts); err != nil {
		return err
	}
	oa := getOpenAPIHandler()
	gwServer := &http.Server{
		Addr: c.HTTPAddress,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if strings.HasPrefix(r.URL.Path, "/v1") {
				mux.ServeHTTP(w, r)
				return
			}
			oa.ServeHTTP(w, r)
		}),
	}

	log.Printf("Starting HTTP server at %s", c.HTTPAddress)
	return gwServer.ListenAndServe()
}

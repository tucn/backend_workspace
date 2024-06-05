# API

Definition of our project's API

## Installation

You'll use the protoc-gen-go and protoc-gen-go-grpc plugins to generate code with buf generate, so you'll need to install them:

```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/envoyproxy/protoc-gen-validate@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
```

You also need to update your PATH so that buf can find the plugins:

```bash
export PATH="$PATH:$(go env GOPATH)/bin"
```

## Validation

We are using `envoyproxy/protoc-gen-validate` to validate proto fields and messages and, it will create Validate methods on the generated types

See [Constraint Rules](https://github.com/envoyproxy/protoc-gen-validate#constraint-rules)

eg:

```protobuf
syntax = "proto3";

package examplepb;

import "validate/validate.proto";

message Person {
  uint64 id    = 1 [(validate.rules).uint64.gt    = 999];

  string email = 2 [(validate.rules).string.email = true];

  string name  = 3 [(validate.rules).string = {
                      pattern:   "^[^[0-9]A-Za-z]+( [^[0-9]A-Za-z]+)*$",
                      max_bytes: 256,
                   }];

  Location home = 4 [(validate.rules).message.required = true];

  message Location {
    double lat = 1 [(validate.rules).double = { gte: -90,  lte: 90 }];
    double lng = 2 [(validate.rules).double = { gte: -180, lte: 180 }];
  }
}
```

## Parsers

Each API folder may contain `parser.go` file that defines parsers for

- resource names (e.g., `orgs/<id>/users/<user_id>`)
- filters (e.g., list organization user's `pending = (true|false)`) ? What's the best way to return?

### Naming

The parser naming convention is:

- Start with `Parse`
- Followed by the resource path where each returned sub-resource:
  - is Pascal case
  - singular form (`Org`, **not** `Orgs`)
  - ends with parsing details. E.g., `WithDash`

  ```
  OrgUser | OrgUserLocationPermission | OrgWithDash
  ```

- Followed by the parser type such as `Name` or `Filter`
- Ends with an optional `Exact` to indicate the match is exact (meaning `$` is ath the end of regex)

Examples: `parseOrgUserLocationPermissionName`, `parseOrgWithDashName`, `parseListMemberFilter`, `parseOrgStatsName`

### Return errors

Parsers should return a simple error message as the usage may happen in multiple layers (GRPC, service). E.g.,

```go
return nil, errors.New("org name should be of the form `orgs/([0-9]+)`")
```
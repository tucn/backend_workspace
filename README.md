# Backend Workspace
This is where I put my idea backend workspace design, which I earned from my previous projects. The workspace is based on mono repository concept that support multiple projects and allows us to deploy to multiple environments.

This backend workspace supports 2 types of coding language: 
- Go  
- Java
And it suitable for those who are trying to move from a legacy Java to Go.

## Contents
 - [Requirements](#requirements)
 - [Installation](#installation)


## Requirements
- The minimal version of Go is `1.18`
- The minimal version of Java is around `11`
- Kubernetes. 
    + For MacOS: [Orbstack](https://orbstack.dev/), For Other: Rancher Desktop, k3s, KinD, minikube, kubeadm, etc.
    + For Cloud: kops
- [Skaffold](https://skaffold.dev) `brew install skaffold`
- [Go](https://go.dev/dl/)
- [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) for Kubernetes overlays 
- [Buf](https://docs.buf.build/installation) and [Generate code](https://docs.buf.build/tour/generate-go-code) - For generate Go and Java code based on the prototype
- [golangci-lint](https://github.com/golangci/golangci-lint) `brew install golangci-lint` for Lint go code
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets) `brew install kubeseal` for create secrets that depends on specific cluster
- [mockery](https://github.com/vektra/mockery) `brew install mockery` for mock Go code
- [ko](https://github.com/google/ko) `brew install ko` for building Go-based image

#### Tips: Macbook with M1 architecture
Make sure that you set up the correct env variable:

```bash
export DOCKER_BUILDKIT=0
export DOCKER_DEFAULT_PLATFORM="linux/arm64"
```

## Installation

This workspace is build using dockerd (moby), Skaffold and Go modules. 

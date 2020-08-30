#   make              - default to 'build' target
#   make lint         - code analysis
#   make test         - run unit test (or plus integration test)
#   make clean        - clean up targets

# This repo's root import path (under GOPATH).
ROOT := github.com/dereknex/go-template-project

# Target binaries. You can build multiple binaries for a single project.
TARGETS := server

# It's necessary to set this because some environments don't link sh -> bash.
export SHELL := /bin/bash

# It's necessary to set the errexit flags for the bash shell.
export SHELLOPTS := errexit

# Project main package location (can be multiple ones).
CMD_DIR := ./cmd

# Project output directory.
OUTPUT_DIR := ./bin

# Current version of the project.
VERSION ?= $(shell git describe --tags --always --dirty)

# Available cpus for compiling
CPUS ?= $(shell /bin/bash hack/read_cpus_available.sh)

# Golang standard bin directory.
GOPATH ?= $(shell go env GOPATH)
BIN_DIR := $(GOPATH)/bin
GOLANGCI_LINT := $(BIN_DIR)/golangci-lint

# Default golang flags used in build and test
# -mod=vendor: force go to use the vendor files instead of using the `$GOPATH/pkg/mod`
# -p: the number of programs that can be run in parallel
# -count: run each test and benchmark 1 times. Set this flag to disable test cache
export GOFLAGS ?= -mod=vendor -p=$(CPUS) -count=1

#
# Define all targets. At least the following commands are required:
#

# All targets.
.PHONY: lint test build

build: build-local

# more info about `GOGC` env: https://github.com/golangci/golangci-lint#memory-usage-of-golangci-lint
lint: $(GOLANGCI_LINT)
	@$(GOLANGCI_LINT) run

$(GOLANGCI_LINT):
	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b $(BIN_DIR) v1.23.6

test:
	@go test -race -coverprofile=coverage.out ./...
	@go tool cover -func coverage.out | tail -n 1 | awk '{ print "Total coverage: " $$3 }'

build-local:
	@for target in $(TARGETS); do                                                      \
	  go build -v -o $(OUTPUT_DIR)/$${target}                                          \
	    -ldflags "-s -w -X $(ROOT)/pkg/version.VERSION=$(VERSION)                      \
	      -X $(ROOT)/pkg/version.REPOROOT=$(ROOT)"                                     \
	    $(CMD_DIR)/$${target};                                                         \
	done

.PHONY: clean
clean:
	@-rm -vrf ${OUTPUT_DIR}
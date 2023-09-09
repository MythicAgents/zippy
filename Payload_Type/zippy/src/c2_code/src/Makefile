export GO111MODULE=on

OUTPUT=../websocket-server.elf

LDFLAGS=-ldflags "-s -w -buildid="
GCFLAGS=-gcflags=all=-trimpath=$(shell echo ${HOME})
ASMFLAGS=-asmflags=all=-trimpath=$(shell echo ${HOME})

GOFILES=`go list ./...`
GOFILESNOTEST=`go list ./... | grep -v test`

all: lint linux

linux: lint
	env CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -trimpath ${LDFLAGS} ${GCFLAGS} ${ASMFLAGS} -o ${OUTPUT} ./cmd/server/main.go
	cp config.json ../

tidy:
	@go mod tidy

dep: tidy ## Get the dependencies
	@go get -v -d ./...
	@go get -u all

lint: ## Lint the files
	@go fmt ${GOFILES}
	@go vet ${GOFILESNOTEST}

clean:
	rm -f ${OUTPUT}

.PHONY: all linux tidy dep lint clean

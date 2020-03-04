FROM golang:latest AS build

RUN GO111MODULE=on go get -u github.com/google/go-containerregistry/cmd/crane \
 && cp ${GOPATH}/bin/crane /tmp/crane

RUN curl -sSL https://github.com/sclevine/yj/releases/download/v4.0.0/yj-linux > /tmp/yj \
 && chmod +x /tmp/yj

FROM golang:latest

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    docker-registry \
    git \
    jq \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /tmp/crane /usr/local/bin
COPY --from=build /tmp/yj /usr/local/bin

RUN mkdir -p /root/.docker \
 && echo "{}" > /root/.docker/config.json

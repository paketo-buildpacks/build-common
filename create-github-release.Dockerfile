FROM ubuntu:bionic AS build

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/sclevine/yj/releases/download/v5.0.0/yj-linux > /tmp/yj \
 && chmod +x /tmp/yj

FROM ubuntu:bionic

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    jq \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /tmp/yj /usr/local/bin/

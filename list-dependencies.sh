#!/usr/bin/env bash

set -eu

if [[ "$#" -lt 1 ]]; then
  printf "Usage: %s <IMAGE>\n" "$(basename "$0")"
  printf "\n"
  exit 1
fi

IMAGE="$1"
docker pull "${IMAGE}"

ID=$(docker create "${IMAGE}" noop)
PAYLOAD=()

for BUILDPACK in $(docker export "${ID}" | tar tf - "cnb/buildpacks/*/*/buildpack.toml"); do
  PAYLOAD+=( "$(docker cp "${ID}:${BUILDPACK}" - \
      | tar xOf - \
      | yj -tj \
      | jq '.metadata.dependencies[]? | { "name": .name, "version": .version, "uri": .uri }')" )
done

echo "${PAYLOAD[@]}" | jq --slurp 'sort_by(.name) | { "dependencies": . }'
docker container rm "${ID}" &> /dev/null


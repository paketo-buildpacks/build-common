#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

CONFIG=$(tar xOf "${ROOT}/source/image.tar" manifest.json | jq -r '.[].Config')
PAYLOAD=$(tar xOf "${ROOT}/source/image.tar" "$CONFIG" | jq -r '.config.Labels."io.buildpacks.buildpackage.metadata"')
PRIMARY=$(echo "${PAYLOAD}" | jq -r '.id')

DEPENDENCIES=()

for LAYER in $(tar tf "${ROOT}/source/image.tar" --wildcards "*.tar.gz"); do
  PAYLOAD=$(tar xOf "${ROOT}/source/image.tar" "${LAYER}" | tar xzOf - --absolute-names --wildcards "/cnb/buildpacks/*/*/buildpack.toml" | yj -tj)

  if [[ "${PRIMARY}" == "$(echo "${PAYLOAD}" | jq -r '.buildpack.id')" ]]; then
    NAME=$(echo "${PAYLOAD}" | jq -r '.buildpack.name')
    VERSION=$(echo "${PAYLOAD}" | jq -r '.buildpack.version')
  fi

  DEPENDENCIES+=( "$(echo "${PAYLOAD}" | jq -r '.metadata.dependencies[]?')" )
done

printf "%s %s" "${NAME}" "${VERSION}" > "${ROOT}"/release/name
printf "v%s" "${VERSION}" > "${ROOT}"/release/tag
printf "v%s" "${VERSION}" > "${ROOT}"/release/commitish

printf "## Dependencies\n| Name | Version |\n| :--- | :------ |\n%s\n"  \
  "$(echo "${DEPENDENCIES[@]}" | jq -r --slurp 'sort_by(.name) | .[] | "| \(.name) | \(.version) |"')" \
  > "${ROOT}"/release/body

echo "${DEPENDENCIES[@]}" | jq -r --slurp \
  --arg NAME "${NAME}" \
  --arg VERSION "${VERSION}" \
  'sort_by(.id) |  { "name": $NAME, "version": $VERSION, "dependencies": . }' \
  > "${ROOT}"/release/manifest.json

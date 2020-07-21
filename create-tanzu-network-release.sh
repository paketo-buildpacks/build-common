#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

DIGEST=$(cat "${ROOT}/source/digest")
CONFIG=$(tar xOf "${ROOT}"/source/image.tar manifest.json | jq -r '.[].Config')
PAYLOAD=$(tar xOf "${ROOT}"/source/image.tar "${CONFIG}" | jq -r '.config.Labels."io.buildpacks.buildpackage.metadata"')
PRIMARY=$(echo "${PAYLOAD}" | jq -r '.id')

DEPENDENCIES=()

for LAYER in $(tar tf "${ROOT}"/source/image.tar --wildcards "*.tar.gz"); do
  PAYLOAD=$(tar xOf "${ROOT}"/source/image.tar "${LAYER}" | tar xzOf - --absolute-names --wildcards "/cnb/buildpacks/*/*/buildpack.toml" | yj -tj)

  if [[ "${PRIMARY}" == "$(echo "${PAYLOAD}" | jq -r '.buildpack.id')" ]]; then
    VERSION=$(echo "${PAYLOAD}" | jq -r '.buildpack.version')
  fi

  DEPENDENCIES+=( "$(echo "${PAYLOAD}" | jq -r '.metadata.dependencies[]?')" )
done

echo "${DEPENDENCIES[@]}" | jq -r --slurp \
  --arg DIGEST "${DIGEST}" \
  --arg ID "${PRIMARY}" \
  --arg IMAGE_PATH "$(basename "${PRIMARY}"):${VERSION}" \
  --arg VERSION "${VERSION}" \
  'sort_by(.name) | [ .[] | "\(.name) \(.version)" ] | join("\n") |
  {
    "release": {
      "version": $VERSION,
      "release_type": "Minor Release",
      "eula_slug": "vmware_eula"
    },
    image_references: [{
      name: $ID,
      image_path: $IMAGE_PATH,
      digest: $DIGEST,
      description: .
    }]
  }
' \
> "${ROOT}"/release/metadata.json

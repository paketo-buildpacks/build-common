#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

CONFIG=$(tar xOf "${ROOT}"/source/image.tar manifest.json \
         | jq -r '.[].Config')
PRIMARY=$(tar xOf "${ROOT}"/source/image.tar "${CONFIG}" \
          | jq -r '.config.Labels."io.buildpacks.buildpackage.metadata" | fromjson | .id')

PAYLOAD='{}'
PAYLOAD=$(jq -n \
          --argjson payload "${PAYLOAD}" \
          --arg digest "$(cat "${ROOT}/source/digest")" \
          '$payload | .digest = $digest')

for LAYER in $(tar tf "${ROOT}"/source/image.tar --wildcards "*.tar.gz"); do
  BUILDPACK=$(tar xOf "${ROOT}"/source/image.tar "${LAYER}" \
              | tar xzOf - --absolute-names --wildcards "/cnb/buildpacks/*/*/buildpack.toml" \
              | yj -tj)

  if [[ "${PRIMARY}" == "$(jq -n -r --argjson buildpack "${BUILDPACK}" '$buildpack.buildpack.id')" ]]; then
    PAYLOAD=$(jq -n \
              --argjson payload "${PAYLOAD}" \
              --argjson buildpack "${BUILDPACK}" \
              '$payload | .primary = $buildpack')
  else
    PAYLOAD=$(jq -n \
              --argjson payload "${PAYLOAD}" \
              --argjson buildpack "${BUILDPACK}" \
              '$payload | .buildpacks += [ $buildpack ]')
  fi
done

printf "%s %s" \
       "$(jq -n -r --argjson payload "${PAYLOAD}" '$payload | .primary.buildpack.id')" \
       "$(jq -n -r --argjson payload "${PAYLOAD}" '$payload | .primary.buildpack.version')" \
       > "${ROOT}"/release/name
printf "v%s" \
       "$(jq -n -r --argjson payload "${PAYLOAD}" '$payload | .primary.buildpack.version')" \
       > "${ROOT}"/release/tag

jq -n -r --argjson payload "${PAYLOAD}" '$payload | [
  "## Digest",
  "`\(.digest)`",
  "",
  ( select(.primary.stacks) | [
    "## Stacks",
    ( .primary.stacks | sort_by(.id) | map("- `\(.id)`")),
    ""
  ]),
  ( select(.primary.metadata.dependencies) | [
    "## Dependencies",
    "Name | Version | SHA256",
    ":--- | :------ | :-----",
    ( .primary.metadata.dependencies | sort_by(.name) | map("\(.name) | `\(.version)` | `\(.sha256)`")),
    ""
  ]),
  ( select(.primary.order) | [
    "## Order Definitions",
    ( .primary.order | map([
      "ID | Version | Optional",
      ":- | :------ | :-------",
      ( .group | map("`\(.id)` | `\(.version)` | `\(.optional // false)`") ),
      ""
    ]))
  ]),
  ( select(.buildpacks) | [
    ( .buildpacks | sort_by(.buildpack.id) | map([
      "# `\(.buildpack.id) \(.buildpack.version)`",
      ( select(.stacks) | [
        "## Stacks",
        ( .stacks | sort_by(.id) | map("- `\(.id)`")),
        ""
      ]),
      ( select(.metadata.dependencies) | [
        "## Dependencies",
        "Name | Version | SHA256",
        ":--- | :------ | :-----",
        ( .metadata.dependencies | sort_by(.name) | map("\(.name) | `\(.version)` | `\(.sha256)`")),
        ""
      ]),
      ( select(.order) | [
        "## Order Definitions",
        ( .order | map([
          "ID | Version | Optional",
          ":- | :------ | :-------",
          ( .group | map("`\(.id)` | `\(.version)` | `\(.optional // false)`") ),
          ""
        ]))
      ])
    ]))
  ])
] | flatten | join("\n")' > "${ROOT}"/release/body

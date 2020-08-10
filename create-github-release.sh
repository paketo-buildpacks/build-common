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

# https://github.com/paketo-buildpacks/spring-boot/releases/tag/v2.6.0

jq -n -r \
  --argjson payload "${PAYLOAD}" \
  '$payload | "\(.primary.buildpack.name) \(.primary.buildpack.version)"' \
  > "${ROOT}"/release/name

jq -n -r \
  --argjson payload "${PAYLOAD}" \
  '$payload | "v\(.primary.buildpack.version)"' \
  > "${ROOT}"/release/tag

jq -n -r --argjson payload "${PAYLOAD}" '
def id(b):
  "**ID**: `\(b.buildpack.id)`"
;

def included_buildpackages(b): [
  "#### Included Buildpackages:",
  "Name | ID | Version",
  ":--- | :- | :------",
  ( b | sort_by(.buildpack.name | ascii_downcase) | map("\(.buildpack.name) | `\(.buildpack.id)` | `\(.buildpack.version)`") ),
  ""
];

def stacks(s): [
  "#### Supported Stacks:",
  ( s | sort_by(.id | ascii_downcase) | map("- `\(.id)`") ),
  ""
];

def default_dependency_versions(d): [
  "#### Default Dependency Versions:",
  "ID | Version",
  ":- | :------",
  ( d | to_entries | sort_by(.key | ascii_downcase) | map("`\(.key)` | `\(.value)`") ),
  ""
];

def dependencies(d): [
  "#### Dependencies:",
  "Name | Version | SHA256",
  ":--- | :------ | :-----",
  ( d | sort_by(.name | ascii_downcase) | map("\(.name) | `\(.version)` | `\(.sha256)`")),
  ""
];

def order_groupings(o): [
  "<details>",
  "<summary>Order Groupings</summary>",
  "",
  ( o | map([
    "ID | Version | Optional",
    ":- | :------ | :-------",
    ( .group | map([ "`\(.id)` | `\(.version)`", ( select(.optional) | "| `\(.optional)`" ) ] | join(" ")) ),
    ""
  ])),
  "</details>",
  ""
];

def primary_buildpack(p): [
  id(p.primary),
  "**Digest**: `\(p.digest)`",
  "",
  ( select(p.buildpacks) | included_buildpackages(p.buildpacks) ),
  ( select(p.primary.stacks) | stacks(p.primary.stacks) ),
  ( select(p.primary.metadata."default-versions") | default_dependency_versions(p.primary.metadata."default-versions") ),
  ( select(p.primary.metadata.dependencies) | dependencies(p.primary.metadata.dependencies) ),
  ( select(p.primary.order) | order_groupings(p.primary.order) ),
  ( select(p.buildpacks) | "---" ),
  ""
];

def nested_buildpack(b): [
  "<details>",
  "<summary>\(b.buildpack.name) \(b.buildpack.version)</summary>",
  "",
  id(b),
  "",
  ( select(b.stacks) | stacks(b.stacks) ),
  ( select(b.metadata."default-versions") | default_dependency_versions(b.metadata."default-versions") ),
  ( select(b.metadata.dependencies) | dependencies(b.metadata.dependencies) ),
  ( select(b.order) | order_groupings(b.order) ),
  "---",
  "",
  "</details>",
  ""
];

$payload | [
  primary_buildpack(.),
  ( select(.buildpacks) | [ .buildpacks | sort_by(.buildpack.name | ascii_downcase) | map(nested_buildpack(.)) ] )
] | flatten | join("\n")' > "${ROOT}/release/body"

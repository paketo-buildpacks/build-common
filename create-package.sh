#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

VERSION=$(cat "${ROOT}"/source/.git/ref)
VERSION=${VERSION:1}

printf "➜ Building Packager\n"
GO111MODULE=on go get -ldflags="-s -w" github.com/paketoio/libpak/cmd/package

printf "➜ Building Buildpack\n"
package \
  --cache-location "${ROOT}"/carton-cache \
  --destination "${ROOT}"/buildpack \
  --include-dependencies \
  --source "${ROOT}"/source \
  --version "${VERSION}"

printf "➜ Creating Package\n"
yj -tj < "${ROOT}"/buildpack/buildpack.toml | \
  jq "{
    buildpack: {
      uri: \"${ROOT}/buildpack\"
    },
    stacks: .stacks
  }" | yj -jt > "${ROOT}"/package.toml
pack \
  create-package \
  localhost:5000/package \
  -p "${ROOT}"/package.toml \
  --publish
crane pull localhost:5000/package "${ROOT}"/image/image.tar

printf "➜ Creating Image Tag %s\n" "${VERSION}"
printf "%s" "${VERSION}" > "${ROOT}"/image/tags

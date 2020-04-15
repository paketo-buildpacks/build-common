#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

VERSION=$(cat "${ROOT}"/source/.git/ref)
VERSION=${VERSION:1}

printf "➜ Building Packager\n"
GO111MODULE=on GOPRIVATE="*" go get -ldflags="-s -w" github.com/paketo-buildpacks/libpak/cmd/create-package

printf "➜ Building Buildpack\n"
create-package \
  --cache-location "${ROOT}"/carton-cache \
  --destination "${ROOT}"/buildpack \
  --include-dependencies \
  --source "${ROOT}"/source \
  --version "${VERSION}"

printf "➜ Creating Package\n"
printf '[buildpack]\nuri = "%s/buildpack"' "${ROOT}" > "${ROOT}"/package.toml
pack \
  package-buildpack \
  localhost:5000/package \
  --package-config "${ROOT}"/package.toml \
  --publish
crane pull localhost:5000/package "${ROOT}"/image/image.tar
printf "%s" "${VERSION}" > "${ROOT}"/image/tags

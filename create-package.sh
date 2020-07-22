#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

VERSION=$(cat "${ROOT}"/source/.git/short_ref)
VERSION=${VERSION:1}

printf "➜ Building Packager\n"
GO111MODULE=on GOPRIVATE="*" go get -ldflags="-s -w" github.com/paketo-buildpacks/libpak/cmd/create-package

printf "➜ Building Buildpack\n"
if [[ "${INCLUDE_DEPENDENCIES}" == "true" ]]; then
  create-package \
    --cache-location "${ROOT}"/carton-cache \
    --destination "${ROOT}"/buildpack \
    --include-dependencies \
    --source "${ROOT}"/source \
    --version "${VERSION}"
else
  create-package \
    --destination "${ROOT}"/buildpack \
    --source "${ROOT}"/source \
    --version "${VERSION}"
fi

printf "➜ Creating Package\n"
if [[ -e "${ROOT}"/source/package.toml ]]; then
  cat "${ROOT}"/source/package.toml > "${ROOT}"/package.toml
fi
printf '[buildpack]\nuri = "%s/buildpack"' "${ROOT}" >> "${ROOT}"/package.toml

pack \
  package-buildpack \
  "${ROOT}"/image/image.tar \
  --config "${ROOT}"/package.toml \
  --format file
printf "%s" "${VERSION}" > "${ROOT}"/image/tags

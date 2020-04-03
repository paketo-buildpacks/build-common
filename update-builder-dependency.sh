#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

printf "➜ Building Dependency Updater\n"
GO111MODULE=on GOPRIVATE="*" go get -ldflags='-s -w' github.com/paketo-buildpacks/libpak/cmd/update-builder-dependency

printf "➜ Updating Dependency\n"
update-builder-dependency \
  --builder-toml "${ROOT}"/source/builder.toml \
  --id "${DEPENDENCY}" \
  --version "$(cat "${ROOT}"/dependency/version)"

cd "${ROOT}"/source

git add buildpack.toml
git checkout -- .

git \
  -c user.name='Paketo Robot' \
  -c user.email='robot@paketo.io' \
  commit \
  --signoff \
  --message "Dependency Upgrade: ${DEPENDENCY} $(version)"

#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

sha256() {
  cat "${ROOT}"/dependency/sha256
}

uri() {
  cat "${ROOT}"/dependency/uri
}

version() {
  cat "${ROOT}"/dependency/version
}

# shellcheck disable=SC1090
[ -f "${ROOT}"/source/scripts/update-package-dependency.sh ] && source "${ROOT}"/source/scripts/update-package-dependency.sh

printf "➜ Building Dependency Updater\n"
GO111MODULE=on GOPRIVATE="*" go get -ldflags='-s -w' github.com/paketo-buildpacks/libpak/cmd/update-package-dependency

printf "➜ Updating Dependency\n"
update-package-dependency \
  --buildpack-toml "${ROOT}"/source/buildpack.toml \
  --id "${DEPENDENCY}" \
  --version-pattern "${VERSION_PATTERN}" \
  --version "$(version)" \
  --uri "$(uri)" \
  --sha256 "$(sha256)"

cd "${ROOT}"/source

git add buildpack.toml
git checkout -- .

git diff --cached --exit-code &> /dev/null && exit

git \
  -c user.name='Paketo Robot' \
  -c user.email='robot@paketo.io' \
  commit \
  --signoff \
  --message "Dependency Upgrade: ${DEPENDENCY} $(version)"

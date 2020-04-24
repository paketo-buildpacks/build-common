#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

VERSION=$(cat "${ROOT}"/dependency/version)

printf "➜ Building Dependency Updater\n"
GO111MODULE=on GOPRIVATE="*" go get -ldflags='-s -w' github.com/paketo-buildpacks/libpak/cmd/update-package-dependency

printf "➜ Updating Dependency\n"
if [[ -e "${ROOT}"/source/builder.toml ]]; then
  update-package-dependency \
    --builder-toml "${ROOT}"/source/builder.toml \
    --id "${DEPENDENCY}" \
    --version "${VERSION}"
fi
if [[ -e "${ROOT}"/source/package.toml ]]; then
  update-package-dependency \
    --package-toml "${ROOT}"/source/package.toml \
    --id "${DEPENDENCY}" \
    --version "${VERSION}"
fi

cd "${ROOT}"/source

[[ -e "${ROOT}"/source/builder.toml ]] && git add builder.toml
[[ -e "${ROOT}"/source/package.toml ]] && git add package.toml
git checkout -- .

git \
  -c user.name='Paketo Robot' \
  -c user.email='robot@paketo.io' \
  commit \
  --signoff \
  --message "Dependency Upgrade: ${DEPENDENCY} ${VERSION}"

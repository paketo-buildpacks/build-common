#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

VERSION=$(cat "${ROOT}"/source/.git/ref)
VERSION=${VERSION:1}

printf "➜ Creating Builder\n"
pack \
  create-builder \
  localhost:5000/builder \
  --config "${ROOT}"/source/builder.toml \
  --publish
crane pull localhost:5000/builder "${ROOT}"/image/image.tar
printf "%s" "${VERSION}" > "${ROOT}"/image/tags

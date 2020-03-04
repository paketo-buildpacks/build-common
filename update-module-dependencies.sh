#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$0")"/common.sh

cd "${ROOT}"/source

rm go.sum
GOPRIVATE="*" go get -u all
go mod tidy

git add go.mod go.sum
git checkout -- .

git diff --cached --exit-code || exit

git \
  -c user.name='Paketo Robot' \
  -c user.email='robot@paketo.io' \
  commit \
  --signoff \
  --message 'Go Module Update'

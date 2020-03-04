# shellcheck disable=SC2034
ROOT=$(realpath "$(dirname "${BASH_SOURCE[0]}")"/..)

if [[ -d "${ROOT}"/go-cache ]]; then
  export GOPATH="${ROOT}"/go-cache
fi

if [[ -d "${ROOT}"/pack ]]; then
  printf "➜ Expanding %s/pack/pack-*.tgz\n" "${ROOT}"
  tar xzvf "${ROOT}"/pack/pack-*.tgz -C "${ROOT}"/pack
  export PATH="${ROOT}"/pack:${PATH}
fi

if command -v docker-registry &> /dev/null; then
  printf "➜ Starting Registry\n"
  docker-registry serve /etc/docker/registry/config.yml &> /dev/null &
fi

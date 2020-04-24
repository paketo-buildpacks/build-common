ROOT=$(realpath "$(dirname "${BASH_SOURCE[0]}")"/..)

if [[ -d "${ROOT}"/go-cache ]]; then
  export GOPATH="${ROOT}"/go-cache
  export PATH="${ROOT}"/go-cache/bin:${PATH}
fi

if [[ -d "${ROOT}"/pack-cache ]]; then
  export PACK_HOME="${ROOT}"/pack-cache
fi

if [[ -d "${ROOT}"/pack ]]; then
  printf "➜ Expanding Pack\n"
  tar xzf "${ROOT}"/pack/pack-*.tgz -C "${ROOT}"/pack
  export PATH="${ROOT}"/pack:${PATH}
fi

if command -v docker-registry &> /dev/null; then
  printf "➜ Starting Registry\n"
  docker-registry serve /etc/docker/registry/config.yml &> /dev/null &
fi

if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
  printf "➜ Configuring Google Application Credentials\n"
  echo "${GOOGLE_APPLICATION_CREDENTIALS}" > "${ROOT}"/google-application-credentials.json
  export GOOGLE_APPLICATION_CREDENTIALS="${ROOT}"/google-application-credentials.json
fi


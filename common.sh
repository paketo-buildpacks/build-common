ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")"/..)"

if [[ -d $PWD/go-cache ]]; then
  export GOPATH=$PWD/go-cache
fi

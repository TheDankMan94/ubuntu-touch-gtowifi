#!/usr/bin/env bash
# Helper for the gtowifi Halium 9 build container.
#   ./build-env.sh image    build the container image (once)
#   ./build-env.sh shell    interactive shell in the container, /work = this folder
#   ./build-env.sh run CMD  run one command in the container
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG=halium9-builder
# Docker is run through sudo on purpose: membership of the 'docker' group is effectively
# passwordless root, so this account is NOT added to it. Run this script from a normal
# terminal (it will ask for your password); it cannot work inside the Claude app.
DOCKER="sudo docker"

case "${1:-}" in
  image)
    $DOCKER build -t "$IMG" \
      --build-arg HOST_UID="$(id -u)" --build-arg HOST_GID="$(id -g)" "$HERE" ;;
  shell)
    $DOCKER run --rm -it -v "$HERE":/work -w /work "$IMG" bash ;;
  run)
    shift
    $DOCKER run --rm -it -v "$HERE":/work -w /work "$IMG" bash -lc "$*" ;;
  *)
    echo "usage: $0 {image|shell|run CMD}" >&2; exit 1 ;;
esac

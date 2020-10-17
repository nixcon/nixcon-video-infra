#! /bin/sh

# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

set -ueo pipefail

ex_usage() {
    cat >&2 <<EOF
Usage: $0 hostname...
EOF
    exit 64 # EX_USAGE
}

if [ "$#" -eq 0 ]; then
    ex_usage
fi

host="$1"
shift

NIX_PATH="nixpkgs=${BASH_SOURCE[0]%/*}/../nixpkgs"
NIX_PATH="$NIX_PATH:nixos-config=${BASH_SOURCE[0]%/*}/../sys/$host.nix"
export NIX_PATH

fqdn="$(nix-instantiate --eval \
    -E 'with (import <nixpkgs/nixos> {}).config.networking;
        "${hostName}.${domain}"' | tr -d '"')"

nixos_rebuild="$(nix-build --no-out-link \
    -A config.system.build.nixos-rebuild \
    '<nixpkgs/nixos>')"

exec $nixos_rebuild/bin/nixos-rebuild switch \
    --target-host "root@$fqdn" "$@"

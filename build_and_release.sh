#!/usr/bin/env bash

set -euo pipefail
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable --quiet --no-modify-path -y
~/.cargo/bin/cargo install sccache
sccache_path=$HOME/.cargo/bin/sccache
set -e
( set -x; "$sccache_path" --help )
set +e
sccache_version=$( "$sccache_path" | awk '{print $1}' )
cp "$sccache_path" .
gzip sccache
archive_path=sccache.gz
sha256sum "$archive_path" >"$archive_path.sha256"
unix_timestamp_sec=$( date +%s )
tag="v$sccache_version-$unix_timestamp_sec"

hub release create "$tag" \
  -m "Release $tag" \
  -a "$archive_path" \
  -a "$archive_path.sha256" \
  -t "$tag"

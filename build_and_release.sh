#!/usr/bin/env bash

set -euo pipefail -x
cd "${BASH_SOURCE[0]%/*}"
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable --quiet --no-modify-path -y
~/.cargo/bin/cargo install sccache
sccache_path=$HOME/.cargo/bin/sccache
set -e
( set -x; "$sccache_path" --help )
set +e
sccache_version=$( "$sccache_path" --version | head -1 | awk '{print $2}' )
echo "sccache version: $sccache_version"

unix_timestamp_sec=$( date +%s )
tag="v$sccache_version-$unix_timestamp_sec"

archive_name=sccache-$tag.gz

mkdir -p build
rm -f build/*
cd build
cp "$sccache_path" .
gzip sccache
mv sccache.gz "$archive_name"

sha256sum "$archive_name" >"$archive_name.sha256"

echo "SHA256 sum:"
cat "$archive_name.sha256"
echo

echo "Using tag: $tag"

git_sha1=$( git rev-parse HEAD )
hub release create "$tag" \
  -m "Release $tag" \
  -a "$archive_name" \
  -a "$archive_name.sha256" \
  -t "$git_sha1"

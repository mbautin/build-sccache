#!/usr/bin/env bash

set -euo pipefail
if [[ -z ${GITHUB_TOKEN:-} ]]; then
  echo "GITHUB_TOKEN is not set" >&2
  exit 1
fi

set -x
cd "${BASH_SOURCE[0]%/*}"
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable --quiet --no-modify-path -y
export PATH=$HOME/.cargo/bin:$PATH

unix_timestamp_sec=$( date +%s )

build_dir=$PWD/build
sccache_tag=v0.2.15

rm -rf "$build_dir"
mkdir -p "$build_dir"
pushd "$build_dir"
git clone https://github.com/mozilla/sccache.git --depth 1 --branch "$sccache_tag"
pushd sccache
cargo build --release --features="dist-client dist-server"
popd
popd

cd "$build_dir"
tag="$sccache_tag-$unix_timestamp_sec"

dir_name=sccache-$tag
mkdir -p "$dir_name"
cp sccache/target/release/{sccache,sccache-dist} "./$dir_name"
archive_name="sccache-$tag.tar.gz"
tar cvzf "$archive_name" "$dir_name"

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

#!/usr/bin/env bash
# Copy libhangyeol_engine.a from cargo release/deps to release/ so
# `xcodebuild -create-xcframework` can see the top-level staticlib.
#
# cargo rustc --crate-type staticlib often lands the .a only under
#   engine/target/<triple>/<profile>/deps/
# while the XCFramework procedure expects
#   engine/target/<triple>/<profile>/libhangyeol_engine.a
#
# macOS XCFramework note: this script only copies files. Apple binaries
# must be built on a Mac (`aarch64-apple-darwin`). Linux CI cannot emit them.
set -euo pipefail

ENGINE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${HANGYEOL_STATICLIB_TARGET:-aarch64-apple-darwin}"
PROFILE="${HANGYEOL_STATICLIB_PROFILE:-release}"
REL="${ENGINE_DIR}/target/${TARGET}/${PROFILE}"
DEST="${REL}/libhangyeol_engine.a"
DEPS="${REL}/deps"

if [[ -f "${DEST}" ]]; then
  echo "already present: ${DEST}"
  exit 0
fi

if [[ ! -d "${DEPS}" ]]; then
  echo "missing ${DEPS}" >&2
  echo "Build first, e.g.:" >&2
  echo "  cargo rustc --release --target ${TARGET} --manifest-path engine/Cargo.toml -- --crate-type staticlib" >&2
  exit 1
fi

SRC=""
if [[ -f "${DEPS}/libhangyeol_engine.a" ]]; then
  SRC="${DEPS}/libhangyeol_engine.a"
else
  # hashed deps name, pick the newest
  SRC="$(ls -1t "${DEPS}"/libhangyeol_engine-*.a 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${SRC}" || ! -f "${SRC}" ]]; then
  echo "no libhangyeol_engine.a under ${DEPS}" >&2
  exit 1
fi

cp -f "${SRC}" "${DEST}"
echo "copied ${SRC} -> ${DEST}"

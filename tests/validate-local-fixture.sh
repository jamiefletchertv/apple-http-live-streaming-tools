#!/usr/bin/env sh
# Offline end-to-end test: segment a bundled clip with mediafilesegmenter,
# validate it with mediastreamvalidator 2.x through hls-validate, and prove the
# --exit-code.threshold gate passes a clean stream and fails a broken one.
set -eu

IMAGE="${IMAGE:-hlstools:local}"
OUTPUT_DIR="${OUTPUT_DIR:-tests/results}"
FIXTURE="${FIXTURE:-tests/fixtures/testsrc-6s.mp4}"

mkdir -p "${OUTPUT_DIR}"
work="$(cd "${OUTPUT_DIR}" && pwd)/local-fixture-$$"
mkdir -p "${work}"
cp "${FIXTURE}" "${work}/input.mp4"

# Run as the calling user so the host (e.g. a CI runner) can read what the
# tools write; mediafilesegmenter creates its output directory with mode 0700.
run() {
  docker run --rm --platform linux/amd64 \
    --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "${work}:/work" --workdir /work "${IMAGE}" "$@"
}

echo "== Segmenting fixture with mediafilesegmenter"
run mediafilesegmenter --target-duration 2 --file-base good input.mp4
test -s "${work}/good/prog_index.m3u8"

echo "== Validating clean stream (expect PASS)"
if ! run env HLS_VALIDATION_JSON=good-validation.json hls-validate good/prog_index.m3u8 \
  > "${work}/good-validation.log" 2>&1; then
  cat "${work}/good-validation.log"
  echo "Expected the clean fixture stream to pass validation." >&2
  exit 1
fi
cat "${work}/good-validation.log"
test -s "${work}/good-validation.json"
test -s "${work}/good-validation.md"
test -s "${work}/good-validation.html"

echo "== Validating broken stream (expect FAIL)"
run sh -c '
  set -eu
  mkdir -p broken
  cp good/* broken/
  last_segment="$(grep -v "^#" broken/prog_index.m3u8 | tail -n 1)"
  sed -i "s|^${last_segment}\$|missing-segment.m4s|" broken/prog_index.m3u8
  grep -q missing-segment.m4s broken/prog_index.m3u8
'
if run env HLS_VALIDATION_JSON=broken-validation.json hls-validate broken/prog_index.m3u8 \
  > "${work}/broken-validation.log" 2>&1; then
  cat "${work}/broken-validation.log"
  echo "Expected the validation gate to fail on a missing segment, but it passed." >&2
  exit 1
fi
cat "${work}/broken-validation.log"
test -s "${work}/broken-validation.md"
echo "Validation gate rejected the broken stream as expected."

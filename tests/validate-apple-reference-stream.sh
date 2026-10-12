#!/usr/bin/env sh
# Validate Apple's public bipbop reference stream with mediastreamvalidator 2.x.
# Needs network access. Fails when a finding reaches HLS_EXIT_THRESHOLD
# (default: critical, since Apple's sample streams are not tuned for every
# Must-level authoring rule set).
set -eu

IMAGE="${IMAGE:-hlstools:local}"
OUTPUT_DIR="${OUTPUT_DIR:-tests/results}"
STREAM_URL="${STREAM_URL:-https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8}"
VALIDATION_SECONDS="${VALIDATION_SECONDS:-20}"
HLS_EXIT_THRESHOLD="${HLS_EXIT_THRESHOLD:-critical}"
VALIDATION_LOG="${OUTPUT_DIR}/apple-bipbop-validation.log"
VALIDATION_EXIT_CODE="${OUTPUT_DIR}/apple-bipbop-validation.exit-code"

mkdir -p "${OUTPUT_DIR}"
results="$(cd "${OUTPUT_DIR}" && pwd)"

set +e
docker run --rm \
  --platform linux/amd64 \
  -v "${results}:/results" \
  -e HLS_VALIDATION_JSON=/results/apple-bipbop-validation.json \
  -e HLS_TIMEOUT="${VALIDATION_SECONDS}" \
  -e HLS_EXIT_THRESHOLD="${HLS_EXIT_THRESHOLD}" \
  "${IMAGE}" \
  hls-validate \
    --description "Apple bipbop HEVC reference stream smoke test" \
    "${STREAM_URL}" \
  > "${VALIDATION_LOG}" 2>&1
validator_status=$?
set -e

cat "${VALIDATION_LOG}"
printf '%s\n' "${validator_status}" > "${VALIDATION_EXIT_CODE}"

test -s "${OUTPUT_DIR}/apple-bipbop-validation.json"
test -s "${OUTPUT_DIR}/apple-bipbop-validation.md"
exit "${validator_status}"

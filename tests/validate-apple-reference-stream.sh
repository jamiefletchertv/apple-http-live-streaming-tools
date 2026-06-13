#!/usr/bin/env sh
set -eu

IMAGE="${IMAGE:-hlstools:local}"
OUTPUT_DIR="${OUTPUT_DIR:-tests/results}"
STREAM_URL="${STREAM_URL:-https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8}"
VALIDATION_SECONDS="${VALIDATION_SECONDS:-20}"
VALIDATION_JSON="${OUTPUT_DIR}/apple-bipbop-validation.json"
VALIDATION_LOG="${OUTPUT_DIR}/apple-bipbop-validation.log"
VALIDATION_EXIT_CODE="${OUTPUT_DIR}/apple-bipbop-validation.exit-code"

mkdir -p "${OUTPUT_DIR}"

set +e
docker run --rm \
  --platform linux/amd64 \
  -v "$(pwd)/${OUTPUT_DIR}:/results" \
  "${IMAGE}" \
  mediastreamvalidator \
    --timeout "${VALIDATION_SECONDS}" \
    --validation-data-path /results/apple-bipbop-validation.json \
    --description "Apple bipbop HEVC reference stream smoke test" \
    "${STREAM_URL}" \
  > "${VALIDATION_LOG}" 2>&1
validator_status=$?
set -e

cat "${VALIDATION_LOG}"
printf '%s\n' "${validator_status}" > "${VALIDATION_EXIT_CODE}"

test -s "${VALIDATION_JSON}"
test -s "${VALIDATION_LOG}"

if [ "${validator_status}" -ne 0 ]; then
  echo "mediastreamvalidator exited with status ${validator_status}; validation data was generated for review."
fi

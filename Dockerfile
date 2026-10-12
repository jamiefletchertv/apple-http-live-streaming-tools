# syntax=docker/dockerfile:1

# Apple HTTP Live Streaming Tools on Debian 13 (trixie), linux/amd64.
#   Validation: mediastreamvalidator 2.x + msvsummary  (packages/linux/hlstools_validation_*)
#   Authoring:  mediafilesegmenter, mediastreamsegmenter, ... (packages/linux/hlstools_authoring_*)
# Apple publishes these packages as Debian builds, so the image is Debian based.

ARG DEBIAN_IMAGE=debian:trixie-slim

FROM ${DEBIAN_IMAGE} AS unpack
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /pkgs
COPY packages/SHA256SUMS packages/SHA256SUMS
COPY packages/linux/ packages/linux/
# Verify the vendored archives, then follow Apple's installationReadMe.md:
# extract each .tgz and check the contained .tar against its .sha256 before untarring.
# hadolint ignore=DL3003
RUN set -eux; \
    grep 'packages/linux/' packages/SHA256SUMS | sha256sum --check --strict; \
    for tgz in packages/linux/*.tgz; do \
        name="$(basename "${tgz}" .tgz)"; \
        mkdir -p "archive/${name}" "out/${name}"; \
        tar -xzf "${tgz}" -C "archive/${name}"; \
        (cd "archive/${name}" && sha256sum --check --strict ./*.sha256); \
        tar -xf "archive/${name}"/*.tar -C "out/${name}"; \
    done; \
    mkdir -p /debs/deps /debs/tools; \
    # Both packages ship identical shared dependencies; take them from the validation package.
    cp out/hlstools_validation_*/Dependencies/Deploy/deb/*.deb /debs/deps/; \
    rm -f /debs/deps/corefoundation-release-5.9-*.deb; \
    cp out/*/hlstools-*-debian-*.deb /debs/tools/; \
    ls -l /debs/deps /debs/tools

FROM ${DEBIAN_IMAGE}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG HLS_VALIDATION_VERSION=2.0.284
ARG HLS_AUTHORING_VERSION=1.27.0

LABEL org.opencontainers.image.title="Apple HTTP Live Streaming Tools"
LABEL org.opencontainers.image.description="Debian amd64 image with Apple HLS tools: mediastreamvalidator ${HLS_VALIDATION_VERSION}, msvsummary and the ${HLS_AUTHORING_VERSION} authoring tools."
LABEL org.opencontainers.image.source="https://github.com/jamiefletchertv/apple-http-live-streaming-tools"
LABEL io.github.jamiefletchertv.hlstools.validation-version="${HLS_VALIDATION_VERSION}"
LABEL io.github.jamiefletchertv.hlstools.authoring-version="${HLS_AUTHORING_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=unpack /debs/ /tmp/debs/
COPY hlstools/ /usr/local/share/hlstools/
COPY scripts/hls-validate /usr/local/bin/hls-validate

# Install order matches Apple's deploy.sh DEPENDENCY_LIST. Apple's .debs do not
# declare their system library dependencies, so they are listed explicitly and
# checked with ldd below.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libatomic1 \
        libcurl4t64 \
        libicu76 \
        libxml2 \
        python3 \
        /tmp/debs/deps/libblocksruntime-release-*.deb \
        /tmp/debs/deps/libdispatch-release-*.deb \
        /tmp/debs/deps/libmd-release-*.deb \
        /tmp/debs/deps/libbsd-release-*.deb \
        /tmp/debs/deps/corefoundation-release-debian-*.deb \
        /tmp/debs/deps/IFS4L-release-*.deb \
        /tmp/debs/deps/calinuxbase-release-*.deb \
        /tmp/debs/deps/caulk-release-*.deb \
        /tmp/debs/deps/coreaudioservices-release-*.deb \
        /tmp/debs/deps/audiocodecs-hls-public-*.deb \
        /tmp/debs/deps/CoreGraphics-hls-*.deb \
        /tmp/debs/deps/ColorSync-release-*.deb \
        /tmp/debs/deps/CoreVideo-release-*.deb \
        /tmp/debs/tools/hlstools-validation-debian-*.deb \
        /tmp/debs/tools/hlstools-authoring-debian-*.deb; \
    printf '%s\n' /usr/lib64 /usr/local/lib64 > /etc/ld.so.conf.d/hlstools.conf; \
    ldconfig; \
    rm -rf /tmp/debs /var/lib/apt/lists/*; \
    missing="$(ldd /usr/local/bin/* /usr/lib64/*.so* /usr/local/lib*/*.so* 2>/dev/null | grep 'not found' | sort -u || true)"; \
    if [ -n "${missing}" ]; then echo "Missing shared libraries:"; echo "${missing}"; exit 1; fi; \
    for tool in mediastreamvalidator msvsummary id3taggenerator mediafilesegmenter \
                mediastreamsegmenter mediasubtitlesegmenter variantplaylistcreator hls-validate; do \
        command -v "${tool}"; \
    done; \
    mediastreamvalidator --version 2>&1 | grep -F "${HLS_VALIDATION_VERSION}"; \
    mediafilesegmenter --version 2>&1 | grep -F "${HLS_AUTHORING_VERSION}"; \
    test -f /usr/local/share/hlstools/ll-hls-origin-example.go; \
    test -f /usr/local/share/hlstools/lowLatencyHLS.php

WORKDIR /data
CMD ["/bin/bash"]

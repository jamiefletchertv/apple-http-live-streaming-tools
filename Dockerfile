FROM ubuntu:24.04

LABEL org.opencontainers.image.title="Apple HTTP Live Streaming Tools"
LABEL org.opencontainers.image.description="Ubuntu amd64 image containing Apple HTTP Live Streaming command-line tools."
LABEL org.opencontainers.image.source="https://github.com/jamiefletchertv/apple-http-live-streaming-tools"

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/hlstools

COPY installer-pkg/ ./installer-pkg/
COPY hlstools/ /usr/local/share/hlstools/

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libatomic1 \
        libcurl4t64 \
        libicu74 \
        ./installer-pkg/Dependencies/Deploy/deb/libblocksruntime-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/libdispatch-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/libmd-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/libbsd-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/corefoundation-release-ubuntu-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/IFS4L-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/calinuxbase-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/caulk-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/coreaudioservices-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/audiocodecs-hls-public-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/CoreGraphics-hls-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/ColorSync-release-*.deb \
        ./installer-pkg/Dependencies/Deploy/deb/CoreVideo-release-*.deb \
        ./installer-pkg/hlstools-ubuntu-release-*.deb; \
    printf '%s\n' /usr/lib64 /usr/local/lib64 > /etc/ld.so.conf.d/hlstools.conf; \
    ldconfig; \
    rm -rf /var/lib/apt/lists/*; \
    command -v id3taggenerator; \
    command -v mediafilesegmenter; \
    command -v mediastreamsegmenter; \
    command -v mediastreamvalidator; \
    command -v mediasubtitlesegmenter; \
    command -v variantplaylistcreator; \
    test -f /usr/local/share/hlstools/ll-hls-origin-example.go; \
    test -f /usr/local/share/hlstools/lowLatencyHLS.php

CMD ["/bin/bash"]

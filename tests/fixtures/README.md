# Test fixtures

`testsrc-6s.mp4` is a 6 second synthetic clip (320x180 H.264 test pattern, 1 kHz AAC tone, 2 second GOP) used by `tests/validate-local-fixture.sh`. It lets CI segment and validate a stream without any network access.

Regenerate it with:

```sh
ffmpeg -f lavfi -i testsrc2=size=320x180:rate=25 -f lavfi -i sine=frequency=1000:sample_rate=48000 \
  -t 6 -c:v libx264 -profile:v main -pix_fmt yuv420p -g 50 -keyint_min 50 -sc_threshold 0 -b:v 200k \
  -c:a aac -b:a 64k -movflags +faststart tests/fixtures/testsrc-6s.mp4
```

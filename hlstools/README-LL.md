#  Low-Latency HLS Tools

The script lowLatencyHLS.php uses PHP URLs to implement Blocking Playlist Reload (as described in the Internet-Draft draft-pantos-hls-rfc8216bis). This means you should increase the default number of PHP workers. When using lowLatencyHLS.php you should budget 4 PHP workers per client per Media Playlist. The following settings in php-fpm.d/www.conf are recommended for a small number of clients (i.e. 4, assuming separate audio and video playlists):

pm.max_children = 32
pm.start_servers = 8
pm.min_spare_servers = 8
pm.max_spare_servers = 16

## Command-line example

For a clean start, begin by running one instance of `mediastreamsegmenter` for each Variant Stream, writing the output into the Document root of the web server. For example, run the following three instances, each in its own Terminal window:

`% rm /Library/WebServer/Documents/2M/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9123 -s 16 -D -T -f /Library/WebServer/Documents/2M/`

`% rm /Library/WebServer/Documents/0.5M/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9125 -s 16 -D -T -f /Library/WebServer/Documents/0.5M/`

`% rm /Library/WebServer/Documents/4M/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9121 -s 16 -D -T -f /Library/WebServer/Documents/4M/`

Once these are running, start up a single instance of `tsrecompressor` to begin feeding them:

`% tsrecompressor -L 224.0.0.50:9123 -P 224.0.0.50:9125 -O 224.0.0.50:9121 -h -g -x -a`

Each instance of `mediastreamsegmenter` will continuously write a live Media Playlist file to `prog_index.m3u8`. But in order to implement the rules of Low-Latency HLS, the client must talk to an active component rather than reading `prog_index.m3u8` directly. So each variant subdirectory (2M/, 0.5M/, 4M/) should also contain a copy of `lowLatencyHLS.php`.

The corresponding multivariant playlist, `Library/WebServer/Documents/main.m3u8`, could then look like:

	#EXTM3U
	#EXT-X-INDEPENDENT-SEGMENTS

	#EXT-X-STREAM-INF:BANDWIDTH=2000000,CODECS="avc1.640028,mp4a.40.2"
	2M/lowLatencyHLS.php

	#EXT-X-STREAM-INF:BANDWIDTH=4000000,CODECS="avc1.640028,mp4a.40.2"
	4M/lowLatencyHLS.php

	#EXT-X-STREAM-INF:BANDWIDTH=500000,CODECS="avc1.640028,mp4a.40.2"
	0.5M/lowLatencyHLS.php

## fMP4 example

In order to generate a stream containing muxed fMP4 Segments, follow the Command-line example above but add --iso-fragmented to each `mediastreamsegmenter` invocation.

## Unmuxed fMP4 (CMAF) example

In order to generate a stream containing unmuxed fMP4 Segments, create another variant subdirectory audio/ with its own copy of `lowLatencyHLS.php` and start up four `mediastreamsegmenter` instances - one for each video bit rate and one for audio:

`% rm /Library/WebServer/Documents/2M/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9123 -s 16 -D -T --cmaf-fragmented --video-only -f /Library/WebServer/Documents/2M/`

`% rm /Library/WebServer/Documents/0.5M/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9125 -s 16 -D -T --cmaf-fragmented --video-only -f /Library/WebServer/Documents/0.5M/`

`% rm /Library/WebServer/Documents/4M/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9121 -s 16 -D -T --cmaf-fragmented --video-only -f /Library/WebServer/Documents/4M/`

`% rm /Library/WebServer/Documents/audio/[fpc]* ; mediastreamsegmenter -w 1002 -t 4 224.0.0.50:9121 -s 16 -D -T --cmaf-fragmented --audio-only -f /Library/WebServer/Documents/audio/`

Run `tsrecompressor` as above to produce media data. The audio variant subdirectory should also contain a copy of `lowLatencyHLS.php`.

Add audio to the multivariant playlist like this:

	#EXTM3U
	#EXT-X-INDEPENDENT-SEGMENTS

	#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="en",NAME="English",AUTOSELECT=YES,DEFAULT=YES,URI="audio/lowLatencyHLS.php"

	#EXT-X-STREAM-INF:BANDWIDTH=2000000,CODECS="avc1.640028,mp4a.40.2",AUDIO="aac"
	2M/lowLatencyHLS.php

	#EXT-X-STREAM-INF:BANDWIDTH=4000000,CODECS="avc1.640028,mp4a.40.2",AUDIO="aac"
	4M/lowLatencyHLS.php

	#EXT-X-STREAM-INF:BANDWIDTH=500000,CODECS="avc1.640028,mp4a.40.2",AUDIO="aac"
	0.5M/lowLatencyHLS.php

Copyright © 2019-2021,2024-2025 Apple Inc. All rights reserved.

Copyright © 2024-2026 Apple Inc. All Rights Reserved.

HTTP Live Streaming Tools
The HTTP Live Streaming (HLS) tools package installs command-line tools that are used for deployment and validation of HLS.

What's in this package
	* ID3TagGenerator
	* Media File Segmenter
	* Media Subtitle Segmenter
	* Media Stream Segmenter
	* Variant Playlist Creator
	* Media Stream Validator

Tool Overview

Media File Segmenter (mediafilesegmenter) divides a MOV, MP4, M4V, M4A, or MP3 file into media segments and creates an index file. It can also perform segment encryption. The index file and media segments can be deployed using almost any web server infrastructure for streaming to iOS, macOS, and tvOS. The Media File Segmenter only produces Video-on-Demand (VOD) streams.

Media Subtitle Segmenter (mediasubtitlesegmenter) converts subtitle tracks from a Quicktime file with tx3g-formatted subtitle tracks or SRT files into WebVTT and segments them for deployment using HLS. It will also take WebVTT files and segment them.

Media Stream Segmenter (mediastreamsegmenter) receives an MPEG-2 transport stream over a UDP network connection or from input stream on a local port and packages it for HLS. It writes a single live Media Playlist with its corresponding Media Segments (including Partial Segments in Low-Latency mode). It can also perform segment encryption. It writes its output to the local filesystem or a WebDAV endpoint. The live Media Playlist and Segments can be deployed using almost any web server infrastructure for streaming to iOS, macOS, and tvOS. The Media Stream Segmenter produces either live or VOD streams.

Variant Playlist Creator (variantplaylistcreator) works with Media File Segmenter to create a multivariant playlist from multiple VOD streams. Variant plists produced by Media File Segmenter, are passed to Variant Playlist Creator.

Media Stream Validator (mediastreamvalidator) simulates an HLS session and verifies that the index file and media segments conform to the HLS specification. It checks for several "best practices" to ensure reliable streaming. If any errors or problems are found, a detailed diagnostic report is displayed. Validation data can be written to a JSON file using --validation-data argument.

The deploy script will install these tools into:

	/usr/local/bin/id3taggenerator
	/usr/local/bin/mediafilesegmenter
	/usr/local/bin/mediastreamsegmenter
	/usr/local/bin/mediastreamvalidator
	/usr/local/bin/mediasubtitlesegmenter
	/usr/local/bin/variantplaylistcreator

Notice: The installer will replace previously installed versions of the files.

Please refer to the man-pages for detailed instructions for how to use the tools. The man-pages are invoked from the command-line as follows:

	man id3taggenerator
	man mediafilesegmenter
	man mediastreamsegmenter
	man mediastreamvalidator
	man mediasubtitlesegmenter
	man variantplaylistcreator


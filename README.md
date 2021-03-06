# TivoHMO

[![Build Status](https://travis-ci.org/wr0ngway/tivohmo.svg?branch=master)](https://travis-ci.org/wr0ngway/tivohmo)
[![Coverage Status](https://img.shields.io/coveralls/wr0ngway/tivohmo.svg)](https://coveralls.io/r/wr0ngway/tivohmo?branch=master)

This gem provides a Ruby SDK for authoring and running Tivo Home Media Option applications.

This is based on the excellent work done in the [pyTivo](http://pytivo.sourceforge.net/wiki/index.php/PyTivo) project, but written from the ground up in ruby with a full test suite and more separation of concerns between http server, data model, metadata provider and transcoder.

In order to reduce some of the code burden, this project only supports HD tivos, and since I only have a Roamio Pro, you can assume that is all it works on for now.  If you are an end user looking for something that just works, you will be better off with pyTivo as it supports more functionality across a wider range of devices.

A basic Directory/File implementation is provided to allow one to point the server at a directory tree containing videos and be able to browse those videos using the Tivo HMO browsing available in 'My Shows', with transcoding and transfer to the Tivo for viewing.

A Plex adapter is also available with similar functionality.  The transcoding only works if the TivoHMO server is on the same machine as Plex because it just reads from the underlying file that Plex references.  Future work will include the ability to use the Plex transcoder, or at the very least stream the video data from Plex to TivoHMO for transcoding before sending to tivo (less efficient).

This project only supports serving of video resources (for now) as that fills my need.

## Noteworthy features

 * Full control of runtime from command line or config file
 * Application for changing runtime settings of the server from the Tivo UI
 * Application to serve video to the Tivo from the Filesystem
 * Application to serve video to the Tivo from a Plex Media Server
 * Can serve video with on-the-fly hardcoded subtitles from srt files (embedded subs are also supported in plex app)

## Installation

Install ffmpeg 2.x:

    # On Mac OS X, use homebrew: http://brew.sh/
    brew install ffmpeg

Install the gem:

    $ gem install tivohmo

then install as a daemon with default configuration:

    $ tivohmo --install

Optionally edit the installed configuration file mentioned when the install command executes, and restart the daemon.

## Usage

Run the 'tivohmo' binary for usage:

    tivohmo --help


## Developing

Use the classes in TivoHMO::API to create your tree of data (Application -> Container(s) -> Items), then serve them with TivoHMO::Server.  See TivoHMO::Adapters::Filesystem for a sample implementation based on folders/files/ffmpeg


## Contributing

1. Fork it ( http://github.com/<my-github-username>/tivohmo/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

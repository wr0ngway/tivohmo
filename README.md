# TivoHMO

This gem provides a Ruby SDK for authoring and running Tivo Home Media Option applications.

This is based on the excellent work done in the [pyTivo](http://pytivo.sourceforge.net/wiki/index.php/PyTivo) project, but written from the ground up in ruby with a full test suite and more separation of concerns between http server, data model, metadata provider and transcoder.

In order to reduce some of the code burden, this project only supports HD tivos, and since I only have a Roamio Pro, you can assume that is all it works on for now.  If you are an end user looking for something that just works, you will be better off with pyTivo as it supports more functionality across a wider range of devices.

A basic Directory/File implementation is provided to allow one to point the server at a directory tree containing videos and be able to browse those videos using the Tivo HMO browsing available in 'My Shows', with transcoding and transfer to the Tivo for viewing.

A Plex adapter is also available with similar functionality.  The transcoding only works if the TivoHMO server is on the same machine as Plex because it just reads from the underlying file that Plex references.  Future work will include the ability to use the Plex transcoder, or at the very least stream the video data from Plex to TivoHMO for transcoding before sending to tivo (less efficient).

This project only supports serving of video resources (for now) as that fills my need.

## Installation

Install the gem:

    $ gem install tivohmo

Or to use this gem in your own ruby project, add this line to your application's Gemfile:

    gem 'tivohmo'

And then execute:

    $ bundle


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

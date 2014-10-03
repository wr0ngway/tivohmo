# TivoHMO

This gem provides a Ruby SDK for authoring and running Tivo Home Media Option applications.

This is based on the excellent work done in the [pyTivo](http://pytivo.sourceforge.net/wiki/index.php/PyTivo) project, but written from the ground up in ruby with a full test suite and more separation of concerns between http server, data model, metadata provider and transcoder.

A basic Directory/File implementation is provided to allow one to point the server at a directory tree containing videos and be able to browse those videos using the Tivo HMO browsing available in 'My Shows', with transcoding and transfer to the Tivo for viewing.

This project only supports serving of video resources (for now) as that fills my need.

Given that one can't beat the Tivo UI and Remote for watching video, the eventual goal is to integrate this project plus [tivohme](http://github.com/wr0ngway/tivohme) into a third, [tivohub](http://github.com/wr0ngway/tivohub), for multiplexing multiple sources (specifically [plex](https://plex.tv/)) into the multiple sinks available in the Tivo UI (hmo, hme, possibly opera apps).

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

Use the classes in TivoHMO::API to create your tree of data (Application -> Container(s) -> Items), then serve them with TivoHMO::Server.  See TivoHMO::BasicAdapter for a sample implementation based on folders/files/ffmpeg


## Contributing

1. Fork it ( http://github.com/<my-github-username>/tivohmo/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

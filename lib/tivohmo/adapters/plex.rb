require 'plex-ruby'
Plex.configure do |config|
  # TODO: figure out a way to make this instance specific rather than global for all plex apps
  token = TivoHMO::Config.instance.get(["adapters", "plex", "auth_token"])
  config.auth_token = token if token.present?
end

require_relative 'plex/movie'
require_relative 'plex/episode'
require_relative 'plex/group'
require_relative 'plex/season'
require_relative 'plex/show'
require_relative 'plex/category'
require_relative 'plex/qualified_category'
require_relative 'plex/section'
require_relative 'plex/application'
require_relative 'plex/metadata'
require_relative 'plex/transcoder'

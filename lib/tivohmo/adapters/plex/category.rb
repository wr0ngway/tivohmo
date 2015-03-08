require 'tivohmo/subtitles_util'
require 'iso-639'

module TivoHMO
  module Adapters
    module Plex

      class Category
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin
        include TivoHMO::Config::Mixin

        attr_reader :delegate
        attr_accessor :category_type, :category_value

        config_register(:enable_subtitles, true,
                        "For items that have subtitles, adds entries that will transcode with those subtitles hardcoded")

        def initialize(delegate, category_type, category_value=nil, presorted=false)
          # delegate is a Plex::Section
          @delegate = delegate

          super(delegate.key)
          self.presorted = presorted

          self.category_type = category_type
          self.category_value = category_value

          if category_value
            self.title = category_value[:title]
          else
            self.title = category_type.to_s.titleize
          end

          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.now
          @subtitles = config_get(:enable_subtitles)
        end

        alias_method :super_children, :children

        def child_count
          super_children.size
        end

        def children
          synchronize do

            # updated_at doesn't get updated for automatic updates, only
            # for updating from within plex media server web ui
            section_id = delegate.key.split('/').last
            new_delegate = delegate.library.section!(section_id)
            new_modified_at = new_delegate.updated_at.to_i
            if new_modified_at > modified_at.to_i
              logger.info "Plex section was updated, refreshing"
              @delegate = new_delegate
              self.modified_at = Time.at(new_modified_at)
              super.clear
            end

            if super.blank? || @subtitles != config_get(:enable_subtitles)
              super.clear
              @subtitles = config_get(:enable_subtitles)

              if category_value
                listing = delegate.send(category_type, category_value[:key])
              else
                listing = delegate.send(category_type)
              end

              Array(listing).each do |media|
                if media.is_a?(::Plex::Movie)
                  add_grouped(Movie, media)
                elsif media.is_a?(::Plex::Episode)
                  add_grouped(Episode, media)
                elsif media.is_a?(::Plex::Show)
                  add_child(Show.new(media))
                else
                  logger.error "Unknown type for #{media.class} in #{self.title}"
                end
              end
            end
          end

          super
        end

        def add_grouped(item_class, item_delegate)
          primary = item_class.new(item_delegate)

          if config_get(:enable_subtitles)
            subs = find_subtitles(item_delegate)

            if subs.size > 0
              group = Group.new(primary.identifier, primary.title)
              add_child(group)
              group.add_child(primary)
              subs.each {|s| group.add_child(item_class.new(item_delegate, s)) }
            else
              add_child(primary)
            end
          else
            add_child(primary)
          end
        end

        def find_subtitles(item_delegate)
          subs = []

          source_filename = CGI.unescape(item_delegate.medias.first.parts.first.file)

          # add in the file based subtitles
          subs.concat(SubtitlesUtil.instance.subtitles_for_media_file(source_filename))

          # add in the embedded subtitles
          item_delegate.medias.each do |media|
            media.parts.each do |part|
              prev_stream_count = 0
              part.streams.each do |stream|

                # stream.stream_type 3=subs, 1=video, 2=audio
                # stream.key.present? means file based srt
                # stream.index and no key, means embedded
                if stream.stream_type.to_i == 3
                  if stream.respond_to?(:index) && stream.index.present?
                    st = TivoHMO::API::Subtitle.new

                    lang_code = stream.respond_to?(:language_code) && stream.language_code || "??"
                    st.language_code = lang_code

                    iso_entry = ISO_639.find_by_code(lang_code.downcase)
                    if iso_entry
                      st.language = iso_entry.english_name
                    else
                      logger.warn "Subtitle stream has unknown language code: #{lang_code}"
                      st.language = "Unknown"
                    end

                    st.format = stream.codec
                    st.type = :embedded
                    # subtitle index should be the index amongst just the embedded subtitle streams
                    st.location = stream.index.to_i - prev_stream_count
                    subs << st
                  end
                end

                prev_stream_count += 1
              end
            end
          end

          subs
        end

      end

    end
  end
end

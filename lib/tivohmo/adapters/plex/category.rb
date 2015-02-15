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
                        "Add additional items for transcoding with hardcoded subtitles when present")

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

            if super.blank?

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

          item_delegate.medias.find do |media|
            media.parts.find do |part|
              part.streams.find do |stream|
                if stream.respond_to?(:codec) && stream.codec == 'srt'
                  if  stream.respond_to?(:language) && stream.respond_to?(:language_code)
                    lang = stream.language
                    code = stream.language_code

                    st = TivoHMO::API::Subtitle.new
                    st.language = lang
                    st.language_code = code

                    sub_file_glob = source_filename.chomp(File.extname(source_filename)) + ".*.srt"
                    sub_file = Dir[sub_file_glob].find do |f|
                      file_code = f.split('.')[-2].downcase
                      file_code == code || file_code.starts_with?(code) || code.starts_with?(file_code)
                    end

                    if sub_file
                      logger.debug "Using subtitles present at: #{sub_file}"
                      st.file = sub_file
                      subs << st
                    else
                      logger.debug "Could not find subtitles for: #{item_delegate.title}"
                    end
                  else
                    logger.warn "Subtitles not in plex naming standard for #{item_delegate.title}"
                  end
                end
              end
            end
          end

          subs
        end

      end

    end
  end
end

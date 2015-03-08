require 'active_support/core_ext/string/inflections'
require 'tivohmo/subtitles_util'

module TivoHMO
  module Adapters
    module Filesystem

      # A Container based on a filesystem folder
      class FolderContainer
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin
        include TivoHMO::Config::Mixin

        VIDEO_EXTENSIONS = %w[
          tivo mpg avi wmv mov flv f4v vob mp4 m4v mkv
          ts tp trp 3g2 3gp 3gp2 3gpp amv asf avs bik bix box bsf
          dat dif divx dmb dpg dv dvr-ms evo eye flc fli flx gvi ivf
          m1v m21 m2t m2ts m2v m2p m4e mjp mjpeg mod moov movie mp21
          mpe mpeg mpv mpv2 mqv mts mvb nsv nuv nut ogm qt rm rmvb
          rts scm smv ssm svi vdo vfw vid viv vivo vp6 vp7 vro webm
          wm wmd wtv yuv
        ]

        attr_reader :full_path

        attr_accessor :allowed_item_types,
                      :allowed_item_extensions

        def initialize(identifier)
          @full_path = File.expand_path(identifier)
          raise ArgumentError,
                "Must provide an existing directory: #{full_path}" unless File.directory?(full_path)

          super(full_path)

          self.allowed_item_types = %i[file dir]
          self.allowed_item_extensions = VIDEO_EXTENSIONS

          self.title = File.basename(self.identifier).titleize
          self.modified_at = File.mtime(self.identifier)
          self.created_at = File.ctime(self.identifier)

          @subtitles = config_get(:enable_subtitles)
        end

        def children
          synchronize do
            if super.blank? || @subtitles != config_get(:enable_subtitles)
              super.clear
              @subtitles = config_get(:enable_subtitles)

              items = Dir["#{self.full_path}/*"].group_by do |path|
                if allowed_container?(path)
                  :dir
                elsif allowed_item?(path)
                  :file
                else
                  :skipped
                end
              end

              Array(items[:dir]).each {|path| add_child(FolderContainer.new(path)) }
              Array(items[:file]).each {|path| add_grouped(path) }
              Array(items[:skipped]).each {|path| logger.debug "Ignoring: #{path}" } if logger.debug?

            end
          end

          super
        end

        protected

        def allowed_container?(path)
          File.directory?(path) && allowed_item_types.include?(:dir)
        end

        def allowed_item?(path)
          ext = File.extname(path).gsub(/^./, '')
          File.file?(path) &&
              allowed_item_types.include?(:file) &&
              allowed_item_extensions.include?(ext)
        end

        def add_grouped(path)
          primary = FileItem.new(path)

          if @subtitles
            subs = SubtitlesUtil.instance.subtitles_for_media_file(path)

            if subs.size > 0
              group = Group.new(primary.identifier, primary.title)
              add_child(group)
              group.add_child(primary)
              subs.each {|s| group.add_child(FileItem.new(path, s)) }
            else
              add_child(primary)
            end
          else
            add_child(primary)
          end
        end

      end

    end
  end
end

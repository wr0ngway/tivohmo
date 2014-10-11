require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Filesystem

      # A Container based on a filesystem folder
      class FolderContainer
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

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

          setup_change_listener
        end

        def children
          synchronize do
            if super.blank?
              folders = []
              files = []

              Dir["#{self.full_path}/*"].each do |path|
                if allowed_container?(path)
                  folders << FolderContainer.new(path)
                elsif allowed_item?(path)
                  files << FileItem.new(path)
                else
                  logger.debug "Ignoring: #{path}"
                end
              end

              (folders + files).each {|c| add_child(c) }
            end
          end

          super
        end

        protected

        def setup_change_listener
          logger.debug "Setting up change listener on #{identifier}"
          @listener = Listen.to(identifier, ignore: /\//) do |modified, added, removed|
            logger.debug "Detected filesystem change on #{identifier}"
            logger.debug "modified: #{modified}"
            logger.debug "added: #{added}"
            logger.debug "removed: #{removed}"

            # TODO: be more intelligent instead of just wiping children to cause the refresh
            self.refresh

            # cleanup - not strictly correct as this listener won't necessarily get triggered
            # if self is removed from the parent
            @listener.stop unless root.find(title_path)
            logger.debug "Completed filesystem refresh on #{identifier}"
          end
          @listener.start
        end

        def allowed_container?(path)
          File.directory?(path) && allowed_item_types.include?(:dir)
        end

        def allowed_item?(path)
          ext = File.extname(path).gsub(/^./, '')
          File.file?(path) &&
              allowed_item_types.include?(:file) &&
              allowed_item_extensions.include?(ext)
        end

      end

    end
  end
end

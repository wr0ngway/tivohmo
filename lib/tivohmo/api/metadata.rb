module TivoHMO
  module API

    # Metadata abstraction for containing and displaying supplemental info about an Item
    module Metadata
      extend ActiveSupport::Concern
      include GemLogger::LoggerSupport

      MPAA_RATINGS = {
          'G' => 1, 'PG' => 2, 'PG-13' => 3, 'PG13' => 3, 'R' => 4, 'X' => 5,
          'NC-17' => 6, 'NC17' => 6, 'NR' => 8, 'UNRATED' => 8, 'G1' => 1,
          'P2' => 2, 'P3' => 3, 'R4' => 4, 'X5' => 5, 'N6' => 6, 'N8' => 8
      }

      TV_RATINGS = {
          'TV-Y7' => 1, 'TV-Y' => 2, 'TV-G' => 3, 'TV-PG' => 4, 'TV-14' => 5,
          'TV-MA' => 6, 'TV-NR' => 7, 'TVY7' => 1, 'TVY' => 2, 'TVG' => 3,
          'TVPG' => 4, 'TV14' => 5, 'TVMA' => 6, 'TVNR' => 7, 'Y7' => 1,
          'Y' => 2, 'G' => 3, 'PG' => 4, '14' => 5, 'MA' => 6, 'NR' => 7,
          'UNRATED' => 7, 'X1' => 1, 'X2' => 2, 'X3' => 3, 'X4' => 4, 'X5' => 5,
          'X6' => 6, 'X7' => 7
      }

      attr_accessor :item,

                    :title,
                    :description,

                    :time, # Time
                    :start_time, # Time
                    :stop_time, # Time
                    :source_size, # int, bytes

                    :actual_showing,
                    :bookmark,
                    :recording_quality, # hash of :name, :value
                    :duration, # int, seconds

                    :showing_bits,
                    :part_count,
                    :part_index,

                    :actors,
                    :choreographers,
                    :directors,
                    :producers,
                    :executive_producers,
                    :writers,
                    :hosts,
                    :guest_stars,
                    :program_genres,

                    :original_air_date,
                    :movie_year,
                    :advisory,
                    :color_code, # hash of :name, :value
                    :show_type, # hash of :name, :value
                    :program_id,
                    :mpaa_rating, # hash of :name, :value
                    :star_rating, # hash of :name, :value
                    :tv_rating, # hash of :name, :value

                    :is_episode,
                    :episode_number,
                    :episode_title,

                    :series_genres,
                    :series_title,
                    :series_id,

                    :channel # hash of :major_number, :minor_number, :callsign


      def initialize(item)
        self.item = item
        self.duration = 0
        self.showing_bits = 4096
        self.is_episode = true
        self.recording_quality = {name: "HIGH", value: "75"}
        self.color_code = {name: 'COLOR', value: '4'}
        self.show_type = {name: 'SERIES', value: '5'}
        self.channel = {major_number: '0', minor_number: '0', callsign: ''}
      end

      def time
        @time ||= Time.now
      end

      def start_time
        @start_time ||= time
      end

      def stop_time
        @stop_time ||= time + duration
      end

      def source_size
        @source_size ||= estimate_source_size
      end

      def estimate_source_size
        # This is needed so that we can give tivo an estimate of transcoded size
        # so transfer doesn't abort half way through.  Using the max audio and
        # video bit rates for a max estimate
        opts = item.transcoder.transcoder_options
        vbr = (opts[:video_bitrate] || opts[:video_max_bitrate] || 30000) * 1000
        abr = (opts[:audio_bitrate] || 448) * 1000
        (self.duration * ((abr + vbr) * 1.02 / 8)).to_i
      end
    end

  end
end

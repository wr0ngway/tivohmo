module TivoHMO
  module API

    # Metadata abstraction for containing and displaying supplemental info about an Item
    module Metadata
      extend ActiveSupport::Concern
      include GemLogger::LoggerSupport

      attr_accessor :item,

                    :title,
                    :description,

                    :time,
                    :start_time,
                    :stop_time,
                    :actual_showing,
                    :bookmark,
                    :recording_quality, # hash of :name, :value
                    :duration,

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
        self.recording_quality = {name: "HIGH", value: "75"}
        self.time = Time.now
      end

    end

  end
end

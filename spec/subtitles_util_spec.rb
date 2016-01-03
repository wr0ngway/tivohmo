require_relative "spec_helper"
require 'tivohmo/subtitles_util'

describe TivoHMO::SubtitlesUtil do

  let(:subject) do
    TivoHMO::SubtitlesUtil.instance_variable_set(:@singleton__instance__, nil)
    TivoHMO::SubtitlesUtil.instance
  end

  describe "subtitles_for_media_file" do

    it "finds subtitles if present" do
      with_file_tree('1.avi', '1.en.srt', '2.avi', '3.avi', '3.en.srt', '3.fr.srt') do |dir|

        subs = subject.subtitles_for_media_file("#{dir}/1.avi")
        expect(subs.size).to eq(1)
        subs.all? {|s| expect(s).to be_instance_of(TivoHMO::API::Subtitle) }
        expect(subs.first.language_code).to eq('en')
        expect(subs.first.language).to eq('English')
        expect(subs.first.type).to eq(:file)
        expect(subs.first.format).to eq('srt')
        expect(subs.first.location).to eq("#{File.realdirpath(dir)}/1.en.srt")

        subs = subject.subtitles_for_media_file("#{dir}/2.avi")
        expect(subs.size).to eq(0)

        subs = subject.subtitles_for_media_file("#{dir}/3.avi")
        expect(subs.size).to eq(2)
        expect(subs.collect(&:language_code)).to match_array(['en', 'fr'])
      end
    end

  end

  describe "change listener" do

    it "watches for filesystem addition" do
      with_file_tree('1.avi') do |dir|

        subs = subject.subtitles_for_media_file("#{dir}/1.avi")
        expect(subs.size).to eq(0)

        sleep 0.1
        FileUtils.touch("#{dir}/1.en.srt")
        sleep 0.5

        subs = subject.subtitles_for_media_file("#{dir}/1.avi")
        expect(subs.size).to eq(1)
      end
    end

    it "watches for filesystem deletion" do
      with_file_tree('1.avi', '1.en.srt') do |dir|

        subs = subject.subtitles_for_media_file("#{dir}/1.avi")
        expect(subs.size).to eq(1)

        sleep 0.1
        FileUtils.rm("#{dir}/1.en.srt")
        sleep 0.5

        subs = subject.subtitles_for_media_file("#{dir}/1.avi")
        expect(subs.size).to eq(0)
      end
    end

  end

end

require_relative "spec_helper"

describe TivoHMO::Server do


  describe "#initialize" do

    it "should instantiate" do
      app = TivoHMO::API::Application.new
      expect(described_class.new(app)).to be_a Sinatra::Wrapper
    end

  end

end

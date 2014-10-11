require_relative "spec_helper"
require "tivohmo/cli"

describe TivoHMO::CLI do

  let(:app_name) { TestAPI::Application.name }
  let(:app_ident) { 'app_ident' }
  let(:minimal_args) do
    {
        application: app_name,
        identifier: app_ident
    }
  end
  let(:api_server) { TivoHMO::API::Server.new }
  let(:cli) { described_class.new("") }

  def argv(arg)
    if arg.is_a?(Hash)
      arg.collect {|k, v| ["--#{k}", v]}.flatten
    elsif arg.is_a?(Enumerable)
      arg.each_slice(2).collect {|k, v| ["--#{k}", v]}.flatten
    else
      raise 'bad arg'
    end
  end

  before(:each) do
    # stub out server so erroneous tests don't block indefinately
    allow(Rack::Handler.default).to receive(:run)
    allow(TivoHMO::API::Server).to receive(:new).and_return(api_server)
  end

  describe "--help" do

    it "produces help text under standard width" do
      lines = described_class.new("").help.split("\n")
      lines.each {|l| expect(l.size).to be <= 80 }
    end

  end

  describe "--debug" do

    it "defaults to info log level" do
      cli.run(argv(minimal_args))
      expect(Logging.logger.root.level).to eq(Logging::level_num(:info))
    end

    it "sets log level to debug" do
      cli.run(argv(minimal_args) + ['--debug'])
      expect(Logging.logger.root.level).to eq(Logging::level_num(:debug))
    end

  end

  describe "--logfile" do

    it "defaults to stdout" do
      cli.run(argv(minimal_args))
      expect(Logging.logger.root.appenders.collect(&:name)).to include('stdout')
    end

    it "sets log to file" do
      file = Tempfile.new('cli_spec').path
      cli.run(argv(minimal_args.merge(logfile: file)))
      expect(Logging.logger.root.appenders.collect(&:name)).to eq([file])
    end

  end

  describe "--configuration" do

    it "defaults to not loading config" do
      expect(YAML).to receive(:load_file).never
      cli.run(argv(minimal_args))
    end

    it "sets log level to debug" do
      expect(YAML).to receive(:load_file).with('foo.yml').and_return({})
      cli.run(argv(minimal_args.merge(configuration: 'foo.yml')))
    end

    it "can supply config" do
      expect(YAML).to receive(:load_file).with('foo.yml').and_return({'port' => 1234})
      expect(TivoHMO::Server).to receive(:start).with(api_server, 1234)
      cli.run(argv(minimal_args.merge(configuration: 'foo.yml')))
    end

    it "supplies config that can be overriden from cli" do
      expect(YAML).to receive(:load_file).with('foo.yml').and_return({'port' => 1234})
      expect(TivoHMO::Server).to receive(:start).with(api_server, 4321)
      cli.run(argv(minimal_args.merge(configuration: 'foo.yml', port: 4321)))
    end

  end

  describe "--port" do

    it "has a default port" do
      expect(TivoHMO::Server).to receive(:start).with(api_server, 9032)
      cli.run(argv(minimal_args))
    end

    it "provides a different port" do
      expect(TivoHMO::Server).to receive(:start).with(api_server, 1234)
      cli.run(argv(minimal_args.merge(port: 1234)))
    end

  end

  describe "--beacon" do

    it "works with defaults" do
      expect(TivoHMO::Beacon).to receive(:new).with(9032, **{})
      cli.run(argv(minimal_args))
    end

    it "can specify just a limit" do
      expect(TivoHMO::Beacon).to receive(:new).with(9032, **{limit: 5})
      cli.run(argv(minimal_args.merge(beacon: '5')))
    end

    it "can specify just an interval" do
      expect(TivoHMO::Beacon).to receive(:new).with(9032, **{interval: 5})
      cli.run(argv(minimal_args.merge(beacon: ':5')))
    end

    it "can specify both limit and interval" do
      expect(TivoHMO::Beacon).to receive(:new).with(9032, **{limit: 5, interval: 6})
      cli.run(argv(minimal_args.merge(beacon: '5:6')))
    end

  end

  describe "requirements" do

    it "requires one app" do
      expect {
        described_class.new("").run([])
      }.to raise_error(Clamp::UsageError,
                       'at least one application is required')
    end

    it "requires one init per app" do
      expect {
        described_class.new("").run(["-a", "foo"])
      }.to raise_error(Clamp::UsageError,
                       'an initializer is needed for each application')
    end

  end

  describe "basic usage" do

    before(:each) do
      expect(TivoHMO::Server).to receive(:start).with(api_server, 9032)
    end

    it "requires the adapter for the application" do
      require 'tivohmo/adapters/filesystem'
      expect(cli).to receive(:require).with('tivohmo/adapters/filesystem')
      cli.run(%w[-a TivoHMO::Adapters::Filesystem::Application -i .])
    end

    it "starts a server for the app" do
      cli.run(argv(minimal_args))
      expect(api_server.children.size).to eq(1)
      expect(api_server.children.first.class).to eq(TestAPI::Application)
      expect(api_server.children.first.title).to eq("#{app_ident} on #{api_server.title}")
    end

    it "starts a server with title" do
      cli.run(argv(minimal_args.merge(title: 'Foo')))
      expect(api_server.children.size).to eq(1)
      expect(api_server.children.first.class).to eq(TestAPI::Application)
      expect(api_server.children.first.title).to eq("Foo")
    end

    it "starts a server with alternate transcoder/metadata" do
      cli.run(argv(minimal_args.merge(
                       transcoder: TivoHMO::API::Transcoder.name,
                       metadata: TivoHMO::API::Metadata.name
                   )))

      default = TestAPI::Application.new('.')
      expect(default.metadata_class).to_not eq(TivoHMO::API::Metadata)
      expect(default.transcoder_class).to_not eq(TivoHMO::API::Transcoder)

      expect(api_server.children.size).to eq(1)
      expect(api_server.children.first.transcoder_class).to eq(TivoHMO::API::Transcoder)
      expect(api_server.children.first.metadata_class).to eq(TivoHMO::API::Metadata)
    end

    it "starts a server with multiple apps" do
      cli.run(argv(%W[
                       application #{TestAPI::Application.name}
                       identifier app_ident1
                       title App1
                       application #{TestAPI::Application.name}
                       identifier app_ident2
                       title App2
                   ]))

      expect(api_server.children.size).to eq(2)
      expect(api_server.children[0].identifier).to eq('app_ident1')
      expect(api_server.children[1].identifier).to eq('app_ident2')
      expect(api_server.children[0].title).to eq('App1')
      expect(api_server.children[1].title).to eq('App2')
    end

  end

end

require 'artifact_tools/client'

module MockSSH
  @start_params = {}

  def self.start(host, user, options)
    @start_params[:host] = host
    @start_params[:user] = user
    @start_params[:options] = options
  end

  class << self
    attr_reader :start_params
  end
end

describe ArtifactTools::Client do
  let(:fake_ssh) { MockSSH }
  before { stub_const('Net::SSH', fake_ssh) }

  describe '.new' do
    it "starts non-interactive session" do
      ArtifactTools::Client.new(config: {})
      expect(MockSSH.start_params[:options]).to have_key(:non_interactive)
      expect(MockSSH.start_params[:options][:non_interactive]).to be
    end

    it "uses passed user to start connection" do
      user = 'santa'
      ArtifactTools::Client.new(config: {}, user: user)
      expect(MockSSH.start_params[:user]).to eq user
    end

    context 'user in configuration' do
      let(:arg_user) { 'santa' }
      let(:config) { { 'user' => 'rudolf' } }
      it 'is send to server' do
        ArtifactTools::Client.new(config: config)
        expect(MockSSH.start_params[:user]).to eq config['user']
      end

      it 'is overriden by passed argument' do
        ArtifactTools::Client.new(config: config, user: arg_user)
        expect(MockSSH.start_params[:user]).to eq arg_user
      end
    end

    context "user in ARTIFACT_STORAGE_USER" do
      let(:env_user) { 'nick' }
      before { ENV.update('ARTIFACT_STORAGE_USER' => env_user) }

      it "is used if no user provided as argument" do
        ArtifactTools::Client.new(config: {})
        expect(MockSSH.start_params[:user]).to eq env_user
      end

      it "is overriden by user parameter" do
        user = 'santa'
        ArtifactTools::Client.new(config: {}, user: user)
        expect(MockSSH.start_params[:user]).to eq user
      end

      it "overrides user in config" do
        user = 'santa'
        ArtifactTools::Client.new(config: { 'user' => user })
        expect(user).not_to eq env_user
        expect(MockSSH.start_params[:user]).to eq env_user
      end
    end
  end
end

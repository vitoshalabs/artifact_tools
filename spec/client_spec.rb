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
  end
end

require 'artifact_tools/client'
require 'artifact_tools/hasher'

TEST_FILES = {
  'files/hello' => {
    'hash' => 'f572d396fae9206628714fb2ce00f72e94f2258f',
  },
}

class Session
  def initialize(host, user, options)
    @host = host
    @user = user
    @options = options
    @scp = MockSCP.new
  end

  attr_reader :scp
end

#TODO: make sure the remote path is correct
class MockSCP
  def download!(remote, local)
  end
end

module MockSSH
  @start_params = {}

  class << self
    attr_reader :start_params

    def start(host, user, options)
      @start_params[:host] = host
      @start_params[:user] = user
      @start_params[:options] = options
      Session.new(host, user, options)
    end
  end
end

class GetHashAlgo
  extend ArtifactTools::Hasher
end

def mock_file_hashes(files: TEST_FILES, expect_calls: false)
  hash = GetHashAlgo.send(:hash_algo)
  file_hash = Struct.new(:hexdigest)
  files.each do |file, props|
    allow(hash).to receive(:file).with(file).and_return(file_hash.new(props['hash']))
    expect(hash).to receive(:file).with(file).once if expect_calls
  end
end

describe ArtifactTools::Client do
  let(:fake_ssh) { MockSSH }
  before { stub_const('Net::SSH', fake_ssh) }
  before { mock_file_hashes }

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

  describe '.fetch' do
    subject { ArtifactTools::Client.new(config: config) }

    context 'with empty files configuration' do
      let(:config) { { 'files' => { } } }

      it "succeeds" do
        expect { subject.fetch }.not_to raise_error
      end
    end

    context 'with files in configuration' do
      let(:config) do
        { 'files' => TEST_FILES }
      end

      it "downloads the files" do
        expect { subject.fetch }.not_to raise_error
      end

      it "downloads and verifies the file" do
        mock_file_hashes(expect_calls: true)
        expect { subject.fetch(verify: true) }.not_to raise_error
      end

      it "downloads only specified file" do
        file, info = TEST_FILES.first
        mock_file_hashes(files: { file => info }, expect_calls: true)
        expect { subject.fetch(file: file, verify: true) }.not_to raise_error
      end

      it "downloads to specified destination" do
        file, info = TEST_FILES.first
        dest = 'there'
        mock_file_hashes(files: { "#{dest}/#{file}" => info }, expect_calls: true)
        expect { subject.fetch(file: file, verify: true, dest: dest) }.not_to raise_error
      end
    end
  end
end

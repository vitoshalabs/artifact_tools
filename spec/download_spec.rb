require 'artifact_tools/downloader'

describe ArtifactTools::Downloader do
  let(:config_file) { 'artifacts.yaml' }
  let(:config) { { 'server' => 'xxx', 'dir' => 'yyy', 'files' => TEST_FILES} }
  before { stub_const('ArtifactTools::Client', FakeClient) }
  before { stub_const('ArtifactTools::ConfigFile', FakeConfig) }
  before { FakeConfig.config = config }
  let(:new_params) { { config_file: config_file, dest_dir: 'ddir' } }

  describe '.new' do
    it "reads config file" do
      ArtifactTools::Downloader.new(**new_params)
      expect(FakeConfig.from_file_calls).to eq 1
    end

    it "passes parameters to Client.fetch" do
      ArtifactTools::Downloader.new(**new_params)
      expect(FakeClient.fetch_args.size).to eq 1
      expect(FakeClient.fetch_args.first[:dest]).to eq new_params[:dest_dir]
    end
  end
end

require 'artifact_tools/downloader'

describe ArtifactTools::Downloader do
  let(:config_file) { 'artifacts.yaml' }

  describe '.new' do
    let(:config) { { 'server' => 'xxx', 'dir' => 'yyy', 'files' => TEST_FILES} }
    before { stub_const('ArtifactTools::Client', FakeClient) }
    before { stub_const('ArtifactTools::ConfigFile', FakeConfig) }
    before { FakeConfig.config = config }
    let(:new_params) { { config_file: config_file, dest_dir: 'ddir' } }

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

  describe 'self.parse' do
    it "requires -c option" do
      args = ["-d" , "didi"]
      expect { ArtifactTools::Downloader.parse(args) }.to raise_error(OptionParser::MissingArgument)
    end

    it "parses all args" do
      args = ['-c', config_file, '-d', 'ddir', '-v', '-u', 'santa', '-m', 'hoho']
      hash = ArtifactTools::Downloader.parse(args)
      expect(hash[:config_file]).to eq config_file
      expect(hash[:match]).to eq Regexp.new('hoho')
      expect(hash[:verify]).to be
      expect(hash[:dest_dir]).to eq 'ddir'
    end
  end
end

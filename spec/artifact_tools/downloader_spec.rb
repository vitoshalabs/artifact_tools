# frozen_string_literal: true

require 'artifact_tools/downloader'

describe ArtifactTools::Downloader do
  let(:config_file) { 'artifacts.yaml' }

  describe '.new' do
    let(:config) { { 'server' => 'xxx', 'dir' => 'yyy', 'files' => TEST_FILES } }
    let(:new_params) { { config_file: config_file, dest_dir: 'ddir' } }

    before do
      stub_const('ArtifactTools::Client', FakeClient)
      stub_const('ArtifactTools::ConfigFile', FakeConfig)
      FakeConfig.config = config
    end

    it 'reads config file' do
      described_class.new(**new_params)
      expect(FakeConfig.from_file_calls).to eq 1
    end

    it 'passes parameters to Client.fetch' do
      described_class.new(**new_params)
      expect(FakeClient.fetch_args.size).to eq 1
      expect(FakeClient.fetch_args.first[:dest]).to eq new_params[:dest_dir]
    end
  end

  describe 'self.parse' do
    it 'requires -c option' do
      args = %w[-d didi]
      expect { described_class.parse(args) }.to raise_error(OptionParser::MissingArgument)
    end

    it 'parses all args' do
      args = ['-c', config_file, '-d', 'ddir', '-v', '-u', 'santa', '-m', 'hoho']
      hash = described_class.parse(args)
      expect(hash[:config_file]).to eq config_file
      expect(hash[:match]).to eq Regexp.new('hoho')
      expect(hash[:verify]).to be true
      expect(hash[:dest_dir]).to eq 'ddir'
    end
  end
end

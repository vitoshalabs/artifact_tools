# frozen_string_literal: true

require 'artifact_tools/config_file'
require 'helpers'

def keys_to_config(keys)
  keys.map { |k| [k, nil] }.to_h
end

describe ArtifactTools::ConfigFile do
  let(:correct_config) { { 'server' => 'server', 'dir' => '/hello', 'files' => nil } }

  describe '.from_file' do
    it 'returns ConfigFile' do
      file = 'hello/world'
      allow(YAML).to receive(:load_file).with('hello/world').and_return(correct_config)
      expect(described_class.from_file(file)).to be_a(described_class)
    end
  end

  describe '.new' do
    it "requires all parameters from #{described_class::REQUIRED_FIELDS.join(', ')}" do
      described_class::REQUIRED_FIELDS.each do |f|
        keys = described_class::REQUIRED_FIELDS - [f]
        config = keys_to_config(keys)
        expect { described_class.new(config: config) }.to raise_error(RuntimeError)
      end
    end

    it "allows 'files' with null" do
      config = correct_config.dup
      config['files'] = nil
      expect { described_class.new(config: config) }.not_to raise_error
    end

    it "allows 'files' with {}" do
      config = correct_config.dup
      config['files'] = {}
      expect { described_class.new(config: config) }.not_to raise_error
    end

    it "succeeds if #{described_class::REQUIRED_FIELDS} are present" do
      config = keys_to_config(described_class::REQUIRED_FIELDS)
      expect { described_class.new(config: config) }.not_to raise_error
    end
  end

  describe '#save' do
    it 'calls write to the provided file' do
      file = '/hello/world'
      expect(File).to receive(:write).with(file, correct_config.to_yaml).once
      described_class.new(config: correct_config).save(file)
    end
  end

  describe '#append_file' do
    subject(:config_file) { described_class.new(config: correct_config) }

    let(:file) { TEST_FILES.keys.first }

    before { mock_file_hashes }

    it 'adds requested file to config' do
      config_file.append_file(file: file)
      expect(config_file.config['files']).to have_key(file)
    end

    it 'computes hash for the file' do
      config_file.append_file(file: file)
      expect(config_file.config['files']).to have_key(file)
      expect(config_file.config['files'][file]).to have_key('hash')
      expect(config_file.config['files'][file]['hash']).to eq TEST_FILES[file]['hash']
    end

    it 'adds requested file to config as different key' do
      expected_key = 'there/file'
      config_file.append_file(file: file, store_path: expected_key)
      expect(config_file.config['files']).to have_key(expected_key)
    end

    it 'overrides hash if provided' do
      hash = 'something'
      config_file.append_file(file: file, hash: hash)
      expect(config_file.config['files']).to have_key(file)
      expect(config_file.config['files'][file]['hash']).to eq hash
    end

    it 'stores arbitrary property if provided' do
    end
  end
end

require 'artifact_tools/config_file'
require 'helpers'

def keys_to_config(keys)
  keys.map { |k| [k, nil] }.to_h
end

describe ArtifactTools::ConfigFile do
  let(:correct_config) { { 'server' => 'server', 'dir' => '/hello', 'files' => {} } }
  describe '.from_file' do
    it "returns ConfigFile" do
      file = 'hello/world'
      allow(YAML).to receive(:load_file).with('hello/world').and_return(correct_config)
      expect(ArtifactTools::ConfigFile.from_file(file)).to be_a(ArtifactTools::ConfigFile)
    end
  end

  describe '.new' do
    it "requires all parameters from #{ArtifactTools::ConfigFile::REQUIRED_FIELDS.join(", ")}" do
      ArtifactTools::ConfigFile::REQUIRED_FIELDS.each do |f|
        keys = ArtifactTools::ConfigFile::REQUIRED_FIELDS - [f]
        config = keys_to_config(keys)
        expect { ArtifactTools::ConfigFile.new(config: config) }.to raise_error(RuntimeError)
      end
    end

    it "succeeds if #{ArtifactTools::ConfigFile::REQUIRED_FIELDS} are present" do
      config = keys_to_config(ArtifactTools::ConfigFile::REQUIRED_FIELDS)
      expect { ArtifactTools::ConfigFile.new(config: config) }.not_to raise_error
    end
  end

  describe '#save' do
    it "calls write to the provided file" do
      file = '/hello/world'
      expect(File).to receive(:write).with(file, correct_config.to_yaml).once
      ArtifactTools::ConfigFile.new(config: correct_config).save(file)
    end
  end

  describe '#append_file' do
    subject { ArtifactTools::ConfigFile.new(config: correct_config) }
    let(:file) { TEST_FILES.keys.first }
    before { mock_file_hashes }

    it "adds requested file to config" do
      subject.append_file(file: file)
      expect(subject.config['files']).to have_key(file)
    end

    it "computes hash for the file" do
      subject.append_file(file: file)
      expect(subject.config['files']).to have_key(file)
      expect(subject.config['files'][file]).to have_key('hash')
      expect(subject.config['files'][file]['hash']).to eq TEST_FILES[file]['hash']
    end

    it "adds requested file to config as different key" do
      expected_key = 'there/file'
      subject.append_file(file: file, store_path: expected_key)
      expect(subject.config['files']).to have_key(expected_key)
    end

    it "overrides hash if provided" do
      hash = 'something'
      subject.append_file(file: file, hash: hash)
      expect(subject.config['files']).to have_key(file)
      expect(subject.config['files'][file]['hash']).to eq hash
    end

    it 'stores arbitrary property if provided' do
    end
  end
end

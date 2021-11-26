# frozen_string_literal: true

require 'artifact_tools/hasher'
require 'tempfile'

def sha1sum(path)
  `sha1sum #{path}`.split[0]
end

def random_bytes
  if Random.respond_to?(:bytes)
    lambda { |x| Random.bytes(x) }
  else
    lambda { |x| Random.new.bytes(x) }
  end
end

def fill_file_random_data(file)
  bytes = random_bytes[Random.rand(1000..10_000)]
  file.write(bytes)
end

class Hash
  extend ArtifactTools::Hasher
end

describe ArtifactTools::Hasher do
  describe 'file_hash' do
    let(:file) { Tempfile.new('hasher') }

    before { fill_file_random_data(file) }

    after { file.unlink }

    it 'returns correct hash' do
      expect(Hash.file_hash(file.path)).to eq sha1sum(file.path)
    end
  end
end

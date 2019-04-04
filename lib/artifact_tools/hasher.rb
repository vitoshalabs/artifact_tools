module ArtifactStorage
  module Hasher
    def file_hash(path)
      hash_algo.file(path).hexdigest
    end

    private

    def hash_algo
      # TODO: decide on used algorithm
      Digest::SHA1
    end
  end
end

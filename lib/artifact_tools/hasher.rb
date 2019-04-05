module ArtifactTools
  module Hasher
    # Calculate hash of a file
    #
    # @param path [String] Path to file to hash.
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

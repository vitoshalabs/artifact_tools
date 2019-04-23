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

  def exec!(cmd)
  end

  attr_reader :scp
end

class MockSCP
  attr_reader :download_last_remote, :upload_last_remote

  def download!(remote, local)
    @download_last_remote = remote
  end

  def upload!(local, remote)
    @upload_last_remote = remote
  end
end

module MockSSH
  @start_params = {}

  class << self
    attr_reader :start_params, :session

    def start(host, user, options)
      @start_params[:host] = host
      @start_params[:user] = user
      @start_params[:options] = options
      @session = Session.new(host, user, options)
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
    props = { 'hash' => nil } if props.nil?
    allow(hash).to receive(:file).with(file).and_return(file_hash.new(props['hash']))
    expect(hash).to receive(:file).with(file).once if expect_calls
  end
end

class FakeConfig
  def self.config=(config)
    @@from_file_calls = 0
    @@config = config
  end

  def self.object
    @@object
  end

  def self.from_file(file)
    @@from_file_calls += 1
    @@object = self.new(@@config)
  end

  def initialize(config)
    @config = config
    @num_save = 0
  end

  def save(config_file)
    @num_save += 1
  end

  def append_file(file:, store_path:nil, **opts)
    store_path = file unless store_path
    @config['files'][store_path] = opts
    @config['files'][store_path]['hash'] = '111'
  end

  attr_reader :config, :num_save

  def self.from_file_calls
    @@from_file_calls
  end
end

class FakeClient
  def initialize(config:, user:nil)
    @@put_files = []
    @config = config
  end

  def put(file:)
    @@put_files << file
  end

  def self.put_files
    @@put_files
  end
end


# frozen_string_literal: true

TEST_FILES = {
  'files/hello' => {
    'hash' => 'f572d396fae9206628714fb2ce00f72e94f2258f'
  },
  'whats/up/there/long' => {
    'hash' => 'ecea77f26d28c9f42b6e3f6916fa67e6d2de568f'
  }
}.freeze

class Session
  def initialize(host, user, options)
    @host = host
    @user = user
    @options = options
    @scp = MockSCP.new
  end

  def exec!(cmd); end

  attr_reader :scp
end

class MockSCP
  attr_reader :download_last_remote, :upload_last_remote

  def download!(remote, local) # rubocop:disable Lint/UnusedMethodArgument
    @download_last_remote = remote
  end

  def upload!(local, remote) # rubocop:disable Lint/UnusedMethodArgument
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

def mock_local_file(files: TEST_FILES, expect_calls: false)
  mock_file_hashes(files: files, expect_calls: expect_calls)
  files.each do |file, _|
    allow(File).to receive(:exist?).with(file).and_return(true)
  end
end

class FakeConfig
  def self.config=(config)
    @from_file_calls = 0
    @config = config
  end

  def self.from_file(*)
    @from_file_calls += 1
    @object = new(@config)
  end

  def initialize(config)
    @config = config
    @num_save = 0
  end

  def save(config_file) # rubocop:disable Lint/UnusedMethodArgument
    @num_save += 1
  end

  def append_file(file:, store_path: nil, **opts)
    store_path ||= file
    @config['files'][store_path] = opts
    @config['files'][store_path]['hash'] = '111'
  end

  attr_reader :config, :num_save

  class << self
    attr_reader :from_file_calls, :object
  end
end

class FakeClient
  def initialize(config:, user: nil) # rubocop:disable Lint/UnusedMethodArgument
    self.class.put_files = []
    self.class.fetch_args = []
    @config = config
  end

  def put(file:)
    self.class.put_files << file
  end

  def fetch(**opts)
    self.class.fetch_args << opts
  end

  class << self
    attr_accessor :fetch_args, :put_files
  end
end

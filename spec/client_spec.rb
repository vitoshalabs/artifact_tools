require 'artifact_tools/client'
require 'artifact_tools/hasher'
require 'helpers'

describe ArtifactTools::Client do
  let(:fake_ssh) { MockSSH }
  before { stub_const('Net::SSH', fake_ssh) }
  before { mock_file_hashes }

  describe '.new' do
    it "starts non-interactive session" do
      ArtifactTools::Client.new(config: {})
      expect(MockSSH.start_params[:options]).to have_key(:non_interactive)
      expect(MockSSH.start_params[:options][:non_interactive]).to be
    end

    it "uses passed user to start connection" do
      user = 'santa'
      ArtifactTools::Client.new(config: {}, user: user)
      expect(MockSSH.start_params[:user]).to eq user
    end

    context 'user in configuration' do
      let(:arg_user) { 'santa' }
      let(:config) { { 'user' => 'rudolf' } }
      it 'is send to server' do
        ArtifactTools::Client.new(config: config)
        expect(MockSSH.start_params[:user]).to eq config['user']
      end

      it 'is overriden by passed argument' do
        ArtifactTools::Client.new(config: config, user: arg_user)
        expect(MockSSH.start_params[:user]).to eq arg_user
      end
    end

    context "user in ARTIFACT_STORAGE_USER" do
      let(:env_user) { 'nick' }
      before { ENV.update('ARTIFACT_STORAGE_USER' => env_user) }

      it "is used if no user provided as argument" do
        ArtifactTools::Client.new(config: {})
        expect(MockSSH.start_params[:user]).to eq env_user
      end

      it "is overriden by user parameter" do
        user = 'santa'
        ArtifactTools::Client.new(config: {}, user: user)
        expect(MockSSH.start_params[:user]).to eq user
      end

      it "overrides user in config" do
        user = 'santa'
        ArtifactTools::Client.new(config: { 'user' => user })
        expect(user).not_to eq env_user
        expect(MockSSH.start_params[:user]).to eq env_user
      end
    end
  end

  describe '.fetch' do
    subject { ArtifactTools::Client.new(config: config) }

    context 'with empty files configuration' do
      let(:config) { { 'files' => { } } }

      it "succeeds" do
        expect { subject.fetch }.not_to raise_error
      end
    end

    context 'with files in configuration' do
      let(:config) do
        { 'files' => TEST_FILES }
      end

      it "downloads the files" do
        expect { subject.fetch }.not_to raise_error
      end

      it "downloads and verifies the file" do
        mock_file_hashes(expect_calls: true)
        expect { subject.fetch(verify: true) }.not_to raise_error
      end

      it "downloads only specified file" do
        file, info = TEST_FILES.first
        mock_file_hashes(files: { file => info }, expect_calls: true)
        expect { subject.fetch(file: file, verify: true) }.not_to raise_error
      end

      it "downloads to specified destination" do
        file, info = TEST_FILES.first
        dest = 'there'
        mock_file_hashes(files: { "#{dest}/#{file}" => info }, expect_calls: true)
        expect { subject.fetch(file: file, verify: true, dest: dest) }.not_to raise_error
      end
    end

    context 'uses correct remote path' do
      let(:remote_dir) { '/hello/there' }
      let(:config) do
        {
          'dir' => remote_dir,
          'files' => TEST_FILES,
        }
      end

      it do
        mock_file_hashes(expect_calls: true)
        expect { subject.fetch(verify: true) }.not_to raise_error
        expect(MockSSH.session.scp.download_last_remote).to start_with(remote_dir)
      end
    end
  end

  describe '.put' do
    subject { ArtifactTools::Client.new(config: config) }
    let(:file) { TEST_FILES.keys.first }

    context 'with empty files configuration' do
      let(:config) { { 'files' => { } } }

      it "succeeds" do
        expect { subject.put(file: file)}.not_to raise_error
      end
    end

    context 'with files in configuration' do
      let(:config) { { 'files' => TEST_FILES } }

      it "uploads the file" do
        expect { subject.put(file: file) }.not_to raise_error
      end
    end

    context 'uses correct remote path' do
      let(:remote_dir) { '/hello/there' }
      let(:config) { { 'dir' => remote_dir } }

      it do
        expect { subject.put(file:TEST_FILES.keys.first) }.not_to raise_error
        expect(MockSSH.session.scp.upload_last_remote).to start_with(remote_dir)
      end
    end
  end
end

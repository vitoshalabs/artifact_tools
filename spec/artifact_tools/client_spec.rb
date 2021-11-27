# frozen_string_literal: true

require 'artifact_tools/client'
require 'artifact_tools/hasher'
require 'helpers'

describe ArtifactTools::Client do
  let(:fake_ssh) { MockSSH }

  before do
    stub_const('Net::SSH', fake_ssh)
    mock_file_hashes
  end

  describe '.new' do
    it 'starts non-interactive session' do
      described_class.new(config: {})
      expect(MockSSH.start_params[:options]).to have_key(:non_interactive)
      expect(MockSSH.start_params[:options][:non_interactive]).to be true
    end

    it 'uses passed user to start connection' do
      user = 'santa'
      described_class.new(config: {}, user: user)
      expect(MockSSH.start_params[:user]).to eq user
    end

    context 'when user in configuration' do
      let(:arg_user) { 'santa' }
      let(:config) { { 'user' => 'rudolf' } }

      it 'is send to server' do
        described_class.new(config: config)
        expect(MockSSH.start_params[:user]).to eq config['user']
      end

      it 'is overriden by passed argument' do
        described_class.new(config: config, user: arg_user)
        expect(MockSSH.start_params[:user]).to eq arg_user
      end
    end

    context 'when user in ARTIFACT_STORAGE_USER' do
      let(:env_user) { 'nick' }

      before { ENV.update('ARTIFACT_STORAGE_USER' => env_user) }

      it 'is used if no user provided as argument' do
        described_class.new(config: {})
        expect(MockSSH.start_params[:user]).to eq env_user
      end

      it 'is overriden by user parameter' do
        user = 'santa'
        described_class.new(config: {}, user: user)
        expect(MockSSH.start_params[:user]).to eq user
      end

      it 'overrides user in config' do
        user = 'santa'
        described_class.new(config: { 'user' => user })
        expect(user).not_to eq env_user
        expect(MockSSH.start_params[:user]).to eq env_user
      end
    end
  end

  describe '.fetch' do
    subject(:client) { described_class.new(config: config) }

    context 'with empty files configuration' do
      let(:config) { { 'files' => {} } }

      it 'succeeds' do
        expect { client.fetch }.not_to raise_error
      end
    end

    context 'with files in configuration' do
      let(:config) do
        { 'files' => TEST_FILES }
      end

      it 'downloads the files' do
        expect { client.fetch }.not_to raise_error
      end

      it 'downloads and verifies the file' do
        hash = mock_file_hashes
        expect { client.fetch(verify: true) }.not_to raise_error
        TEST_FILES.each { |file, _p| expect(hash).to have_received(:file).with(file).once }
      end

      it 'downloads only specified file' do
        file, info = TEST_FILES.first
        hash = mock_file_hashes(files: { file => info })
        expect { client.fetch(file: file, verify: true) }.not_to raise_error
        expect(hash).to have_received(:file).with(file).once
      end

      it 'downloads to specified destination' do
        file, info = TEST_FILES.first
        dest = 'there'
        hash = mock_file_hashes(files: { "#{dest}/#{file}" => info })
        expect { client.fetch(file: file, verify: true, dest: dest) }.not_to raise_error
        expect(hash).to have_received(:file).with("#{dest}/#{file}").once
      end
    end

    context 'when files already downloaded' do
      let(:files1) { { 'filename' => { 'hash' => '111111111' } } }
      let(:files2) { { 'filename' => { 'hash' => '222222222' } } }
      let(:config) { { 'files' => files1 } }

      it "doesn't download the file if already present with correct hash" do
        hash = mock_local_file(files: files1)
        expect { client.fetch(force: false) }.not_to raise_error
        files1.each { |file| expect(hash).to have_received(:file).with(file[0]).once }
        expect(MockSSH.session.scp.download_last_remote).to be_nil
      end

      it 'downloads the file if already present if forced' do
        mock_local_file(files: files1)
        expect { client.fetch(force: true) }.not_to raise_error
        expect(MockSSH.session.scp.download_last_remote).to include(files1.keys.first)
      end

      it 'downloads the file if already present with incorrect hash' do
        hash = mock_local_file(files: files2)
        expect { client.fetch(force: false) }.not_to raise_error
        files2.each { |file| expect(hash).to have_received(:file).with(file[0]).once }
        expect(MockSSH.session.scp.download_last_remote).to include(files1.keys.first)
      end
    end

    context 'when uses correct remote path' do
      let(:remote_dir) { '/hello/there' }
      let(:config) do
        {
          'dir' => remote_dir,
          'files' => TEST_FILES
        }
      end

      it do
        hash = mock_file_hashes
        expect { client.fetch(verify: true) }.not_to raise_error
        TEST_FILES.each { |file| expect(hash).to have_received(:file).with(file[0]).once }
        expect(MockSSH.session.scp.download_last_remote).to start_with(remote_dir)
      end
    end
  end

  describe '.put' do
    subject(:client) { described_class.new(config: config) }

    let(:file) { TEST_FILES.keys.first }

    context 'with empty files configuration' do
      let(:config) { { 'files' => {} } }

      it 'succeeds' do
        expect { client.put(file: file) }.not_to raise_error
      end
    end

    context 'with files in configuration' do
      let(:config) { { 'files' => TEST_FILES } }

      it 'uploads the file' do
        expect { client.put(file: file) }.not_to raise_error
      end
    end

    context 'when uses correct remote path' do
      let(:remote_dir) { '/hello/there' }
      let(:config) { { 'dir' => remote_dir } }

      it do
        expect { client.put(file: TEST_FILES.keys.first) }.not_to raise_error
        expect(MockSSH.session.scp.upload_last_remote).to start_with(remote_dir)
      end
    end
  end
end

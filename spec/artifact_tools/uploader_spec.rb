# frozen_string_literal: true

require 'artifact_tools/uploader'
require 'yaml'
require 'helpers'

def mock_stdout(files)
  files.each do |file|
    out = " #{file}"
    allow($stdout).to receive(:puts).with(out)
    expect($stdout).to receive(:puts).with(out)
  end
end

def mock_files(files, expect_calls: false)
  mock_file_hashes(files: files, expect_calls: expect_calls)
  mock_stdout(files)
end

describe ArtifactTools::Uploader do
  ['artifacts.yaml', 'conf_dir/artifacts.yaml'].each do |config_file_path|
    context "uses #{config_file_path}" do
      let(:config_file) { config_file_path }

      let(:config_file_dir) { File.dirname(config_file_path) }

      describe '.new' do
        let(:config) { { 'server' => 'xxx', 'dir' => 'yyy', 'files' => {} } }

        before do
          stub_const('ArtifactTools::Client', FakeClient)
          stub_const('ArtifactTools::ConfigFile', FakeConfig)
          FakeConfig.config = config
        end

        it 'reads config file' do
          described_class.new(config_file: config_file, files: [])
          expect(FakeConfig.from_file_calls).to eq 1
        end

        context 'when called with files parameter' do
          let(:files) do
            ['file1', 'dir1/file2']
              .map { |f| config_file_dir != '.' ? "#{config_file_dir}/#{f}" : f }
          end

          before { mock_files(files, expect_calls: true) }

          it 'uploads requested files' do
            described_class.new(config_file: config_file, files: files)
            expect(FakeClient.put_files).to eq files
          end

          it 'uploads and appends requested files' do
            described_class.new(config_file: config_file, files: files, append: true)
            expect(FakeClient.put_files).to eq files
            expect(FakeConfig.object.num_save).to eq 1
          end
        end

        context 'when issues a warning if file is not relative to configuration file' do
          let(:bad_files) { ['bad_file'] }

          it do
            next if config_file_dir == '.'

            mock_files(bad_files, expect_calls: true)
            expect do
              described_class.new(config_file: config_file, files: bad_files, append: true)
            end.to raise_error(RuntimeError, /relative/)
          end
        end
      end

      describe 'self.parse' do
        it 'requires -c option' do
          args = %w[-a]
          expect { described_class.parse(args) }.to raise_error(OptionParser::MissingArgument)
        end

        it 'parses all args' do
          files = ['file1', 'file2']
          args = ['-c', config_file, '-a'] + files
          hash = described_class.parse(args)
          expect(hash[:config_file]).to eq config_file
          expect(hash[:append]).to be true
          expect(hash[:files]).to eq files
        end
      end
    end
  end
end

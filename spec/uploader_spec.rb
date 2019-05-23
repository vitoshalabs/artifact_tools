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
        before { stub_const('ArtifactTools::Client', FakeClient) }
        before { stub_const('ArtifactTools::ConfigFile', FakeConfig) }
        before { FakeConfig.config = config }

        it "reads config file" do
          ArtifactTools::Uploader.new(config_file: config_file, files:[])
          expect(FakeConfig.from_file_calls).to eq 1
        end

        context "called with files parameter" do
          let(:files) {
            ['file1', 'dir1/file2']
              .map { |f| config_file_dir != '.' ? "#{config_file_dir}/#{f}" : f }
          }
          before { mock_files(files, expect_calls: true) }

          it "uploads requested files" do
            ArtifactTools::Uploader.new(config_file: config_file, files: files)
            expect(FakeClient.put_files).to eq files
          end

          it "uploads and appends requested files" do
            ArtifactTools::Uploader.new(config_file: config_file, files: files, append: true)
            expect(FakeClient.put_files).to eq files
            expect(FakeConfig.object.num_save).to eq 1
          end
        end
      end

      describe 'self.parse' do
        it "requires -c option" do
          args = %w[-a]
          expect { ArtifactTools::Uploader.parse(args) }.to raise_error(OptionParser::MissingArgument)
        end

        it "parses all args" do
          files = ['file1', 'file2']
          args = ['-c', config_file, '-a'] + files
          hash = ArtifactTools::Uploader.parse(args)
          expect(hash[:config_file]).to eq config_file
          expect(hash[:append]).to be
          expect(hash[:files]).to eq files
        end
      end
    end
  end
end

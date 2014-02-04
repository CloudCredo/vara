require 'spec_helper'

require 'tmpdir'

require 'support/unzip'
require 'vara/product_artifact_zipper'

describe Vara::ProductArtifactZipper do
  let(:artifact_dir) { File.join(Dir.tmpdir, 'product_artifact_zipper_spec') }
  let(:artifact_path) { File.join(artifact_dir, 'artifact.zip') }

  let(:tarball_filename) { 'fake_tarball.tgz' }
  let(:stemcell_filename) { 'fake_stemcell.tgz' }
  let(:tarball_path) { File.join(Dir.tmpdir, tarball_filename) }
  let(:stemcell_path) { File.join(Dir.tmpdir, stemcell_filename) }

  let(:artifact_components) do
    {
      releases: tarball_path,
      stemcells: stemcell_path
    }
  end

  let(:unzip_path) { File.join(Dir.tmpdir, 'unzipped_artifact') }

  subject(:zipper) { Vara::ProductArtifactZipper.new(artifact_path, artifact_components) }

  before do
    FileUtils.rm_rf(unzip_path)
    FileUtils.mkdir_p(unzip_path)
    FileUtils.rm_rf(artifact_dir)
    FileUtils.mkdir_p(artifact_dir)
    FileUtils.touch(tarball_path)
    FileUtils.touch(stemcell_path)
  end

  describe '#zip!' do
    it 'removes any previous artifact at the artifact path before creating a new one' do
      Vara::ProductArtifactZipper.new(artifact_path, foo: tarball_path).zip!

      zipper.zip!

      unzip(artifact_path, unzip_path)
      expect(Dir.new(unzip_path).entries).to_not include('foo')
    end

    it 'creates a zip file at the artifact path' do
      zipper.zip!

      expect(File.exist?(artifact_path)).to be_truthy
    end

    it 'creates a top level directory for each of the keys in artifact components' do
      zipper.zip!

      unzip(artifact_path, unzip_path)

      top_level_directories = Dir.new(unzip_path).entries.reject { |e| e.start_with? '.' }
      expected_directories = artifact_components.keys.map(&:to_s)
      expect(top_level_directories).to match_array(expected_directories)
    end

    it 'puts the artifact components in the correct top level directories' do
      zipper.zip!

      unzip(artifact_path, unzip_path)
      releases_path = File.join(unzip_path, 'releases')
      stemcells_path = File.join(unzip_path, 'stemcells')

      expect(Dir.new(releases_path).entries).to include(tarball_filename)
      expect(Dir.new(stemcells_path).entries).to include(stemcell_filename)
    end
  end
end

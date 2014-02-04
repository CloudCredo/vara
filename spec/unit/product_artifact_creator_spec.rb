require 'vara/product_artifact_creator'

describe Vara::ProductArtifactCreator do
  let(:migration_builder) { double('MigrationBuilder', build_for_all_previous_versions: { migration: 'true' }) }
  let(:metadata_coordinator) { double('metadata_coordinator', template_metadata: nil) }
  let(:stemcell_url) { 'http://example.com/stemcell.tgz' }
  let(:release_download_manager) { double('DownloadManager', acquire_latest_release: nil) }
  let(:artifact_dir) { '/tmp' }
  subject(:creator) do
    described_class.new(artifact_dir, release_download_manager, stemcell_url, metadata_coordinator, migration_builder)
  end

  let(:zipper) { double(:zipper, zip!: nil) }
  let(:stemcell_resource_manager) { double(:stemcell_resource_manager, download_stemcell: nil) }

  before do
    allow(Vara::ProductArtifactZipper).to receive(:new).and_return(zipper)
    allow(Vara::StemcellResourceManager).to receive(:new).and_return(stemcell_resource_manager)
  end

  describe '#create' do
    it 'returns a artifact path that includes the product name and version' do
      path = creator.create('hello', '1.0')

      expect(path).to eq(File.join(artifact_dir, 'hello-1.0.zip'))
    end

    it 'includes the migration data in the zip file' do
      artifact_zip = File.join(artifact_dir, 'foo-1.0.zip')
      expect(Vara::ProductArtifactZipper).to receive(:new).with(
                                               artifact_zip,
                                               hash_including(content_migrations: File.join(artifact_dir, 'migration-1.0.yml'))
                                             )
      creator.create('foo', '1.0')
    end
  end
end

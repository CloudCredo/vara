require 'vara/product_artifact_creator'

describe Vara::ProductArtifactCreator do
  let(:metadata_coordinator) { double('metadata_coordinator', template_metadata: nil) }
  let(:stemcell_url) { 'http://example.com/stemcell.tgz' }
  let(:release_download_manager) { double('DownloadManager', acquire_latest_release: nil) }
  let(:artifact_dir) { '/tmp' }
  subject(:creator) { described_class.new(artifact_dir, release_download_manager, stemcell_url, metadata_coordinator) }

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
  end
end

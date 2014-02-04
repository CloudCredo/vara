require 'spec_helper'

require 'vara/release_download_manager'

describe 'Given a Release Download Manager' do
  context 'When attempting to download a release' do
    let(:aws_download_client) { double('ProductCreation::AwsDownloadClient') }
    let(:service_type) { 'some service, e.g. Redis' }
    let(:local_release_dir) { '/some/parent/folder/for/file/' }

    subject(:release_download_manager) do
      Vara::ReleaseDownloadManager.new(aws_download_client, service_type, local_release_dir)
    end

    before do
      allow(aws_download_client).to receive(:list_bucket_objects_with_prefix).with(service_type).and_return(object_list)
    end

    describe '#aquire_latest_release' do
      context 'when there are no objects with the given prefix in the bucket' do
        let(:object_list) { [] }

        it 'does not try to download anything' do
          expect(aws_download_client).not_to receive(:download_object)
          expect do
            release_download_manager.acquire_latest_release
          end.to raise_error
        end

        it 'raises an appropriate error' do
          expect do
            release_download_manager.acquire_latest_release
          end.to raise_error(Vara::ReleaseDownloadManagerError, /#{service_type}/)
        end
      end

      context 'when there are objects with the given prefix in the bucket' do
        let(:latest_tarball) { 'redis/cf-redis-10.tgz' }
        let(:object_list) do
          ['redis/cf-redis-1.tgz', 'redis/cf-redis-2.tgz', latest_tarball, 'redis/some_non_tarball_file']
        end
        let(:file_path) { 'the path' }

        it 'downloads the latest object' do
          expect(aws_download_client).to receive(:download_object).with(latest_tarball, local_release_dir)
          release_download_manager.acquire_latest_release
        end

        it 'returns the local path as returned by the download client' do
          expect(aws_download_client).to receive(:download_object).and_return(file_path)
          expect(release_download_manager.acquire_latest_release).to eq(file_path)
        end
      end
    end
  end
end

require 'spec_helper'

require 'vara/aws_download_client'

describe Vara::AwsDownloadClient do
  let(:bucket_name) { 'i am bucket' }
  let(:access_key_id) { 'access_key_id' }
  let(:secret_access_key) { 'secret_access_key' }
  let(:s3_client) { double('s3-client') }
  let(:bucket) { double('s3-bucket') }
  let(:service_type) { 'some service type, e.g. Redis' }

  subject(:client) { Vara::AwsDownloadClient.new(bucket_name, access_key_id, secret_access_key) }

  before do
    expect(AWS::S3)
      .to receive(:new)
      .with(access_key_id: access_key_id, secret_access_key: secret_access_key)
      .and_return(s3_client)
    expect(s3_client).to receive(:buckets).and_return(bucket_name => bucket)
  end

  describe '#list_bucket_objects_with_prefix' do
    let(:aws_object) { double('aws_object', key: 'redis/some-redis-tarball-1.tgz') }
    let(:aws_object_collection) { double('aws-object-collection') }

    it 'returns array of strings representing AWS object keys with supplied prefix' do
      expect(bucket).to receive(:objects).and_return(aws_object_collection)
      expect(aws_object_collection).to receive(:with_prefix).with(service_type).and_return([aws_object])

      aws_object_keys = client.list_bucket_objects_with_prefix(service_type)
      expect(aws_object_keys).to eq(['redis/some-redis-tarball-1.tgz'])
    end
  end

  describe '#download_object' do
    let(:filename) { 'i_am_file' }
    let(:object_key) { File.join('redis', filename) }
    let(:object) { double('object') }
    let(:local_dir) { '/some/local/path' }
    let(:local_path) { File.join(local_dir, filename) }
    let(:file) { double('File') }
    let(:chunk) { double('Chunk') }

    it 'downloads the object to the given path on disk and returns that path' do
      expect(bucket).to receive(:objects).and_return(object_key => object)

      expect(File).to receive(:open).with(local_path, 'wb').and_yield(file)
      expect(object).to receive(:read).and_yield(chunk)
      expect(file).to receive(:write).with(chunk)

      path = client.download_object(object_key, local_dir)
      expect(path).to eq(local_path)
    end
  end
end

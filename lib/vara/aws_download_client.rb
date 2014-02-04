require 'aws-sdk'

module Vara
  class AwsDownloadClient
    def initialize(bucket_name, access_key_id, secret_access_key)
      s3_client = AWS::S3.new(access_key_id: access_key_id,
                              secret_access_key: secret_access_key)
      @bucket = s3_client.buckets[bucket_name]
    end

    def list_bucket_objects_with_prefix(prefix)
      bucket.objects.with_prefix(prefix).map(&:key)
    end

    def download_object(object_key, local_dir)
      object = bucket.objects[object_key]
      local_path = local_file_path(local_dir, object_key)

      File.open(local_path, 'wb') do |file|
        object.read do |chunk|
          file.write(chunk)
        end
      end

      local_path
    end

    private

    attr_reader :bucket

    def local_file_path(local_dir, object_key)
      filename = object_key.split('/').last
      File.join(local_dir, filename)
    end
  end
end

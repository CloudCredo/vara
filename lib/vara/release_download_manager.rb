module Vara
  class ReleaseDownloadManager
    def initialize(aws_download_client, service_type, local_release_dir)
      @aws_download_client = aws_download_client
      @service_type = service_type
      @local_release_dir = local_release_dir
    end

    def acquire_latest_release
      aws_objects = aws_download_client.list_bucket_objects_with_prefix(service_type)
      object_to_download = latest_release_tarball(aws_objects)

      unless object_to_download
        fail(ReleaseDownloadManagerError, "no release tarball found with prefix #{service_type}")
      end

      download_object(object_to_download)
    end

    private

    attr_reader :aws_download_client, :service_type, :local_release_dir

    def latest_release_tarball(aws_objects)
      aws_objects.max_by do |object|
        match = object.match(tgz_release_regex)
        match ? match[0].to_i : -1
      end
    end

    def download_object(object_to_download)
      aws_download_client.download_object(object_to_download, @local_release_dir)
    end

    def tgz_release_regex
      /(\d+)\.tgz/
    end
  end

  class ReleaseDownloadManagerError < Exception
  end
end

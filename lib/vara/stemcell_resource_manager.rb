require 'net/http'

require 'cli'

module Vara
  class InvalidStemcellResourceError < StandardError
    def initialize(uri)
      super "The provided uri #{uri} does not point to a valid stemcell resource"
    end
  end

  class StemcellResourceManager
    def download_stemcell(stemcell_url)
      file_name = URI.parse(stemcell_url).path.split('/').last
      fail(InvalidStemcellResourceError, stemcell_path.to_s) unless file_name
      download_path = stemcell_download_dir + file_name
      headers = if File.exists?(download_path)
                  { 'If-Modified-Since' => File.mtime(download_path).to_datetime.rfc2822 }
                else
                  {}
                end
      download_url(stemcell_url, download_path, headers)
    end

    def get_stemcell_name_and_version(stemcell_path)
      stemcell_command = Bosh::Cli::Stemcell.new(stemcell_path)

      begin
        stemcell_command.perform_validation
      rescue
        raise(InvalidStemcellResourceError, stemcell_path)
      end

      { name: stemcell_command.manifest['name'],
        version: stemcell_command.manifest['version'] }
    end

    def get_stemcell_info(stemcell_path)
      stemcell_name_and_version = get_stemcell_name_and_version(stemcell_path)
      stemcell_md5sum = Digest::MD5.hexdigest(File.read(stemcell_path))
      { name: stemcell_name_and_version[:name],
        version: stemcell_name_and_version[:version],
        md5sum: stemcell_md5sum,
        tarball: stemcell_path
      }
    end

    private

    def stemcell_download_dir
      Pathname.new(if ENV['STEMCELL_DOWNLOAD_DIR']
                     ENV['STEMCELL_DOWNLOAD_DIR']
                   else
                     Dir.tmpdir
                   end)
    end

    def download_url(download_url, download_path, headers = {})
      uri = URI.parse(download_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.request_get(uri.path, headers) do |resp|
        case resp.code
        when '304' then break # Do nothing, we already have the resource
        when '200'
          begin
            f = File.open(download_path, 'wb')
            resp.read_body do |segment|
              f.write(segment)
            end
          ensure
            f.close if f
          end
        else
          fail "Problem downloading resource: #{download_url}"
        end
      end
      puts download_path
      download_path
    end
  end
end

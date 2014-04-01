require 'digest'
require 'erubis'

module Vara
  class MetadataCoordinator
    def initialize(metadata_template_path, stemcell_resource_manager)
      @metadata_template_path = metadata_template_path
      @stemcell_resource_manager = stemcell_resource_manager
    end

    def template_metadata(product_name, product_version, release_tarball_path, stemcell_path, output_path)
      release_info = get_release_info(release_tarball_path)
      stemcell_info = get_stemcell_info(stemcell_path)

      metadata_context = {
          product_name: product_name,
          product_version: product_version,
          stemcell: stemcell_info,
          release: release_info
      }

      write_template(metadata_context, output_path)
    end

    private

    attr_reader :metadata_template_path, :stemcell_resource_manager

    def remove_dirname_from_tarball_value!(info)
      info.tap { |i| i[:tarball] = File.basename(i[:tarball]) }
    end

    def write_template(metadata_context, output_path)
      input = File.read(metadata_template_path)

      # Change the erb markup pattern to something unique as BOSH already uses the standard markup
      eruby = Erubis::Eruby.new(input, pattern: '<!--% %-->')

      result = eruby.result(metadata_context)
      File.write(output_path, result)
    end

    def get_release_info(release_tarball_path)
      name, version = name_and_version_from_tarball_path(release_tarball_path)
      md5sum = Digest::MD5.hexdigest(File.read(release_tarball_path))
      tarball_basename = File.basename(release_tarball_path)

      {
          name: name,
          version: version,
          tarball: tarball_basename,
          md5sum: md5sum
      }
    end

    def name_and_version_from_tarball_path(release_tarball_path)
      name_and_version = File.basename(release_tarball_path, '.tgz')
      version = name_and_version.match(/([^\-]+(?:-dev)?$)/)[1]
      name = name_and_version.gsub(/(.*)(-#{Regexp.escape(version)})/, '\1')
      [name, version]
    end

    def get_stemcell_info(stemcell_path)
      info = stemcell_resource_manager.get_stemcell_info(stemcell_path)
      info[:tarball] = File.basename(info[:tarball])
      info
    end
  end
end

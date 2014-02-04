require 'vara/product_artifact_zipper'
require 'vara/stemcell_resource_manager'

module Vara
  class ProductArtifactCreator
    def initialize(artifact_dir, release_download_manager, stemcell_url, metadata_coordinator)
      @artifact_dir = artifact_dir
      @release_download_manager = release_download_manager
      @stemcell_url = stemcell_url
      @metadata_coordinator = metadata_coordinator
    end

    def create(product_name, product_version)
      release_tarball_path = download_release
      stemcell_path = download_stemcell
      metadata_path = template_metadata(product_name, product_version, release_tarball_path, stemcell_path)

      artifact_components = {
          releases: release_tarball_path,
          stemcells: stemcell_path,
          metadata: metadata_path
      }

      artifact_path = artifact_path(product_name, product_version)
      ProductArtifactZipper.new(artifact_path, artifact_components).zip!
      artifact_path
    end

    private

    attr_reader :artifact_dir, :release_download_manager, :stemcell_url, :metadata_coordinator

    def artifact_path(product_name, product_version)
      File.join(artifact_dir, "#{product_name}-#{product_version}.zip")
    end

    def download_release
      release_download_manager.acquire_latest_release
    end

    def download_stemcell
      Vara::StemcellResourceManager.new.download_stemcell(stemcell_url)
    end

    def template_metadata(product_name, product_version, release_tarball_path, stemcell_path)
      metadata_path = File.join(artifact_dir, "#{product_name}.yml")
      metadata_coordinator.template_metadata(product_name, product_version,
                                             release_tarball_path, stemcell_path, metadata_path)
      metadata_path
    end
  end
end

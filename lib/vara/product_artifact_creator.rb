require 'vara/product_artifact_zipper'
require 'vara/stemcell_resource_manager'

module Vara
  class ProductArtifactCreator
    def initialize(artifact_dir, release_download_manager, stemcell_url, metadata_coordinator, migration_builder)
      @artifact_dir = artifact_dir
      @release_download_manager = release_download_manager
      @stemcell_url = stemcell_url
      @metadata_coordinator = metadata_coordinator
      @migration_builder = migration_builder
    end

    def create(product_name, product_version)
      release_tarball_path = download_release
      puts "Release downloaded to #{release_tarball_path}"

      stemcell_path = download_stemcell
      puts "Stemcell downloaded to: #{stemcell_path}"

      metadata_path = template_metadata(product_name, product_version, release_tarball_path, stemcell_path)
      puts "Metadata templated to: #{metadata_path}"

      migration_path = build_migration_file(product_name, product_version)
      puts "Migration file outputted to: #{migration_path}"

      artifact_components = {
          releases: release_tarball_path,
          stemcells: stemcell_path,
          metadata: metadata_path,
          content_migrations: migration_path
      }

      artifact_path = artifact_path(product_name, product_version)
      ProductArtifactZipper.new(artifact_path, artifact_components).zip!
      artifact_path
    end

    private

    attr_reader :artifact_dir, :release_download_manager, :stemcell_url, :metadata_coordinator,
                :migration_builder

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

    def build_migration_file(product_name, product_version)
      result = migration_builder.build_for_all_previous_versions(product_name, '1.0', product_version)
      migration_path = File.join(artifact_dir, "migration-#{product_version}.yml")
      File.write(migration_path, result.to_yaml)
      migration_path
    end
  end
end

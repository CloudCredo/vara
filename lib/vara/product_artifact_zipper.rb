module Vara
  class ProductArtifactZipper
    def initialize(artifact_path, artifact_components)
      @artifact_path = artifact_path
      @artifact_components = artifact_components
    end

    def zip!
      remove_previous_artifacts

      in_tmp_dir do |zip_temp_dir|
        copy_dirs_and_files
        create_zip!
      end
    end

    private

    attr_reader :artifact_path, :artifact_components

    def remove_previous_artifacts
      FileUtils.rm(artifact_path) if File.exist?(artifact_path)
    end

    def in_tmp_dir
      Dir.mktmpdir do |temp_dir|
        FileUtils.cd(temp_dir) do
          yield temp_dir
        end
      end
    end

    def copy_dirs_and_files
      artifact_components.each do |top_level_directory, directory_contents|
        FileUtils.mkdir(top_level_directory.to_s)
        FileUtils.cp(directory_contents.to_s, top_level_directory.to_s)
      end
    end

    def create_zip!
      `zip -r -0 #{artifact_path} .`
    end
  end
end

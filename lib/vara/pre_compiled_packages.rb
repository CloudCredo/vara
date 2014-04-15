require 'yaml'
require 'digest/md5'
require 'fileutils'
require 'vara/migration_builder'

module Vara
  class PreCompiledPackages
    def initialize(tmp_dir, artifact_zip)
      @tmp_dir = tmp_dir
      @migrations_dir = File.join(@tmp_dir, 'content_migrations')
      @compiled_packages_dir = File.join(@tmp_dir, 'compiled_packages')
      @artifact_zip = artifact_zip
    end

    def unpack
      system("unzip #{@artifact_zip} -d #{@tmp_dir} ")
      fail 'Zip failed' unless $?.exitstatus == 0
    end

    def repack
      new_artifact_path = File.join(Dir.tmpdir, increment_filename(@artifact_zip))
      system("cd #{@tmp_dir} && zip -FSr -0 #{new_artifact_path} .")
      fail 'Zip failed' unless $?.exitstatus == 0
      puts "*** New Product zip written to - #{new_artifact_path} ***"
    end

    def write_new_metadata
      new_release_yml = metadata_yml.clone
      new_version = increment_version
      new_release_yml['product_version'] = new_version
      new_release_yml['provides_product_versions'][0]['version'] = new_version
      new_release_yml.merge!(compiled_package_metadata)
      file_writer(metadata_file_path, new_release_yml.to_yaml)

      clear_old_migrations!
      migrations_file_path = File.join(@migrations_dir, 'migrations.yml')
      file_writer(migrations_file_path, migration(new_version).to_yaml)
    end

    def download_compiled_package
      data = release_metadata
      clear_old_packages!
      system("bosh export compiled_packages \
              #{data[:release_name]}/#{data[:release_version]} \
              #{data[:stemcell_name]}/#{data[:stemcell_version]} \
              #{@compiled_packages_dir}")
      fail 'Download of comiled packages failed
             Are you logged in to the correct BOSH director' unless $?.exitstatus == 0
      Dir.glob(File.join(@compiled_packages_dir, '*.tgz')).first
    end

    private

    def migration(new_version)
      migration_builder = Vara::MigrationBuilder.new
      migration_builder.build_for_all_previous_versions(
        release_metadata[:product_name],
        '1.1',
        new_version
      )
    end

    def clear_old_migrations!
      FileUtils.rm_f(Dir.glob(File.join(@migrations_dir, '*.yml')))
    end

    def clear_old_packages!
      if File.directory?(@compiled_packages_dir)
        FileUtils.rm_f(Dir.glob(File.join(@compiled_packages_dir, '*.tgz')))
      else
        Dir.mkdir(@compiled_packages_dir)
      end
    end

    def increment_filename(file_path)
      filename = File.basename(file_path)
      filename_components = filename.split('.')

      # The penultimate component is the build number that we want to
      # increment
      filename_components[-2] = filename_components[-2].succ

      filename_components.join('.')
    end

    def compiled_package_metadata
      package_tarball_path = download_compiled_package
      { compiled_package: { name:  "#{release_metadata[:release_name]}",
                            file: "#{File.basename(package_tarball_path)}",
                            version: "#{release_metadata[:release_version]}",
                            md5: "#{Digest::MD5.file(package_tarball_path).hexdigest}" } }
    end

    def increment_version
      data = release_metadata.clone
      data[:product_version].succ
    end

    def release_metadata
      product_name = metadata_yml['name']
      product_version = metadata_yml['product_version']
      stemcell_name =  metadata_yml['stemcell']['name']
      stemcell_version = metadata_yml['stemcell']['version']
      release_name = metadata_yml['releases'][0]['name']
      release_version = metadata_yml['releases'][0]['version']
      { product_name: product_name, product_version: product_version,
        stemcell_name: stemcell_name, stemcell_version: stemcell_version,
        release_name: release_name, release_version: release_version }
    end

    def metadata_yml
      YAML.load_file(metadata_file_path).clone
    end

    def metadata_file_path
      metadata_glob = File.join(@tmp_dir, 'metadata/*.yml')
      Dir.glob(metadata_glob).first
    end

    def file_writer(location, contents)
      afile = File.new(location, 'w')
      afile.write(contents)
      afile.close
    end
  end
end

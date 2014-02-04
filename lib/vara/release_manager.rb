require 'yaml'

module Vara
  class ReleaseManager
    def initialize(options = {})
      @bosh_director = options[:director]
      @release_command = options[:release_command]
      @final_release_command = options[:final_release_command]
    end

    def create_release(release_name)
      self.dev_release_name = release_name
      @release_command.create
    end

    def create_final_release
      @final_release_command.create
    end

    def upload_release(release_file)
      director_releases = @bosh_director.list_releases

      yaml = YAML.load_file(release_file)
      release_name = yaml['name']
      release_version = yaml['version']

      unless bosh_contains_release?(release_name, release_version, director_releases)
        @release_command.upload(release_file)
        BoshMediator.raise_on_error! @release_command
      end
    end

    def upload_dev_release(release_directory)
      upload_release find_dev_release(release_directory)
    end

    def release_info(release_attributes_path)
      release_attributes = YAML.load_file(release_attributes_path)
      tarball = "#{release_attributes_path.chomp(File.extname(release_attributes_path))}.tgz"
      md5sum = Digest::MD5.hexdigest(File.read(tarball))
      { name: release_attributes['name'],
        version: release_attributes['version'],
        tarball: tarball,
        md5sum: md5sum }
    end

    def dev_release_name=(release_name)
      fail "This directory is not a release directory - #{Dir.pwd}" unless File.directory?('config')
      dev_release_attributes = {
          'dev_name' => "#{release_name}",
          'latest_release_filename' => ''
      }
      File.write('config/dev.yml', dev_release_attributes.to_yaml)
    end

    def find_dev_release(release_directory)
      dev_release_attributes = YAML.load_file("#{release_directory}/config/dev.yml")
      dev_release_attributes['latest_release_filename']
    end

    private

    def bosh_contains_release?(expected_release_name, release_version, director_releases)
      director_releases.any? do |release_json|
        if release_json['name'] == expected_release_name
          release_versions = get_versions(release_json['release_versions'])
          release_versions.include?(release_version.to_s)
        end
      end
    end

    def get_versions(release_versions)
      release_versions.map do |release_version|
        release_version['version']
      end
    end
  end
end

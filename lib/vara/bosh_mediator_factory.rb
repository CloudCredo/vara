require 'cli'
require_relative 'bosh_mediator'

module Vara
  module BoshMediatorFactory
    def create_bosh_mediator(bosh_director_uri, username, password, manifest_file, release_dir)
      cd_to_release_dir!(release_dir)
      bosh_director = Bosh::Cli::Client::Director.new(bosh_director_uri, username, password)

      deployment_command = Bosh::Cli::Command::Deployment.new
      deployment_command.options = { config: manifest_file,
                                     target: bosh_director_uri,
                                     username: username,
                                     password: password,
                                     deployment: manifest_file,
                                     non_interactive: true,
                                     force: true }

      BoshMediator.new(director: bosh_director,
                       release_command: release_command,
                       deployment_command: deployment_command)
    end

    def create_local_bosh_mediator(release_dir)
      cd_to_release_dir!(release_dir)
      BoshMediator.new(release_command: release_command)
    end

    def create_local_bosh_mediator_final(release_dir)
      cd_to_release_dir!(release_dir)
      BoshMediator.new(final_release_command: final_release_command)
    end

    private

    def cd_to_release_dir!(release_dir)
      fail(ArgumentError, "Release directory does not exist: #{release_dir}") unless File.directory?(release_dir)
      p release_dir
      Dir.chdir(release_dir)
    end

    def release_command
      release_command = Bosh::Cli::Command::Release.new
      release_command.add_option(:force, true)
      release_command.add_option(:with_tarball, true)
      release_command.add_option(:non_interactive, true)
      release_command
    end

    def final_release_command
      final_release_command = Bosh::Cli::Command::Release.new
      final_release_command.add_option(:force, true)
      final_release_command.add_option(:with_tarball, true)
      final_release_command.add_option(:final, true)
      final_release_command.add_option(:non_interactive, true)
      final_release_command
    end
  end
end

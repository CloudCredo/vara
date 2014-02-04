require 'spec_helper'

require 'webrick'
require 'yaml'

require 'support/unzip'

require 'vara/metadata_coordinator'
require 'vara/product_artifact_creator'
require 'vara/release_download_manager'

describe 'creation of a product artifact zip' do
  let(:product_name) { 'redis' }
  let(:service_type) { 'redis' }
  let(:product_version) { '0.0.0.3' }
  let(:metadata_template_path) { File.join(assets_path, 'example_metadata_template.yml.erb') }

  subject(:product_artifact_creator) do
    release_download_manager = Vara::ReleaseDownloadManager
        .new(FakeAwsDownloadClient.new, service_type, local_working_dir)
    metadata_coordinator = Vara::MetadataCoordinator
        .new(metadata_template_path, Vara::StemcellResourceManager.new)
    migration_builder = Vara::MigrationBuilder.new
    Vara::ProductArtifactCreator
        .new(local_working_dir, release_download_manager, stemcell_url, metadata_coordinator, migration_builder)
  end

  before :all do
    @spec_assets_server_thread = spec_assets_server
  end

  after :all do
    @spec_assets_server_thread.kill
  end

  before do
    FileUtils.rm_rf(local_working_dir)
    FileUtils.mkdir_p(local_working_dir)
  end

  it 'includes the release tarball in the releases directory inside the zip' do
    artifact_path = product_artifact_creator.create(product_name, product_version)
    unzip_destination = unzip_artifact(artifact_path, local_working_dir)

    expect(Dir.new(unzip_destination).entries).to include('releases')
    expect(Dir.new(File.join(unzip_destination, 'releases')).entries).to include('cf-redis-42.tgz')
  end

  it 'includes the stemcell in the stemcells directory inside the zip' do
    artifact_path = product_artifact_creator.create(product_name, product_version)
    unzip_destination = unzip_artifact(artifact_path, local_working_dir)

    expect(Dir.new(unzip_destination).entries).to include('stemcells')
    expect(Dir.new(File.join(unzip_destination, 'stemcells')).entries).to include('fake_stemcell.tgz')
  end

  it 'includes a correctly templated metadata file in the metadata directory inside the zip' do
    artifact_path = product_artifact_creator.create(product_name, product_version)
    unzip_destination = unzip_artifact(artifact_path, local_working_dir)

    expect(Dir.new(unzip_destination).entries).to include('metadata')
    metadata_file_path = File.join(unzip_destination, 'metadata', "#{product_name}.yml")
    metadata = YAML.load_file(metadata_file_path)

    expect(metadata).to include(
                             'name' => product_name,
                             'product_version' => product_version,
                             'stemcell' => {
                               'name' => 'bosh-warden-boshlite-ubuntu',
                               'version' => '24',
                               'file' => 'fake_stemcell.tgz',
                               'md5' => '1b3bd2559b69ec45d8283349c44a646f'
                             },
                             'releases' => [
                               {
                                 'name' => 'cf-redis',
                                 'version' => '42',
                                 'file' => 'cf-redis-42.tgz',
                                 'md5' => 'd41d8cd98f00b204e9800998ecf8427e'
                               }
                             ],
                             'provides_product_versions' => [
                               {
                                 'name' => product_name,
                                 'version' => product_version
                               }
                             ]
                           )
  end

  it 'includes a migration file in the content_migrations directory inside the zip' do
    artifact_path = product_artifact_creator.create(product_name, product_version)
    unzip_destination = unzip_artifact(artifact_path, local_working_dir)

    expect(Dir.new(unzip_destination).entries).to include('content_migrations')
    migration_file_path = File.join(unzip_destination, 'content_migrations', "migration-#{product_version}.yml")
    migration = YAML.load_file(migration_file_path)

    expect(migration).to include(
                          'product' => product_name,
                          'to_version' => product_version,
                          'installation_version' => '1.0',
                        )
    versions = migration.fetch('migrations').map { |migration| migration.fetch('product_version') }
    expect(versions).to eq(%w(0.0.0.1 0.0.0.2))
  end
end

class FakeAwsDownloadClient
  def list_bucket_objects_with_prefix(prefix)
    ['redis/cf-redis-42.tgz']
  end

  def download_object(object_key, local_dir)
    source = File.join(spec_assets_dir, 'example-release-12.tgz')
    destination = File.join(local_working_dir, 'cf-redis-42.tgz')
    FileUtils.cp(source, destination)
    destination
  end
end

def local_working_dir
  File.join(Dir.tmpdir, 'product_artifact_creation_spec')
end

def spec_assets_dir
  File.join(File.dirname(__FILE__), '..', 'assets')
end

def stemcell_url
  "http://localhost:#{spec_assets_server_port}/fake_stemcell.tgz"
end

def spec_assets_server_port
  8123
end

def spec_assets_server
  thread = Thread.new do
    server = WEBrick::HTTPServer.new Port: spec_assets_server_port, DocumentRoot: spec_assets_dir
    trap :INT do
      server.shutdown
    end
    server.start
  end
  sleep 1
  thread
end

def unzip_artifact(artifact_path, local_working_dir)
  destination = File.join(local_working_dir, 'unzipped_artifact')
  unzip(artifact_path, destination)
  destination
end

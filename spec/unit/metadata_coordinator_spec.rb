require 'spec_helper'

require 'tmpdir'
require 'yaml'

require 'vara/metadata_coordinator'

describe Vara::MetadataCoordinator do
  let(:metadata_template_path) { File.join(assets_path, 'example_metadata_template.yml.erb') }
  let(:stemcell_resource_manager) { double('stemcell_resource_manager') }

  let(:product_name) { 'ProductX' }
  let(:product_version) { '1.2.3' }

  let(:release_tarball_path) { File.join(assets_path, 'example-release-12.tgz') }
  let(:release_md5sum) { Digest::MD5.hexdigest(File.read(release_tarball_path)) }
  let(:release_info) do
    {
      name: 'example-release',
      version: 12,
      tarball: release_tarball_path,
      md5sum: release_md5sum
    }
  end

  let(:stemcell_path) { '/whatever/stemcell.tgz' }
  let(:stemcell_info) do
    {
      name: 'stemcell-name',
      version: 42,
      tarball: '/some/path/to/a/stemcell.tgz',
      md5sum: 'anothermd5sum'
    }
  end

  let(:output_path) { File.join(Dir.tmpdir, 'test_metadata.yml') }

  subject(:metadata_coordinator) do
    Vara::MetadataCoordinator.new(metadata_template_path, stemcell_resource_manager)
  end

  before do
    FileUtils.rm_rf(output_path)
    allow(stemcell_resource_manager).to receive(:get_stemcell_info).with(stemcell_path).and_return(stemcell_info)
  end

  it 'templates the metadata it received and writes the correct result to the specified path' do
    metadata_coordinator
      .template_metadata(product_name, product_version, release_tarball_path, stemcell_path, output_path)

    result = YAML.load_file(output_path)
    expect(result).to eq(
                           'name' => product_name,
                           'product_version' => product_version,
                           'metadata_version' => 1.0,
                           'stemcell' => {
                             'name' => stemcell_info[:name],
                             'version' => "#{stemcell_info[:version]}",
                             'file' => File.basename(stemcell_info[:tarball]),
                             'md5' => stemcell_info[:md5sum]
                           },
                           'releases' => [
                             {
                               'name' => release_info[:name],
                               'version' => "#{release_info[:version]}",
                               'file' => File.basename(release_info[:tarball]),
                               'md5' => release_info[:md5sum]
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
end

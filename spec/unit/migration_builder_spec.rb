require 'vara/migration_builder'

describe Vara::MigrationBuilder do
  let(:product_name) { 'redis' }
  let(:installation_version) { '1.0' }
  let(:to_version) { '0.0.0.11' }
  let(:from_versions) { %w(0.0.0.2 0.0.0.3) }
  let(:migration_builder) { Vara::MigrationBuilder.new }
  let(:result) do
    migration_builder.build(product_name, installation_version,
                            to_version, from_versions)
  end

  describe 'automatically working out which versions we need to migrate from' do
    it 'includes all of the previous versions' do
      previous_versions = %w(0.0.0.1 0.0.0.2 0.0.0.3 0.0.0.4 0.0.0.5 0.0.0.6 0.0.0.7 0.0.0.8 0.0.0.9 0.0.0.10)
      expect(migration_builder).to receive(:build)
                                        .with(product_name, installation_version,
                                              to_version, previous_versions)

      migration_builder.build_for_all_previous_versions(product_name, installation_version, to_version)
    end
  end

  describe 'building a set of product version migrations' do
    it 'returns the product name that is given' do
      expect(result.fetch('product')).to eq(product_name)
    end

    it 'returns the installation version that is given' do
      expect(result.fetch('installation_version')).to eq(installation_version)
    end

    it 'returns the version that it is being updated to' do
      expect(result.fetch('to_version')).to eq(to_version)
    end

    def product_version_migration(from_version, to_version)
      {
        'product_version' => from_version,
        'rules' => [
          {
            'type' => 'update',
            'selector' => 'product_version',
            'value' => to_version
          }
        ]
      }
    end

    def product_version_migrations(from_versions, to_version)
      from_versions.map do |from_version|
        product_version_migration(from_version, to_version)
      end
    end

    describe 'generating the version list' do
      context 'with multiple from versions' do
        it 'returns a migration for each of them' do
          migrations = result.fetch('migrations')
          expect(migrations).to eq(product_version_migrations(from_versions, to_version))
        end
      end
    end
  end
end

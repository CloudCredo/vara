module Vara
  class MigrationBuilder
    def build_for_all_previous_versions(product_name, installation_version, to_version)
      build_to_version = to_version.split('.').last.to_i
      from_versions = (1...build_to_version).map { |version| "0.0.0.#{version}" }
      build(product_name, installation_version, to_version, from_versions)
    end

    def build(product_name, installation_version, to_version, from_versions)
      {
        'product' => product_name,
        'installation_version' => installation_version,
        'to_version' => to_version,
        'migrations' => product_version_migrations(from_versions, to_version)
      }
    end

    private

    attr_reader :product_name, :installation_version,
                :to_version

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
  end
end

require_relative 'shared_examples'

provider_class = Puppet::Type.type(:elasticsearch-legacy_plugin).provider(:elasticsearch-legacy_plugin)

describe provider_class do
  let(:resource_name) { 'lmenezes/elasticsearch-legacy-kopf' }
  let(:resource) do
    Puppet::Type.type(:elasticsearch-legacy_plugin).new(
      :name     => resource_name,
      :ensure   => :present,
      :provider => 'elasticsearch-legacy_plugin'
    )
  end
  let(:provider) do
    provider = provider_class.new
    provider.resource = resource
    provider
  end
  let(:shortname) { provider.plugin_name(resource_name) }
  let(:klass) { provider_class }

  include_examples 'plugin provider', '5.0.1'
end

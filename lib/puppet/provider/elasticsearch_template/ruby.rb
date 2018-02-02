$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))

require 'puppet/provider/elastic_rest'

require 'puppet_x/elastic/deep_to_i'

Puppet::Type.type(:elasticsearch-legacy_template).provide(
  :ruby,
  :parent => Puppet::Provider::ElasticREST,
  :api_uri => '_template',
  :metadata => :content,
  :metadata_pipeline => [
    lambda { |data| Puppet_X::Elastic.deep_to_i data }
  ]
) do
  desc 'A REST API based provider to manage elasticsearch-legacy templates.'

  mk_resource_methods
end

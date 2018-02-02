$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..'))

require 'puppet_x/elastic/deep_to_i'
require 'puppet_x/elastic/deep_implode'
require 'puppet_x/elastic/elasticsearch-legacy_rest_resource'

Puppet::Type.newtype(:elasticsearch-legacy_pipeline) do
  extend elasticsearch-legacyRESTResource

  desc 'Manages elasticsearch-legacy ingest pipelines.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Pipeline name.'
  end

  newproperty(:content) do
    desc 'Structured content of pipeline.'

    validate do |value|
      raise Puppet::Error, 'hash expected' unless value.is_a? Hash
    end

    munge do |value|
      Puppet_X::Elastic.deep_to_i(value)
    end
  end
end # of newtype

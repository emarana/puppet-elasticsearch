require_relative '../../helpers/unit/type/elasticsearch-legacy_rest_shared_examples'

describe Puppet::Type.type(:elasticsearch-legacy_pipeline) do
  let(:resource_name) { 'test_pipeline' }

  include_examples 'REST API types', 'pipeline', :content
end

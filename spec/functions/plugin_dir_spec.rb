require 'spec_helper'

describe 'plugin_dir' do

  describe 'exception handling' do
    describe 'with no arguments' do
      it { is_expected.to run.with_params()
        .and_raise_error(Puppet::ParseError) }
    end

    describe 'more than two arguments' do
      it { is_expected.to run.with_params('a', 'b', 'c')
        .and_raise_error(Puppet::ParseError) }
    end

    describe 'non-string arguments' do
      it { is_expected.to run.with_params([])
        .and_raise_error(Puppet::ParseError) }
    end
  end

  {
    'mobz/elasticsearch-legacy-head' => 'head',
    'lukas-vlcek/bigdesk/2.4.0' => 'bigdesk',
    'elasticsearch-legacy/elasticsearch-legacy-cloud-aws/2.5.1' => 'cloud-aws',
    'com.sksamuel.elasticsearch-legacy/elasticsearch-legacy-river-redis/1.1.0' => 'river-redis',
    'com.github.lbroudoux.elasticsearch-legacy/amazon-s3-river/1.4.0' => 'amazon-s3-river',
    'elasticsearch-legacy/elasticsearch-legacy-lang-groovy/2.0.0' => 'lang-groovy',
    'royrusso/elasticsearch-legacy-hq' => 'hq',
    'polyfractal/elasticsearch-legacy-inquisitor' => 'inquisitor',
    'mycustomplugin' => 'mycustomplugin'
  }.each do |plugin, dir|
    describe "parsed dir for #{plugin}" do
      it { is_expected.to run.with_params(plugin).and_return(dir) }
    end
  end

end

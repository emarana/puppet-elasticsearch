require 'puppet/provider/elastic_plugin'

Puppet::Type.type(:elasticsearch-legacy_plugin).provide(
  :plugin,
  :parent => Puppet::Provider::ElasticPlugin
) do
  desc 'Pre-5.x provider for elasticsearch-legacy bin/plugin command operations.'

  case Facter.value('osfamily')
  when 'OpenBSD'
    commands :plugin => '/usr/local/elasticsearch-legacy/bin/plugin'
    commands :es => '/usr/local/elasticsearch-legacy/bin/elasticsearch-legacy'
    commands :javapathhelper => '/usr/local/bin/javaPathHelper'
  else
    commands :plugin => '/usr/share/elasticsearch-legacy/bin/plugin'
    commands :es => '/usr/share/elasticsearch-legacy/bin/elasticsearch-legacy'
  end

end

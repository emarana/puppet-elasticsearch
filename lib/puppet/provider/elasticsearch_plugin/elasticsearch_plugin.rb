require 'puppet/provider/elastic_plugin'

Puppet::Type.type(:elasticsearch-legacy_plugin).provide(
  :elasticsearch-legacy_plugin,
  :parent => Puppet::Provider::ElasticPlugin
) do
  desc <<-END
    Post-5.x provider for elasticsearch-legacy bin/elasticsearch-legacy-plugin
    command operations.'
  END

  case Facter.value('osfamily')
  when 'OpenBSD'
    commands :plugin => '/usr/local/elasticsearch-legacy/bin/elasticsearch-legacy-plugin'
    commands :es => '/usr/local/elasticsearch-legacy/bin/elasticsearch-legacy'
    commands :javapathhelper => '/usr/local/bin/javaPathHelper'
  else
    commands :plugin => '/usr/share/elasticsearch-legacy/bin/elasticsearch-legacy-plugin'
    commands :es => '/usr/share/elasticsearch-legacy/bin/elasticsearch-legacy'
  end

end

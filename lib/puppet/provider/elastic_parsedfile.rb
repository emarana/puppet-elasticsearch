require 'puppet/provider/parsedfile'

# Parent class for elasticsearch-legacy-based providers that need to access
# specific configuration directories.
class Puppet::Provider::ElasticParsedFile < Puppet::Provider::ParsedFile
  # Find/set a shield configuration file.
  #
  # @return String
  def self.shield_config(val)
    @default_target ||= "/etc/elasticsearch-legacy/shield/#{val}"
  end

  # Find/set an x-pack configuration file.
  #
  # @return String
  def self.xpack_config(val)
    @default_target ||= "/etc/elasticsearch-legacy/x-pack/#{val}"
  end
end

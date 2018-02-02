require 'puppet/parameter/boolean'

# Provides common properties and parameters for REST-based elasticsearch-legacy types
module elasticsearch-legacyRESTResource
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def self.extended(extender)
    extender.newparam(:ca_file) do
      desc 'Absolute path to a CA file to authenticate server certs against.'
    end

    extender.newparam(:ca_path) do
      desc 'Absolute path to a directory containing CA files.'
    end

    extender.newparam(:host) do
      desc 'Hostname or address of elasticsearch-legacy instance.'
      defaultto 'localhost'

      validate do |value|
        unless value.is_a? String
          raise Puppet::Error, 'invalid parameter, expected string'
        end
      end
    end

    extender.newparam(:password) do
      desc 'Optional HTTP basic auth plaintext password for elasticsearch-legacy.'
    end

    extender.newparam(:port) do
      desc 'Port to use for elasticsearch-legacy HTTP API operations.'
      defaultto 9200

      munge do |value|
        if value.is_a? String
          value.to_i
        elsif value.is_a? Integer
          value
        else
          raise Puppet::Error, "unknown '#{value}' timeout type #{value.class}"
        end
      end

      validate do |value|
        raise Puppet::Error, "invalid port value '#{value}'" \
          unless value.to_s =~ /^([0-9]+)$/
        raise Puppet::Error, "invalid port value '#{value}'" \
          unless (0 < Regexp.last_match[0].to_i) \
            and (Regexp.last_match[0].to_i < 65_535)
      end
    end

    extender.newparam(:protocol) do
      desc 'Protocol to use for communication with elasticsearch-legacy.'
      defaultto 'http'
    end

    extender.newparam(:timeout) do
      desc 'HTTP timeout for reading/writing content to elasticsearch-legacy.'
      defaultto 10

      munge do |value|
        if value.is_a? String
          value.to_i
        elsif value.is_a? Integer
          value
        else
          raise Puppet::Error, "unknown '#{value}' timeout type #{value.class}"
        end
      end

      validate do |value|
        if value.to_s !~ /^\d+$/
          raise Puppet::Error, 'timeout must be a positive integer'
        end
      end
    end

    extender.newparam(:username) do
      desc 'Optional HTTP basic auth username for elasticsearch-legacy.'
    end

    extender.newparam(
      :validate_tls,
      :boolean => true,
      :parent => Puppet::Parameter::Boolean
    ) do
      desc 'Whether to verify TLS/SSL certificates.'
      defaultto true
    end
  end
end # of newtype

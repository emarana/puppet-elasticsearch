require 'spec_helper'

describe 'elasticsearch-legacy::role' do
  let(:title) { 'elastic_role' }

  let(:pre_condition) do
    <<~EOS
      class { 'elasticsearch-legacy':
        security_plugin => 'shield',
      }
    EOS
  end

  let(:params) do
    {
      :privileges => {
        'cluster' => '*'
      },
      :mappings => [
        'cn=users,dc=example,dc=com',
        'cn=admins,dc=example,dc=com',
        'cn=John Doe,cn=other users,dc=example,dc=com'
      ]
    }
  end

  on_supported_os(
    :hardwaremodels => ['x86_64'],
    :supported_os => [
      {
        'operatingsystem' => 'CentOS',
        'operatingsystemrelease' => ['7']
      }
    ]
  ).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(
        :scenario => '',
        :common => ''
      ) }

      context 'with an invalid role name' do
        context 'too long' do
          let(:title) { 'A' * 31 }
          it { should raise_error(Puppet::Error, /expected length/i) }
        end
      end

      context 'with default parameters' do
        it { should contain_elasticsearch-legacy__role('elastic_role') }
        it { should contain_elasticsearch-legacy_role('elastic_role') }
        it do
          should contain_elasticsearch-legacy_role_mapping('elastic_role').with(
            'ensure' => 'present',
            'mappings' => [
              'cn=users,dc=example,dc=com',
              'cn=admins,dc=example,dc=com',
              'cn=John Doe,cn=other users,dc=example,dc=com'
            ]
          )
        end
      end

      describe 'collector ordering' do
        describe 'when present' do
          let(:pre_condition) do
            <<~EOS
              class { 'elasticsearch-legacy':
                security_plugin => 'shield',
              }
              elasticsearch-legacy::instance { 'es-security-role': }
              elasticsearch-legacy::plugin { 'shield': instances => 'es-security-role' }
              elasticsearch-legacy::template { 'foo': content => {"foo" => "bar"} }
              elasticsearch-legacy::user { 'elastic':
                password => 'foobar',
                roles => ['elastic_role'],
              }
            EOS
          end

          it { should contain_elasticsearch-legacy__plugin('shield') }
          it { should contain_elasticsearch-legacy__role('elastic_role')
            .that_comes_before([
            'elasticsearch-legacy::Template[foo]',
            'elasticsearch-legacy::User[elastic]'
          ]).that_requires([
            'elasticsearch-legacy::Plugin[shield]'
          ])}

          include_examples 'instance', 'es-security-role', :systemd
          it { should contain_file(
            '/etc/elasticsearch-legacy/es-security-role/shield'
          ) }
        end

        describe 'when absent' do
          let(:pre_condition) do
            <<~EOS
              class { 'elasticsearch-legacy':
                security_plugin => 'shield',
              }
              elasticsearch-legacy::instance { 'es-security-role': }
              elasticsearch-legacy::plugin { 'shield':
                ensure => 'absent',
                instances => 'es-security-role',
              }
              elasticsearch-legacy::template { 'foo': content => {"foo" => "bar"} }
              elasticsearch-legacy::user { 'elastic':
                password => 'foobar',
                roles => ['elastic_role'],
              }
            EOS
          end

          it { should contain_elasticsearch-legacy__plugin('shield') }
          include_examples 'instance', 'es-security-role', :systemd
          # TODO: Uncomment once upstream issue is fixed.
          # https://github.com/rodjek/rspec-puppet/issues/418
          # it { should contain_elasticsearch-legacy__shield__role('elastic_role')
          #   .that_comes_before([
          #   'elasticsearch-legacy::Template[foo]',
          #   'elasticsearch-legacy::Plugin[shield]',
          #   'elasticsearch-legacy::Shield::User[elastic]'
          # ])}
        end
      end
    end
  end
end

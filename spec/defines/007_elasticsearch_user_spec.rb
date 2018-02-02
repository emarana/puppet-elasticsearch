require 'spec_helper'

describe 'elasticsearch-legacy::user' do
  let(:title) { 'elastic' }

  let(:pre_condition) do
    <<-EOS
      class { 'elasticsearch-legacy':
        security_plugin => 'shield',
      }
    EOS
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

      context 'with default parameters' do
        let(:params) do
          {
            :password => 'foobar',
            :roles => %w[monitor user]
          }
        end

        it { should contain_elasticsearch-legacy__user('elastic') }
        it { should contain_elasticsearch-legacy_user('elastic') }
        it do
          should contain_elasticsearch-legacy_user_roles('elastic').with(
            'ensure' => 'present',
            'roles'  => %w[monitor user]
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
              elasticsearch-legacy::instance { 'es-security-user': }
              elasticsearch-legacy::plugin { 'shield': instances => 'es-security-user' }
              elasticsearch-legacy::template { 'foo': content => {"foo" => "bar"} }
              elasticsearch-legacy::role { 'test_role':
                privileges => {
                  'cluster' => 'monitor',
                  'indices' => {
                    '*' => 'all',
                  },
                },
              }
            EOS
          end

          let(:params) do
            {
              :password => 'foobar',
              :roles => %w[monitor user]
            }
          end

          it { should contain_elasticsearch-legacy__role('test_role') }
          it { should contain_elasticsearch-legacy_role('test_role') }
          it { should contain_elasticsearch-legacy_role_mapping('test_role') }
          it { should contain_elasticsearch-legacy__plugin('shield') }
          it { should contain_elasticsearch-legacy_plugin('shield') }
          it { should contain_file(
            '/usr/share/elasticsearch-legacy/plugins/shield'
          ) }
          it { should contain_elasticsearch-legacy__user('elastic')
            .that_comes_before([
            'elasticsearch-legacy::Template[foo]'
          ]).that_requires([
            'elasticsearch-legacy::Plugin[shield]',
            'elasticsearch-legacy::Role[test_role]'
          ])}

          include_examples 'instance', 'es-security-user', :systemd
          it { should contain_file(
            '/etc/elasticsearch-legacy/es-security-user/shield'
          ) }
        end

        describe 'when absent' do
          let(:pre_condition) do
            <<~EOS
              class { 'elasticsearch-legacy':
                security_plugin => 'shield',
              }
              elasticsearch-legacy::instance { 'es-security-user': }
              elasticsearch-legacy::plugin { 'shield':
                ensure => 'absent',
                instances => 'es-security-user',
              }
              elasticsearch-legacy::template { 'foo': content => {"foo" => "bar"} }
              elasticsearch-legacy::role { 'test_role':
                privileges => {
                  'cluster' => 'monitor',
                  'indices' => {
                    '*' => 'all',
                  },
                },
              }
            EOS
          end

          let(:params) do
            {
              :password => 'foobar',
              :roles => %w[monitor user]
            }
          end

          it { should contain_elasticsearch-legacy__role('test_role') }
          it { should contain_elasticsearch-legacy_role('test_role') }
          it { should contain_elasticsearch-legacy_role_mapping('test_role') }
          it { should contain_elasticsearch-legacy__plugin('shield') }
          it { should contain_elasticsearch-legacy_plugin('shield') }
          it { should contain_file(
            '/usr/share/elasticsearch-legacy/plugins/shield'
          ) }
          it { should contain_elasticsearch-legacy__user('elastic')
            .that_comes_before([
              'elasticsearch-legacy::Template[foo]',
              'elasticsearch-legacy::Plugin[shield]'
          ]).that_requires([
            'elasticsearch-legacy::Role[test_role]'
          ])}

          include_examples 'instance', 'es-security-user', :systemd
        end
      end
    end
  end
end

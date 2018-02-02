require 'spec_helper'

describe 'elasticsearch-legacy::plugin', :type => 'define' do
  let(:title) { 'mobz/elasticsearch-legacy-head/1.0.0' }

  on_supported_os(
    :hardwaremodels => ['x86_64'],
    :supported_os => [
      {
        'operatingsystem' => 'CentOS',
        'operatingsystemrelease' => ['6']
      }
    ]
  ).each do |_os, facts|
    let(:facts) do
      facts.merge('scenario' => '', 'common' => '')
    end

    let(:pre_condition) do
      <<-EOS
        class { "elasticsearch-legacy":
          config => {
            "node" => {
              "name" => "test"
            }
          }
        }
      EOS
    end

    context 'default values' do
      context 'present' do
        let(:params) do {
          :ensure => 'present',
          :configdir => '/etc/elasticsearch-legacy',
          :instances => 'es-plugin'
        } end

        it { is_expected.to compile }
      end

      context 'absent' do
        let(:params) do {
          :ensure => 'absent',
          :instances  => 'es-plugin'
        } end

        it { is_expected.to compile }
      end

      context 'configdir' do
        let(:params) do {
          :instances => 'es-plugin'
        } end

        it { should contain_elasticsearch-legacy__plugin(
          'mobz/elasticsearch-legacy-head/1.0.0'
        ).with_configdir('/etc/elasticsearch-legacy') }

        it { should contain_elasticsearch-legacy_plugin(
          'mobz/elasticsearch-legacy-head/1.0.0'
        ).with_configdir('/etc/elasticsearch-legacy') }
      end
    end

    context 'with module_dir' do
      context 'add a plugin' do
        let(:params) do {
          :ensure     => 'present',
          :module_dir => 'head',
          :instances  => 'es-plugin'
        } end

        it { should contain_elasticsearch-legacy__plugin(
          'mobz/elasticsearch-legacy-head/1.0.0'
        ) }
        it { should contain_elasticsearch-legacy_plugin(
          'mobz/elasticsearch-legacy-head/1.0.0'
        ) }
        it { should contain_file(
          '/usr/share/elasticsearch-legacy/plugins/head'
        ).that_requires(
          'elasticsearch-legacy_plugin[mobz/elasticsearch-legacy-head/1.0.0]'
        ) }
      end

      context 'remove a plugin' do
        let(:params) do {
          :ensure     => 'absent',
          :module_dir => 'head',
          :instances  => 'es-plugin'
        } end

        it { should contain_elasticsearch-legacy__plugin(
          'mobz/elasticsearch-legacy-head/1.0.0'
        ) }
        it { should contain_elasticsearch-legacy_plugin(
          'mobz/elasticsearch-legacy-head/1.0.0'
        ).with(
          :ensure => 'absent'
        ) }
        it { should contain_file(
          '/usr/share/elasticsearch-legacy/plugins/head'
        ).that_requires(
          'elasticsearch-legacy_plugin[mobz/elasticsearch-legacy-head/1.0.0]'
        ) }
      end
    end

    context 'with url' do
      context 'add a plugin with full name' do
        let(:params) do {
          :ensure     => 'present',
          :instances  => 'es-plugin',
          :url        => 'https://github.com/mobz/elasticsearch-legacy-head/archive/master.zip'
        } end

        it { should contain_elasticsearch-legacy__plugin('mobz/elasticsearch-legacy-head/1.0.0') }
        it { should contain_elasticsearch-legacy_plugin('mobz/elasticsearch-legacy-head/1.0.0').with(:ensure => 'present', :url => 'https://github.com/mobz/elasticsearch-legacy-head/archive/master.zip') }
      end
    end

    context 'offline plugin install' do
      let(:title) { 'head' }
      let(:params) do {
        :ensure    => 'present',
        :instances => 'es-plugin',
        :source    => 'puppet:///path/to/my/plugin.zip'
      } end

      it { should contain_elasticsearch-legacy__plugin('head') }
      it { should contain_file('/opt/elasticsearch-legacy/swdl/plugin.zip').with(:source => 'puppet:///path/to/my/plugin.zip', :before => 'elasticsearch-legacy_plugin[head]') }
      it { should contain_elasticsearch-legacy_plugin('head').with(:ensure => 'present', :source => '/opt/elasticsearch-legacy/swdl/plugin.zip') }
    end

    describe 'service restarts' do
      let(:title) { 'head' }
      let(:params) do {
        :ensure     => 'present',
        :instances  => 'es-plugin',
        :module_dir => 'head'
      } end

      context 'restart_on_change set to false (default)' do
        let(:pre_condition) do
          <<-EOS
            class { "elasticsearch-legacy": }

            elasticsearch-legacy::instance { 'es-plugin': }
          EOS
        end

        it { should_not contain_elasticsearch-legacy_plugin(
          'head'
        ).that_notifies(
          'elasticsearch-legacy::Service[es-plugin]'
        )}

        include_examples 'instance', 'es-plugin', :sysv
      end

      context 'restart_on_change set to true' do
        let(:pre_condition) do
          <<-EOS
            class { "elasticsearch-legacy":
              restart_on_change => true,
            }

            elasticsearch-legacy::instance { 'es-plugin': }
          EOS
        end

        it { should contain_elasticsearch-legacy_plugin(
          'head'
        ).that_notifies(
          'elasticsearch-legacy::Service[es-plugin]'
        )}

        include_examples 'instance', 'es-plugin', :sysv
      end

      context 'restart_plugin_change set to false (default)' do
        let(:pre_condition) do
          <<-EOS
            class { "elasticsearch-legacy":
              restart_plugin_change => false,
            }

            elasticsearch-legacy::instance { 'es-plugin': }
          EOS
        end

        it { should_not contain_elasticsearch-legacy_plugin(
          'head'
        ).that_notifies(
          'elasticsearch-legacy::Service[es-plugin]'
        )}

        include_examples 'instance', 'es-plugin', :sysv
      end

      context 'restart_plugin_change set to true' do
        let(:pre_condition) do
          <<-EOS
            class { "elasticsearch-legacy":
              restart_plugin_change => true,
            }

            elasticsearch-legacy::instance { 'es-plugin': }
          EOS
        end

        it { should contain_elasticsearch-legacy_plugin(
          'head'
        ).that_notifies(
          'elasticsearch-legacy::Service[es-plugin]'
        )}

        include_examples 'instance', 'es-plugin', :sysv
      end
    end

    describe 'proxy arguments' do
      let(:title) { 'head' }

      context 'unauthenticated' do
        context 'on define' do
          let(:params) do {
            :ensure         => 'present',
            :instances      => 'es-plugin',
            :proxy_host     => 'es.local',
            :proxy_port     => 8080
          } end

          it { should contain_elasticsearch-legacy_plugin(
            'head'
          ).with_proxy(
            'http://es.local:8080'
          )}
        end

        context 'on main class' do
          let(:params) do {
            :ensure    => 'present',
            :instances => 'es-plugin'
          } end

          let(:pre_condition) do
            <<-EOS
              class { 'elasticsearch-legacy':
                proxy_url => 'https://es.local:8080',
              }
            EOS
          end

          it { should contain_elasticsearch-legacy_plugin(
            'head'
          ).with_proxy(
            'https://es.local:8080'
          )}
        end
      end

      context 'authenticated' do
        context 'on define' do
          let(:params) do {
            :ensure         => 'present',
            :instances      => 'es-plugin',
            :proxy_host     => 'es.local',
            :proxy_port     => 8080,
            :proxy_username => 'elastic',
            :proxy_password => 'password'
          } end

          it { should contain_elasticsearch-legacy_plugin(
            'head'
          ).with_proxy(
            'http://elastic:password@es.local:8080'
          )}
        end

        context 'on main class' do
          let(:params) do {
            :ensure    => 'present',
            :instances => 'es-plugin'
          } end

          let(:pre_condition) do
            <<-EOS
              class { 'elasticsearch-legacy':
                proxy_url => 'http://elastic:password@es.local:8080',
              }
            EOS
          end

          it { should contain_elasticsearch-legacy_plugin(
            'head'
          ).with_proxy(
            'http://elastic:password@es.local:8080'
          )}
        end
      end
    end

    describe 'collector ordering' do
      describe 'present' do
        let(:title) { 'head' }
        let(:pre_condition) do
          <<-EOS
            class { 'elasticsearch-legacy': }
            elasticsearch-legacy::instance { 'es-plugin': }
          EOS
        end

        let(:params) do {
          :instances => 'es-plugin'
        } end

        it { should contain_elasticsearch-legacy__plugin(
          'head'
        ).that_comes_before(
          'elasticsearch-legacy::Instance[es-plugin]'
        )}

        include_examples 'instance', 'es-plugin', :sysv
      end
    end
  end
end

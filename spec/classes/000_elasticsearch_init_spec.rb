require 'spec_helper'

describe 'elasticsearch-legacy', :type => 'class' do
  default_params = {
    :config => { 'node.name' => 'foo' }
  }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      case facts[:os]['family']
      when 'Debian'
        let(:defaults_path) { '/etc/default' }
        let(:system_service_folder) { '/lib/systemd/system' }
        let(:pkg_ext) { 'deb' }
        let(:pkg_prov) { 'dpkg' }
        let(:version_add) { '' }
        if (facts[:os]['name'] == 'Debian' and \
           facts[:os]['release']['major'].to_i >= 8) or \
           (facts[:os]['name'] == 'Ubuntu' and \
           facts[:os]['release']['major'].to_i >= 15)
          let(:systemd_service_path) { '/lib/systemd/system' }
          test_pid = true
        else
          test_pid = false
        end
      when 'RedHat'
        let(:defaults_path) { '/etc/sysconfig' }
        let(:system_service_folder) { '/lib/systemd/system' }
        let(:pkg_ext) { 'rpm' }
        let(:pkg_prov) { 'rpm' }
        let(:version_add) { '-1' }
        if facts[:os]['release']['major'].to_i >= 7
          let(:systemd_service_path) { '/lib/systemd/system' }
          test_pid = true
        else
          test_pid = false
        end
      when 'Suse'
        let(:defaults_path) { '/etc/sysconfig' }
        let(:pkg_ext) { 'rpm' }
        let(:pkg_prov) { 'rpm' }
        let(:version_add) { '-1' }
        if facts[:os]['name'] == 'OpenSuSE' and
           facts[:os]['release']['major'].to_i <= 12
          let(:systemd_service_path) { '/lib/systemd/system' }
        else
          let(:systemd_service_path) { '/usr/lib/systemd/system' }
        end
      end

      let(:facts) do
        facts.merge('scenario' => '', 'common' => '')
      end

      let(:params) do
        default_params.merge({})
      end

      # Varies depending on distro
      it { should contain_augeas("#{defaults_path}/elasticsearch-legacy") }

      # Systemd-specific files
      if test_pid == true
        it { should contain_service('elasticsearch-legacy').with(:enable => 'mask') }
        it { should contain_file('/usr/lib/tmpfiles.d/elasticsearch-legacy.conf') }
      end

      context 'java installation' do
        let(:pre_condition) do
          <<~EOS
            include ::java
          EOS
        end

        it { should contain_class('elasticsearch-legacy::config')
          .that_requires('Class[java]') }
      end

      context 'package installation' do
        context 'via repository' do
          context 'with specified version' do
            let(:params) do
              default_params.merge(
                :version => '1.0'
              )
            end

            it { should contain_package('elasticsearch-legacy')
              .with(:ensure => "1.0#{version_add}") }
          end

          if facts[:os]['family'] == 'RedHat'
            context 'Handle special CentOS/RHEL package versioning' do
              let(:params) do
                default_params.merge(
                  :version => '1.1-2'
                )
              end

              it { should contain_package('elasticsearch-legacy')
                .with(:ensure => '1.1-2') }
            end
          end
        end

        context 'when setting package version and package_url' do
          let(:params) do
            default_params.merge(
              :version     => '0.90.10',
              :package_url => "puppet:///path/to/some/es-0.90.10.#{pkg_ext}"
            )
          end

          it { expect { should raise_error(Puppet::Error) } }
        end

        context 'via package_url setting' do
          ['file:/', 'ftp://', 'http://', 'https://', 'puppet:///'].each do |schema|
            context "using #{schema} schema" do
              let(:params) do
                default_params.merge(
                  :package_url => "#{schema}domain-or-path/pkg.#{pkg_ext}"
                )
              end

              unless schema.start_with? 'puppet'
                it { should contain_exec('create_package_dir_elasticsearch-legacy')
                  .with(:command => 'mkdir -p /opt/elasticsearch-legacy/swdl') }
                it { should contain_file('/opt/elasticsearch-legacy/swdl')
                  .with(
                    :purge => false,
                    :force => false,
                    :require => 'Exec[create_package_dir_elasticsearch-legacy]'
                  ) }
              end

              case schema
              when 'file:/'
                it { should contain_file(
                  "/opt/elasticsearch-legacy/swdl/pkg.#{pkg_ext}"
                ).with(
                  :source => "/domain-or-path/pkg.#{pkg_ext}",
                  :backup => false
                ) }
              when 'puppet:///'
                it { should contain_file(
                  "/opt/elasticsearch-legacy/swdl/pkg.#{pkg_ext}"
                ).with(
                  :source => "#{schema}domain-or-path/pkg.#{pkg_ext}",
                  :backup => false
                ) }
              else
                it { should contain_exec('download_package_elasticsearch-legacy')
                  .with(
                    :command => "wget --no-check-certificate -O /opt/elasticsearch-legacy/swdl/pkg.#{pkg_ext} #{schema}domain-or-path/pkg.#{pkg_ext} 2> /dev/null",
                    :require => 'File[/opt/elasticsearch-legacy/swdl]'
                  ) }
              end

              it { should contain_package('elasticsearch-legacy')
                .with(
                  :ensure => 'present',
                  :source => "/opt/elasticsearch-legacy/swdl/pkg.#{pkg_ext}",
                  :provider => pkg_prov
                ) }
            end
          end

          context 'using http:// schema with proxy_url' do
            let(:params) do
              default_params.merge(
                :package_url => "http://www.domain.com/package.#{pkg_ext}",
                :proxy_url   => 'http://proxy.example.com:12345/'
              )
            end

            it { should contain_exec('download_package_elasticsearch-legacy')
              .with(
                :environment => [
                  'use_proxy=yes',
                  'http_proxy=http://proxy.example.com:12345/',
                  'https_proxy=http://proxy.example.com:12345/'
                ]
              ) }
          end
        end
      end # package

      context 'when setting the module to absent' do
        let(:params) do
          default_params.merge(
            :ensure => 'absent'
          )
        end

        case facts[:os]['family']
        when 'Suse'
          it { should contain_package('elasticsearch-legacy')
            .with(:ensure => 'absent') }
        else
          it { should contain_package('elasticsearch-legacy')
            .with(:ensure => 'purged') }
        end

        it { should contain_file('/usr/share/elasticsearch-legacy/plugins')
          .with(:ensure => 'absent') }
      end

      context 'When managing the repository' do
        let(:params) do
          default_params.merge(
            :manage_repo => true,
            :repo_version => '1.0'
          )
        end

        case facts[:os]['family']
        when 'Debian'
          it { should contain_class('elasticsearch-legacy::repo') }
          it { should contain_class('apt') }
          it { should contain_apt__source('elasticsearch-legacy')
            .with(
              :release => 'stable',
              :repos => 'main',
              :location => 'http://packages.elastic.co/elasticsearch-legacy/1.0/debian'
            ) }
        when 'RedHat'
          it { should contain_class('elasticsearch-legacy::repo') }
          it { should contain_yumrepo('elasticsearch-legacy')
            .with(
              :baseurl => 'http://packages.elastic.co/elasticsearch-legacy/1.0/centos',
              :gpgkey  => 'https://artifacts.elastic.co/GPG-KEY-elasticsearch-legacy',
              :enabled => 1
            ) }
          it { should contain_exec('elasticsearch-legacy_yumrepo_yum_clean') }
        when 'SuSE'
          it { should contain_class('elasticsearch-legacy::repo') }
          it { should contain_exec('elasticsearch-legacy_suse_import_gpg') }
          it { should contain_zypprepo('elasticsearch-legacy')
            .with(
              :baseurl => 'http://packages.elastic.co/elasticsearch-legacy/1.0/centos') }
          it { should contain_exec(
            'elasticsearch-legacy_zypper_refresh_elasticsearch-legacy'
          ) }
        end
      end

      context 'repository priority pinning' do
        let(:params) do
          default_params.merge(
            :manage_repo => true,
            :repo_priority => 10,
            :repo_version => '2.x'
          )
        end

        case facts[:os]['family']
        when 'Debian'
          context 'is supported' do
            it { should contain_apt__source('elasticsearch-legacy').with(
              :pin => 10
            ) }
          end
        when 'RedHat'
          context 'is supported' do
            it { should contain_yumrepo('elasticsearch-legacy').with(
              :priority => 10
            ) }
          end
        end
      end
    end
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

      context 'main class tests' do
        # init.pp
        it { should compile.with_all_deps }
        it { should contain_class('elasticsearch-legacy') }
        it { should contain_class('elasticsearch-legacy::package') }
        it { should contain_class('elasticsearch-legacy::config')
          .that_requires('Class[elasticsearch-legacy::package]') }

        # Base directories
        it { should contain_file('/etc/elasticsearch-legacy') }
        it { should contain_file('/usr/share/elasticsearch-legacy/templates_import') }
        it { should contain_file('/usr/share/elasticsearch-legacy/scripts') }
        it { should contain_file('/usr/share/elasticsearch-legacy') }
        it { should contain_file('/usr/share/elasticsearch-legacy/lib') }

        it { should contain_exec('remove_plugin_dir') }

        # file removal from package
        it { should contain_file('/etc/init.d/elasticsearch-legacy')
          .with(:ensure => 'absent') }
        it { should contain_file('/etc/elasticsearch-legacy/elasticsearch-legacy.yml')
          .with(:ensure => 'absent') }
        it { should contain_file('/etc/elasticsearch-legacy/jvm.options')
            .with(:ensure => 'absent') }
        it { should contain_file('/etc/elasticsearch-legacy/logging.yml')
          .with(:ensure => 'absent') }
        it { should contain_file('/etc/elasticsearch-legacy/log4j2.properties')
          .with(:ensure => 'absent') }
        it { should contain_file('/etc/elasticsearch-legacy/log4j2.properties')
          .with(:ensure => 'absent') }
      end

      context 'package installation' do
        context 'with default package' do
          it { should contain_package('elasticsearch-legacy')
            .with(:ensure => 'present') }
          it { should_not contain_package('my-elasticsearch-legacy')
            .with(:ensure => 'present') }
        end

        context 'with specified package name' do
          let(:params) do
            default_params.merge(
              :package_name => 'my-elasticsearch-legacy'
            )
          end

          it { should contain_package('my-elasticsearch-legacy')
            .with(:ensure => 'present') }
          it { should_not contain_package('elasticsearch-legacy')
            .with(:ensure => 'present') }
        end

        context 'with auto upgrade enabled' do
          let(:params) do
            default_params.merge(
              :autoupgrade => true
            )
          end

          it { should contain_package('elasticsearch-legacy')
            .with(:ensure => 'latest') }
        end
      end

      context 'when not supplying a repo_version' do
        let(:params) do
          default_params.merge(
            :manage_repo => true
          )
        end

        it { expect { should raise_error(
          Puppet::Error, 'Please fill in a repository version at $repo_version'
        ) } }
      end

      context 'running a a different user' do
        let(:params) do
          default_params.merge(
            :elasticsearch-legacy_user => 'myesuser',
            :elasticsearch-legacy_group => 'myesgroup'
          )
        end

        it { should contain_file('/etc/elasticsearch-legacy')
          .with(:owner => 'myesuser', :group => 'myesgroup') }
        it { should contain_file('/var/log/elasticsearch-legacy')
          .with(:owner => 'myesuser') }
        it { should contain_file('/usr/share/elasticsearch-legacy')
          .with(:owner => 'myesuser', :group => 'myesgroup') }
        it { should contain_file('/var/lib/elasticsearch-legacy')
          .with(:owner => 'myesuser', :group => 'myesgroup') }
        it { should contain_file('/var/run/elasticsearch-legacy')
          .with(:owner => 'myesuser') if facts[:os]['family'] == 'RedHat' }
      end

      # This check helps catch dependency cycles.
      context 'create_resource' do
        # Helper for these tests
        def singular(s)
          s == 'indices' ? 'index' : s[0..-2]
        end
        {
          'indices' => { 'test-index' => {} },
          'instances' => { 'es-instance' => {} },
          'pipelines' => { 'testpipeline' => { 'content' => {} } },
          'plugins' => { 'head' => {} },
          'roles' => { 'elastic_role' => {} },
          'scripts' => {
            'foo' => { 'source' => 'puppet:///path/to/foo.groovy' }
          },
          'templates' => { 'foo' => { 'content' => {} } },
          'users' => { 'elastic' => { 'password' => 'foobar' } }
        }.each_pair do |deftype, params|
          describe deftype do
            let(:params) do
              default_params.merge(
                deftype => params,
                :security_plugin => 'x-pack'
              )
            end
            it { should compile }
            it { should send(
              "contain_elasticsearch-legacy__#{singular(deftype)}", params.keys.first
            ) }
          end
        end
      end
    end
  end
end

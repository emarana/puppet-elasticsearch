require 'spec_helper_acceptance'
require 'json'

shared_examples 'plugin behavior' do |version, user, plugin, offline, config|
  describe "plugin operations on #{version}" do
    context 'official repo', :with_cleanup do
      describe 'manifest' do
        pp = <<-EOS
          class { 'elasticsearch-legacy':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'cluster.name' => '#{test_settings['cluster_name']}',
              'network.host' => '0.0.0.0',
            },
            #{config}
            restart_on_change => true,
          }

          elasticsearch-legacy::instance { 'es-01':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'http.port' => '#{test_settings['port_a']}'
            }
          }

          elasticsearch-legacy::plugin { 'mobz/elasticsearch-legacy-head':
             instances => 'es-01'
          }
        EOS

        it 'applies cleanly ' do
          apply_manifest pp, :catch_failures => true
        end
        it 'is idempotent' do
          apply_manifest pp, :catch_changes => true
        end
      end

      describe file('/usr/share/elasticsearch-legacy/plugins/head/') do
        it { should be_directory }
      end

      describe port(test_settings['port_a']) do
        it 'open', :with_retries do
          should be_listening
        end
      end

      describe server :container do
        describe http(
          "http://localhost:#{test_settings['port_a']}/_cluster/stats"
        ) do
          it 'reports the plugin as installed', :with_retries do
            plugins = JSON.parse(response.body)['nodes']['plugins'].map do |h|
              h['name']
            end
            expect(plugins).to include('head')
          end
        end
      end
    end

    # Pending
    context 'custom git repo' do
      describe 'manifest'
      describe file('/usr/share/elasticsearch-legacy/plugins/head/')
      describe server :container
    end

    context 'invalid plugin', :with_cleanup do
      describe 'manifest' do
        pp = <<-EOS
          class { 'elasticsearch-legacy':
            config => {
              'node.name' => 'elasticearch001',
              'cluster.name' => '#{test_settings['cluster_name']}',
              'network.host' => '0.0.0.0',
            },
            #{config}
          }

          elasticsearch-legacy::instance { 'es-01':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'http.port' => '#{test_settings['port_a']}'
            }
          }

          elasticsearch-legacy::plugin { 'elasticsearch-legacy/non-existing':
            instances => 'es-01'
          }
        EOS

        it 'fails to apply cleanly' do
          apply_manifest pp, :expect_failures => true
        end
      end
    end

    describe "running ES under #{user} user", :with_cleanup do
      describe 'manifest' do
        pp = <<-EOS
          class { 'elasticsearch-legacy':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'cluster.name' => '#{test_settings['cluster_name']}',
              'network.host' => '0.0.0.0',
            },
            #{config}
            elasticsearch-legacy_user => '#{user}',
            elasticsearch-legacy_group => '#{user}',
            restart_on_change => true,
          }

          elasticsearch-legacy::instance { 'es-01':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'http.port' => '#{test_settings['port_a']}'
            }
          }

          elasticsearch-legacy::plugin { '#{plugin[:prefix]}#{plugin[:name]}/#{plugin[:old]}':
            instances => 'es-01'
          }
        EOS

        it 'applies cleanly ' do
          apply_manifest pp, :catch_failures => true
        end
        it 'is idempotent' do
          apply_manifest pp, :catch_changes => true
        end
      end

      describe file("/usr/share/elasticsearch-legacy/plugins/#{plugin[:name]}/") do
        it { should be_directory }
      end

      describe port(test_settings['port_a']) do
        it 'open', :with_retries do
          should be_listening
        end
      end

      describe server :container do
        describe http(
          "http://localhost:#{test_settings['port_a']}/_cluster/stats"
        ) do
          it 'reports the plugin as installed', :with_retries do
            plugins = JSON.parse(response.body)['nodes']['plugins'].map do |h|
              {
                name: h['name'],
                version: h['version']
              }
            end
            expect(plugins).to include(
              name: plugin[:name],
              version: plugin[:old]
            )
          end
        end
      end
    end

    if version =~ /^1/
      describe 'upgrading', :with_cleanup do
        describe 'manifest' do
          pp = <<-EOS
            class { 'elasticsearch-legacy':
              config => {
                'node.name' => 'elasticsearch-legacy001',
                'cluster.name' => '#{test_settings['cluster_name']}',
                'network.host' => '0.0.0.0',
              },
              #{config}
              elasticsearch-legacy_user => '#{user}',
              elasticsearch-legacy_group => '#{user}',
              restart_on_change => true,
            }

            elasticsearch-legacy::instance { 'es-01':
              config => {
                'node.name' => 'elasticsearch-legacy001',
                'http.port' => '#{test_settings['port_a']}'
              }
            }

            elasticsearch-legacy::plugin { '#{plugin[:prefix]}#{plugin[:name]}/#{plugin[:new]}':
              instances => 'es-01'
            }
          EOS

          it 'applies cleanly ' do
            apply_manifest pp, :catch_failures => true
          end
          it 'is idempotent' do
            apply_manifest pp, :catch_changes => true
          end
        end

        describe port(test_settings['port_a']) do
          it 'open', :with_retries do
            should be_listening
          end
        end

        describe server :container do
          describe http(
            "http://localhost:#{test_settings['port_a']}/_cluster/stats"
          ) do
            it 'reports the upgraded plugin version', :with_retries do
              j = JSON.parse(response.body)['nodes']['plugins'].find do |h|
                h['name'] == plugin[:name]
              end
              expect(j).to include('version' => plugin[:new])
            end
          end
        end
      end
    end

    describe 'offline installation via puppet://', :with_cleanup do
      describe 'manifest' do
        pp = <<-EOS
          class { 'elasticsearch-legacy':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'cluster.name' => '#{test_settings['cluster_name']}',
              'network.host' => '0.0.0.0',
            },
            #{config}
            elasticsearch-legacy_user => '#{user}',
            elasticsearch-legacy_group => '#{user}',
            restart_on_change => true,
          }

          elasticsearch-legacy::instance { 'es-01':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'http.port' => '#{test_settings['port_a']}'
            }
          }

          elasticsearch-legacy::plugin { '#{offline}':
            source => 'puppet:///modules/another/elasticsearch-legacy-#{offline}.zip',
            instances => 'es-01'
          }
        EOS

        it 'applies cleanly ' do
          apply_manifest pp, :catch_failures => true
        end
        it 'is idempotent' do
          apply_manifest pp, :catch_changes => true
        end
      end

      describe port(test_settings['port_a']) do
        it 'open', :with_retries do
          should be_listening
        end
      end

      describe server :container do
        describe http(
          "http://localhost:#{test_settings['port_a']}/_cluster/stats"
        ) do
          it 'reports the plugin as installed', :with_retries do
            plugins = JSON.parse(response.body)['nodes']['plugins']
            expect(plugins.first).to include('name' => offline)
          end
        end
      end
    end

    describe 'installation via url', :with_cleanup do
      describe 'manifest' do
        pp = <<-EOS
          class { 'elasticsearch-legacy':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'cluster.name' => '#{test_settings['cluster_name']}',
              'network.host' => '0.0.0.0',
            },
            #{config}
            restart_on_change => true,
          }

          elasticsearch-legacy::instance { 'es-01':
            config => {
              'node.name' => 'elasticsearch-legacy001',
              'http.port' => '#{test_settings['port_a']}'
            }
          }

          elasticsearch-legacy::plugin { 'hq':
            url => 'https://github.com/royrusso/elasticsearch-legacy-HQ/archive/v2.0.3.zip',
            instances => 'es-01'
          }
        EOS

        it 'applies cleanly ' do
          apply_manifest pp, :catch_failures => true
        end
        it 'is idempotent' do
          apply_manifest pp, :catch_changes => true
        end
      end

      describe port(test_settings['port_a']) do
        it 'open', :with_retries do
          should be_listening
        end
      end

      describe server :container do
        describe http(
          "http://localhost:#{test_settings['port_a']}/_cluster/stats"
        ) do
          it 'reports the plugin as installed', :with_retries do
            plugins = JSON.parse(response.body)['nodes']['plugins'].map do |h|
              h['name']
            end
            expect(plugins).to include('hq')
          end
        end
      end
    end
  end
end

describe 'elasticsearch-legacy::plugin' do
  before :all do
    shell "mkdir -p #{default['distmoduledir']}/another/files"

    shell %W[
      ln -sf /tmp/elasticsearch-legacy-kopf.zip
      #{default['distmoduledir']}/another/files/elasticsearch-legacy-kopf.zip
    ].join(' ')
  end

  include_examples 'plugin behavior',
                   test_settings['repo_version2x'],
                   'elasticsearch-legacy',
                   {
                     prefix: 'lmenezes/elasticsearch-legacy-',
                     name: 'kopf',
                     old: '2.0.1',
                     new: '2.1.1'
                   },
                   'kopf',
                   <<-EOS
                     repo_version => '#{test_settings['repo_version2x']}',
                     version => '2.0.0',
                   EOS
end

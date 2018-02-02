require 'spec_helper_acceptance'

describe 'elasticsearch-legacy::elasticsearch-legacy_user', :then_purge do
  describe 'changing service user', :with_cleanup do
    describe 'manifest' do
      pp = <<-EOS
        user { 'esuser':
          ensure => 'present',
          groups => ['esgroup', 'esuser']
        }
        group { 'esuser': ensure => 'present' }
        group { 'esgroup': ensure => 'present' }

        class { 'elasticsearch-legacy':
          config => {
            'cluster.name' => '#{test_settings['cluster_name']}',
            'network.host' => '0.0.0.0',
          },
          repo_version => '#{test_settings['repo_version']}',
          elasticsearch-legacy_user => 'esuser',
          elasticsearch-legacy_group => 'esgroup'
        }

        elasticsearch-legacy::instance { 'es-01':
          config => {
            'node.name' => 'elasticsearch-legacy001',
            'http.port' => '#{test_settings['port_a']}'
          }
        }
      EOS

      it 'applies cleanly ' do
        apply_manifest pp, :catch_failures => true
      end
      it 'is idempotent' do
        apply_manifest pp, :catch_changes => true
      end
    end

    describe service(test_settings['service_name_a']) do
      it { should be_enabled }
      it { should be_running }
    end

    describe file('/etc/elasticsearch-legacy/es-01/elasticsearch-legacy.yml') do
      it { should be_file }
      it { should be_owned_by 'esuser' }
      it { should contain 'name: elasticsearch-legacy001' }
    end

    describe file('/usr/share/elasticsearch-legacy') do
      it { should be_directory }
      it { should be_owned_by 'esuser' }
    end

    describe file('/var/log/elasticsearch-legacy') do
      it { should be_directory }
      it { should be_owned_by 'esuser' }
    end

    describe file('/etc/elasticsearch-legacy') do
      it { should be_directory }
      it { should be_owned_by 'esuser' }
    end

    describe port(test_settings['port_a']) do
      it 'open', :with_retries do
        should be_listening
      end
    end

    describe server :container do
      describe http(
        "http://localhost:#{test_settings['port_a']}"
      ) do
        describe 'instance a' do
          it 'serves requests', :with_retries do
            expect(response.status).to eq(200)
          end
        end
      end
    end
  end
end

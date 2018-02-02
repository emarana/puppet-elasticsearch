require 'spec_helper_acceptance'
require 'json'

describe '::elasticsearch-legacy' do
  describe 'single instance' do
    describe 'manifest' do
      pp = <<-EOS
        class { 'elasticsearch-legacy':
          config => {
            'cluster.name' => '#{test_settings['cluster_name']}',
            'network.host' => '0.0.0.0',
          },
          repo_version => '#{test_settings['repo_version']}',
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

    describe package(test_settings['package_name']) do
      it { should be_installed }
    end

    describe file(test_settings['pid_a']) do
      it { should be_file }
      its(:content) { should match(/[0-9]+/) }
    end

    describe file('/etc/elasticsearch-legacy/es-01/elasticsearch-legacy.yml') do
      it { should be_file }
      it { should contain 'name: elasticsearch-legacy001' }
      it { should contain '/var/lib/elasticsearch-legacy/es-01' }
    end

    describe file('/usr/share/elasticsearch-legacy/templates_import') do
      it { should be_directory }
    end

    describe file('/var/lib/elasticsearch-legacy/es-01') do
      it { should be_directory }
    end

    describe file('/usr/share/elasticsearch-legacy/scripts') do
      it { should be_directory }
    end

    describe file('/etc/elasticsearch-legacy/es-01/scripts') do
      it { should be_symlink }
    end

    describe port(test_settings['port_a']) do
      it 'open', :with_retries do
        should be_listening
      end
    end

    describe server :container do
      describe http(
        "http://localhost:#{test_settings['port_a']}/_nodes/_local"
      ) do
        it 'serves requests', :with_retries do
          expect(response.status).to eq(200)
        end

        it 'uses the default data path' do
          json = JSON.parse(response.body)['nodes'].values.first
          expect(
            json['settings']['path']
          ).to include(
            'data' => '/var/lib/elasticsearch-legacy/es-01'
          )
        end
      end
    end
  end

  describe 'multiple instances' do
    it 'should run successfully' do
      pp = <<-EOS
        class { 'elasticsearch-legacy':
          config => {
            'cluster.name' => '#{test_settings['cluster_name']}',
            'network.host' => '0.0.0.0',
          },
          repo_version => '#{test_settings['repo_version']}',
        }

        elasticsearch-legacy::instance { 'es-01':
          config => {
            'node.name' => 'elasticsearch-legacy001',
            'http.port' => '#{test_settings['port_a']}'
          }
        }

        elasticsearch-legacy::instance { 'es-02':
          config => {
            'node.name' => 'elasticsearch-legacy002',
            'http.port' => '#{test_settings['port_b']}'
          }
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest pp, :catch_failures => true
      apply_manifest pp, :catch_changes => true
    end

    describe service(test_settings['service_name_a']) do
      it { should be_enabled }
      it { should be_running }
    end

    describe service(test_settings['service_name_b']) do
      it { should be_enabled }
      it { should be_running }
    end

    describe package(test_settings['package_name']) do
      it { should be_installed }
    end

    describe file(test_settings['pid_a']) do
      it { should be_file }
      its(:content) { should match(/[0-9]+/) }
    end

    describe file(test_settings['pid_b']) do
      it { should be_file }
      its(:content) { should match(/[0-9]+/) }
    end

    describe port(test_settings['port_a']) do
      it 'open', :with_retries do
        should be_listening
      end
    end
    describe port(test_settings['port_b']) do
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

      describe http(
        "http://localhost:#{test_settings['port_b']}"
      ) do
        describe 'instance b' do
          it 'serves requests', :with_retries do
            expect(response.status).to eq(200)
          end
        end
      end
    end

    describe file('/etc/elasticsearch-legacy/es-01/elasticsearch-legacy.yml') do
      it { should be_file }
      it { should contain 'name: elasticsearch-legacy001' }
    end

    describe file('/etc/elasticsearch-legacy/es-02/elasticsearch-legacy.yml') do
      it { should be_file }
      it { should contain 'name: elasticsearch-legacy002' }
    end
  end

  describe 'module removal' do
    it 'should run successfully' do
      pp = <<-EOS
        class { 'elasticsearch-legacy': ensure => 'absent' }
        elasticsearch-legacy::instance { 'es-01': ensure => 'absent' }
        elasticsearch-legacy::instance { 'es-02': ensure => 'absent' }
      EOS

      apply_manifest pp, :catch_failures => true
    end

    describe file('/etc/elasticsearch-legacy/es-01') do
      it { should_not be_directory }
    end

    describe file('/etc/elasticsearch-legacy/es-02') do
      it { should_not be_directory }
    end

    describe file('/etc/elasticsearch-legacy/es-03') do
      it { should_not be_directory }
    end

    describe service(test_settings['service_name_a']) do
      it { should_not be_enabled }
      it { should_not be_running }
    end

    describe service(test_settings['service_name_b']) do
      it { should_not be_enabled }
      it { should_not be_running }
    end
  end
end

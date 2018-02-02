shared_examples 'instance' do |name, init|
  it { should contain_elasticsearch-legacy__instance(name) }
  it { should contain_augeas("defaults_#{name}") }
  it { should contain_datacat("/etc/elasticsearch-legacy/#{name}/elasticsearch-legacy.yml") }
  it { should contain_datacat_fragment("main_config_#{name}") }
  it { should contain_elasticsearch-legacy__instance(name) }
  it { should contain_elasticsearch-legacy__service(name) }
  it { should contain_exec("mkdir_configdir_elasticsearch-legacy_#{name}") }
  it { should contain_exec("mkdir_datadir_elasticsearch-legacy_#{name}")
    .with(:command => "mkdir -p /var/lib/elasticsearch-legacy/#{name}") }
  it { should contain_exec("mkdir_logdir_elasticsearch-legacy_#{name}")
    .with(:command => "mkdir -p /var/log/elasticsearch-legacy/#{name}") }
  it { should contain_elasticsearch-legacy__service(name) }
  it { should contain_service("elasticsearch-legacy-instance-#{name}") }

  %w[/var/log/elasticsearch-legacy /var/lib/elasticsearch-legacy /etc/elasticsearch-legacy].each do |dir|
    it { should contain_file("#{dir}/#{name}").with(:ensure => 'directory') }
  end

  %w[elasticsearch-legacy.yml jvm.options logging.yml log4j2.properties scripts].each do |file|
    it { should contain_file("/etc/elasticsearch-legacy/#{name}/#{file}") }
  end

  case init
  when :sysv
    it { should contain_elasticsearch-legacy__service__init(name) }
    it { should contain_elasticsearch-legacy_service_file("/etc/init.d/elasticsearch-legacy-#{name}") }
    it { should contain_file("/etc/init.d/elasticsearch-legacy-#{name}") }
  when :systemd
    it { should contain_elasticsearch-legacy__service__systemd(name) }
    it { should contain_elasticsearch-legacy_service_file("/lib/systemd/system/elasticsearch-legacy-#{name}.service") }
    it { should contain_file("/lib/systemd/system/elasticsearch-legacy-#{name}.service") }
    it { should contain_exec("systemd_reload_#{name}") }
  end
end

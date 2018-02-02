# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
# @example importing this class into other classes to use its functionality:
#   class { 'elasticsearch-legacy::config': }
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch-legacy.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class elasticsearch-legacy::config {

  #### Configuration

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if ( $elasticsearch-legacy::ensure == 'present' ) {

    file {
      $elasticsearch-legacy::configdir:
        ensure => 'directory',
        group  => $elasticsearch-legacy::elasticsearch-legacy_group,
        owner  => $elasticsearch-legacy::elasticsearch-legacy_user,
        mode   => '0755';
      $elasticsearch-legacy::datadir:
        ensure => 'directory',
        group  => $elasticsearch-legacy::elasticsearch-legacy_group,
        owner  => $elasticsearch-legacy::elasticsearch-legacy_user;
      $elasticsearch-legacy::logdir:
        ensure  => 'directory',
        group   => undef,
        owner   => $elasticsearch-legacy::elasticsearch-legacy_user,
        mode    => '0755',
        recurse => true;
      $elasticsearch-legacy::plugindir:
        ensure => 'directory',
        group  => $elasticsearch-legacy::elasticsearch-legacy_group,
        owner  => $elasticsearch-legacy::elasticsearch-legacy_user,
        mode   => 'o+Xr';
      "${elasticsearch-legacy::homedir}/lib":
        ensure  => 'directory',
        group   => '0',
        owner   => 'root',
        recurse => true;
      $elasticsearch-legacy::homedir:
        ensure => 'directory',
        group  => $elasticsearch-legacy::elasticsearch-legacy_group,
        owner  => $elasticsearch-legacy::elasticsearch-legacy_user;
      "${elasticsearch-legacy::homedir}/templates_import":
        ensure => 'directory',
        group  => $elasticsearch-legacy::elasticsearch-legacy_group,
        owner  => $elasticsearch-legacy::elasticsearch-legacy_user,
        mode   => '0755';
      "${elasticsearch-legacy::homedir}/scripts":
        ensure => 'directory',
        group  => $elasticsearch-legacy::elasticsearch-legacy_group,
        owner  => $elasticsearch-legacy::elasticsearch-legacy_user,
        mode   => '0755';
      '/etc/elasticsearch-legacy/elasticsearch-legacy.yml':
        ensure => 'absent';
      '/etc/elasticsearch-legacy/jvm.options':
        ensure => 'absent';
      '/etc/elasticsearch-legacy/logging.yml':
        ensure => 'absent';
      '/etc/elasticsearch-legacy/log4j2.properties':
        ensure => 'absent';
      '/etc/init.d/elasticsearch-legacy':
        ensure => 'absent';
    }

    if $elasticsearch-legacy::pid_dir {
      file { $elasticsearch-legacy::pid_dir:
        ensure  => 'directory',
        group   => undef,
        owner   => $elasticsearch-legacy::elasticsearch-legacy_user,
        recurse => true,
      }

      if ($elasticsearch-legacy::service_provider == 'systemd') {
        $group = $elasticsearch-legacy::elasticsearch-legacy_group
        $user = $elasticsearch-legacy::elasticsearch-legacy_user
        $pid_dir = $elasticsearch-legacy::pid_dir

        file { '/usr/lib/tmpfiles.d/elasticsearch-legacy.conf':
          ensure  => 'file',
          content => template("${module_name}/usr/lib/tmpfiles.d/elasticsearch-legacy.conf.erb"),
          group   => '0',
          owner   => 'root',
        }
      }
    }

    if ($elasticsearch-legacy::service_provider == 'systemd') {
      # Mask default unit (from package)
      service { 'elasticsearch-legacy' :
        enable => 'mask',
      }
    }

    if $elasticsearch-legacy::defaults_location {
      augeas { "${elasticsearch-legacy::defaults_location}/elasticsearch-legacy":
        incl    => "${elasticsearch-legacy::defaults_location}/elasticsearch-legacy",
        lens    => 'Shellvars.lns',
        changes => [
          'rm CONF_FILE',
          'rm CONF_DIR',
          'rm ES_PATH_CONF',
        ],
      }
    }

    if $::elasticsearch-legacy::security_plugin != undef and ($::elasticsearch-legacy::security_plugin in ['shield', 'x-pack']) {
      file { "/etc/elasticsearch-legacy/${::elasticsearch-legacy::security_plugin}" :
        ensure => 'directory',
      }
    }

    # Define logging config file for the in-use security plugin
    if $::elasticsearch-legacy::security_logging_content != undef or $::elasticsearch-legacy::security_logging_source != undef {
      if $::elasticsearch-legacy::security_plugin == undef or ! ($::elasticsearch-legacy::security_plugin in ['shield', 'x-pack']) {
        fail("\"${::elasticsearch-legacy::security_plugin}\" is not a valid security_plugin parameter value")
      }

      $_security_logging_file = $::elasticsearch-legacy::security_plugin ? {
        'shield' => 'logging.yml',
        default => 'log4j2.properties'
      }

      file { "/etc/elasticsearch-legacy/${::elasticsearch-legacy::security_plugin}/${_security_logging_file}" :
        content => $::elasticsearch-legacy::security_logging_content,
        source  => $::elasticsearch-legacy::security_logging_source,
      }
    }

  } elsif ( $elasticsearch-legacy::ensure == 'absent' ) {

    file { $elasticsearch-legacy::plugindir:
      ensure => 'absent',
      force  => true,
      backup => false,
    }

    file { "${elasticsearch-legacy::configdir}/jvm.options":
      ensure => 'absent',
    }

  }

}

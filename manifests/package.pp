# This class exists to coordinate all software package management related
# actions, functionality and logical units in a central place.
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
# @example importing this class by other classes to use its functionality:
#   class { 'elasticsearch-legacy::package': }
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch-legacy.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class elasticsearch-legacy::package {

  Exec {
    path      => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd       => '/',
    tries     => 3,
    try_sleep => 10,
  }

  if $elasticsearch-legacy::ensure == 'present' {

    if $elasticsearch-legacy::restart_package_change {
      Package[$elasticsearch-legacy::package_name] ~> elasticsearch-legacy::Service <| |>
    }
    Package[$elasticsearch-legacy::package_name] ~> Exec['remove_plugin_dir']

    # Create directory to place the package file
    $package_dir = $elasticsearch-legacy::package_dir
    exec { 'create_package_dir_elasticsearch-legacy':
      cwd     => '/',
      path    => ['/usr/bin', '/bin'],
      command => "mkdir -p ${package_dir}",
      creates => $package_dir,
    }

    file { $package_dir:
      ensure  => 'directory',
      purge   => $elasticsearch-legacy::purge_package_dir,
      force   => $elasticsearch-legacy::purge_package_dir,
      backup  => false,
      require => Exec['create_package_dir_elasticsearch-legacy'],
    }

    # Check if we want to install a specific version or not
    if $elasticsearch-legacy::version == false {

      $package_ensure = $elasticsearch-legacy::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }

    } else {

      # install specific version
      $package_ensure = $elasticsearch-legacy::pkg_version

    }

    # action
    if ($elasticsearch-legacy::package_url != undef) {

      case $elasticsearch-legacy::package_provider {
        'package': { $before = Package[$elasticsearch-legacy::package_name]  }
        default:   { fail("software provider \"${elasticsearch-legacy::package_provider}\".") }
      }


      $filename_array = split($elasticsearch-legacy::package_url, '/')
      $basefilename = $filename_array[-1]

      $source_array = split($elasticsearch-legacy::package_url, ':')
      $protocol_type = $source_array[0]

      $ext_array = split($basefilename, '\.')
      $ext = $ext_array[-1]

      $pkg_source = "${package_dir}/${basefilename}"

      case $protocol_type {

        'puppet': {

          file { $pkg_source:
            ensure  => file,
            source  => $elasticsearch-legacy::package_url,
            require => File[$package_dir],
            backup  => false,
            before  => $before,
          }

        }
        'ftp', 'https', 'http': {

          if $elasticsearch-legacy::proxy_url != undef {
            $exec_environment = [
              'use_proxy=yes',
              "http_proxy=${elasticsearch-legacy::proxy_url}",
              "https_proxy=${elasticsearch-legacy::proxy_url}",
            ]
          } else {
            $exec_environment = []
          }

          case $elasticsearch-legacy::download_tool {
            String: {
              exec { 'download_package_elasticsearch-legacy':
                command     => "${elasticsearch-legacy::download_tool} ${pkg_source} ${elasticsearch-legacy::package_url} 2> /dev/null",
                creates     => $pkg_source,
                environment => $exec_environment,
                timeout     => $elasticsearch-legacy::package_dl_timeout,
                require     => File[$package_dir],
                before      => $before,
              }
            }
            default: {
              fail("no \$elasticsearch-legacy::download_tool defined for ${facts['os']['family']}")
            }
          }

        }
        'file': {

          $source_path = $source_array[1]
          file { $pkg_source:
            ensure  => file,
            source  => $source_path,
            require => File[$package_dir],
            backup  => false,
            before  => $before,
          }

        }
        default: {
          fail("Protocol must be puppet, file, http, https, or ftp. You have given \"${protocol_type}\"")
        }
      }

      if ($elasticsearch-legacy::package_provider == 'package') {

        case $ext {
          'deb':   { Package { provider => 'dpkg', source => $pkg_source } }
          'rpm':   { Package { provider => 'rpm', source => $pkg_source } }
          default: { fail("Unknown file extention \"${ext}\".") }
        }

      }

    }

  # Package removal
  } else {

    if ($facts['os']['family'] == 'Suse') {
      Package {
        provider  => 'rpm',
      }
      $package_ensure = 'absent'
    } else {
      $package_ensure = 'purged'
    }

  }

  if ($elasticsearch-legacy::package_provider == 'package') {

    package { $elasticsearch-legacy::package_name:
      ensure => $package_ensure,
    }

    exec { 'remove_plugin_dir':
      refreshonly => true,
      command     => "rm -rf ${elasticsearch-legacy::plugindir}",
    }


  } else {
    fail("\"${elasticsearch-legacy::package_provider}\" is not supported")
  }

}

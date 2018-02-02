# This class exists to install and manage yum and apt repositories
# that contain elasticsearch-legacy official elasticsearch-legacy packages.
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
# @example importing this class to be used by other classes to use its functionality:
#   class { 'elasticsearch-legacy::repo': }
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch-legacy.com>
# @author Phil Fenstermacher <phillip.fenstermacher@gmail.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class elasticsearch-legacy::repo {

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if $elasticsearch-legacy::ensure == 'present' {
    if $::elasticsearch-legacy::repo_baseurl != undef {
      $_baseurl = $::elasticsearch-legacy::repo_baseurl
    } else {
      if versioncmp($elasticsearch-legacy::repo_version, '5.0') >= 0 {
        $_repo_url = 'https://artifacts.elastic.co/packages'
        case $facts['os']['family'] {
          'Debian': {
            $_repo_path = 'apt'
          }
          default: {
            $_repo_path = 'yum'
          }
        }
      } else {
        $_repo_url = 'http://packages.elastic.co/elasticsearch-legacy'
        case $facts['os']['family'] {
          'Debian': {
            $_repo_path = 'debian'
          }
          default: {
            $_repo_path = 'centos'
          }
        }
      }

      $_baseurl = "${_repo_url}/${elasticsearch-legacy::repo_version}/${_repo_path}"
    }
  } else {
    case $facts['os']['family'] {
      'Debian': {
        $_baseurl = undef
      }
      default: {
        $_baseurl = 'absent'
      }
    }
  }

  case $facts['os']['family'] {
    'Debian': {
      include ::apt
      Class['apt::update'] -> Package[$elasticsearch-legacy::package_name]

      apt::source { 'elasticsearch-legacy':
        ensure   => $elasticsearch-legacy::ensure,
        location => $_baseurl,
        release  => 'stable',
        repos    => 'main',
        key      => {
          'id'     => $::elasticsearch-legacy::repo_key_id,
          'source' => $::elasticsearch-legacy::repo_key_source,
        },
        include  => {
          'src' => false,
          'deb' => true,
        },
        pin      => $elasticsearch-legacy::repo_priority,
      }
    }
    'RedHat', 'Linux': {
      yumrepo { 'elasticsearch-legacy':
        ensure   => $elasticsearch-legacy::ensure,
        descr    => 'elasticsearch-legacy repo',
        baseurl  => $_baseurl,
        gpgcheck => 1,
        gpgkey   => $::elasticsearch-legacy::repo_key_source,
        enabled  => 1,
        proxy    => $::elasticsearch-legacy::repo_proxy,
        priority => $elasticsearch-legacy::repo_priority,
      }
      ~> exec { 'elasticsearch-legacy_yumrepo_yum_clean':
        command     => 'yum clean metadata expire-cache --disablerepo="*" --enablerepo="elasticsearch-legacy"',
        refreshonly => true,
        returns     => [0, 1],
      }
    }
    'Suse': {
      if $facts['os']['name'] == 'SLES' and versioncmp($facts['os']['release']['major'], '11') <= 0 {
        # Older versions of SLES do not ship with rpmkeys
        $_import_cmd = "rpm --import ${::elasticsearch-legacy::repo_key_source}"
      } else {
        $_import_cmd = "rpmkeys --import ${::elasticsearch-legacy::repo_key_source}"
      }

      exec { 'elasticsearch-legacy_suse_import_gpg':
        command => $_import_cmd,
        unless  =>
          "test $(rpm -qa gpg-pubkey | grep -i 'D88E42B4' | wc -l) -eq 1",
        notify  => Zypprepo['elasticsearch-legacy'],
      }

      zypprepo { 'elasticsearch-legacy':
        baseurl     => $_baseurl,
        enabled     => 1,
        autorefresh => 1,
        name        => 'elasticsearch-legacy',
        gpgcheck    => 1,
        gpgkey      => $::elasticsearch-legacy::repo_key_source,
        type        => 'yum',
      }
      ~> exec { 'elasticsearch-legacy_zypper_refresh_elasticsearch-legacy':
        command     => 'zypper refresh elasticsearch-legacy',
        refreshonly => true,
      }
    }
    default: {
      fail("\"${module_name}\" provides no repo information for OS family ${facts['os']['family']}")
    }
  }
}

# Manages shield/x-pack users.
#
# @example creates and manage a user with membership in the 'logstash' and 'kibana4' roles.
#   elasticsearch-legacy::user { 'bob':
#     password => 'foobar',
#     roles    => ['logstash', 'kibana4'],
#   }
#
# @param ensure
#   Whether the user should be present or not.
#   Set to `absent` to ensure a user is not installed
#
# @param password
#   Password for the given user. A plaintext password will be managed
#   with the esusers utility and requires a refresh to update, while
#   a hashed password from the esusers utility will be managed manually
#   in the uses file.
#
# @param roles
#   A list of roles to which the user should belong.
#
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
define elasticsearch-legacy::user (
  String                    $password,
  Enum['absent', 'present'] $ensure = 'present',
  Array                     $roles  = [],
) {
  if $elasticsearch-legacy::security_plugin == undef {
    fail("\"${elasticsearch-legacy::security_plugin}\" required")
  }

  if $password =~ /^\$2a\$/ {
    elasticsearch-legacy_user { $name:
      ensure          => $ensure,
      configdir       => $elasticsearch-legacy::configdir,
      hashed_password => $password,
    }
  } else {
    $_provider = $elasticsearch-legacy::security_plugin ? {
      'shield' => 'esusers',
      'x-pack' => 'users',
    }
    elasticsearch-legacy_user { $name:
      ensure    => $ensure,
      configdir => $elasticsearch-legacy::configdir,
      password  => $password,
      provider  => $_provider,
    }
  }

  elasticsearch-legacy_user_roles { $name:
    ensure => $ensure,
    roles  => $roles,
  }
}

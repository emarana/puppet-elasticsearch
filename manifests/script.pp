#  This define allows you to insert, update or delete scripts that are used
#  within elasticsearch-legacy.
#
# @param ensure
#   Controls the state of the script file resource to manage.
#   Values are simply passed through to the `file` resource.
#
# @param recurse
#   Will be passed through to the script file resource.
#
# @param source
#   Puppet source of the script
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch-legacy.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
define elasticsearch-legacy::script (
  String                                     $source,
  String                                     $ensure  = 'present',
  Optional[Variant[Boolean, Enum['remote']]] $recurse = undef,
) {
  if ! defined(Class['elasticsearch-legacy']) {
    fail('You must include the elasticsearch-legacy base class before using defined resources')
  }

  $filename_array = split($source, '/')
  $basefilename = $filename_array[-1]

  file { "${elasticsearch-legacy::homedir}/scripts/${basefilename}":
    ensure  => $ensure,
    source  => $source,
    owner   => $elasticsearch-legacy::elasticsearch-legacy_user,
    group   => $elasticsearch-legacy::elasticsearch-legacy_group,
    recurse => $recurse,
    mode    => '0644',
  }
}

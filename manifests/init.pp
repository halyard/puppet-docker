# @summary Configure Docker containers
#
# @param containers to launch
class docker (
  Hash[String, Hash] $containers = {},
) {
  package { 'docker': }

  -> service { 'docker':
    ensure => running,
    enable => true,
  }

  file { '/etc/systemd/system/container@.service':
    ensure => file,
    source => 'puppet:///modules/docker/container@.service',
  }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      * => $options,
    }
  }
}

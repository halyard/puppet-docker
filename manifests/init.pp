# @summary Configure Docker containers
#
# @param containers to launch
class docker (
  Hash[String, Hash] $containers = {},
) {
  package { 'docker': }

  file { '/etc/docker/daemon.json':
    ensure => file,
    source => 'puppet:///modules/docker/daemon.json',
  }

  -> service { 'docker':
    ensure => running,
    enable => true,
  }

  file { '/etc/systemd/system/container@.service':
    ensure => file,
    source => 'puppet:///modules/docker/container@.service',
  }

  file { '/etc/container':
    ensure => directory,
  }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      * => $options,
    }
  }
}

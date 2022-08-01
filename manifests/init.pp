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

  firewall { '100 masquerade for docker containers':
    chain    => 'POSTROUTING',
    jump     => 'MASQUERADE',
    proto    => 'all',
    outiface => '! docker0',
    iniface  => 'docker0',
    table    => 'nat',
  }

  firewall { '100 forward for docker containers':
    chain    => 'FORWARD',
    action   => 'ACCEPT',
    proto    => 'all',
    outiface => '! docker0',
    iniface  => 'docker0',
  }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      * => $options,
    }
  }
}

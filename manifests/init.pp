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

  firewallchain { 'DOCKER_EXPOSE:nat:IPv4':
    ensure  => present,
  }

  firewall { '100 handle incoming traffic for containers':
    chain    => 'PREROUTING',
    jump     => 'DOCKER_EXPOSE',
    dst_type => 'LOCAL',
    table    => 'nat',
  }

  firewall { '100 handle uturn traffic for containers':
    chain       => 'OUTPUT',
    jump        => 'DOCKER_EXPOSE',
    destination => '! 127.0.0.0/8',
    dst_type    => 'LOCAL',
    table       => 'nat',
  }

  firewall { '100 masquerade for docker containers':
    chain    => 'POSTROUTING',
    jump     => 'MASQUERADE',
    proto    => 'all',
    outiface => '! docker0',
    source   => '172.17.0.0/16',
    table    => 'nat',
  }

  firewall { '100 forward from docker containers':
    chain    => 'FORWARD',
    action   => 'accept',
    proto    => 'all',
    outiface => '! docker0',
    iniface  => 'docker0',
  }

  firewall { '100 forward to docker containers':
    chain    => 'FORWARD',
    action   => 'accept',
    proto    => 'all',
    outiface => 'docker0',
    iniface  => '! docker0',
  }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      * => $options,
    }
  }
}

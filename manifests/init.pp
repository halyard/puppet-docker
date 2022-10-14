# @summary Configure Docker containers
#
# @param containers to launch
# @param data_root for storing docker images / volumes
# @param bridge_subnet sets the subnet used for the docker bridge
# @param default_bridge controls whether Docker creates a default bridge for containers
class docker (
  Hash[String, Hash] $containers = {},
  String $data_root = '/var/lib/docker',
  String $bridge_subnet = '172.17.0.0/16',
  String $default_bridge = 'none',
) {
  package { 'docker': }

  -> file { $data_root:
    ensure => directory,
    owner  => root,
    group  => root,
  }

  -> file { '/etc/docker/daemon.json':
    ensure  => file,
    content => template('docker/daemon.json.erb'),
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
    outiface => '! docker1',
    source   => '172.17.0.0/16',
    table    => 'nat',
  }

  firewall { '100 forward from docker containers':
    chain    => 'FORWARD',
    action   => 'accept',
    proto    => 'all',
    outiface => '! docker1',
    iniface  => 'docker1',
  }

  firewall { '100 forward to docker containers':
    chain    => 'FORWARD',
    action   => 'accept',
    proto    => 'all',
    outiface => 'docker1',
    iniface  => '! docker1',
  }

  exec { 'create docker network':
    command   => "/usr/bin/docker network create --subnet ${bridge_subnet} -o com.docker.network.bridge.name=docker1 docker1",
    unless    => '/usr/bin/docker network inspect docker1',
    subscribe => Service['docker'],
  }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      *       => $options,
      require => Exec['create docker network'],
    }
  }
}

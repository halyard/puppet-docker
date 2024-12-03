# @summary Configure Docker containers
#
# @param containers to launch
# @param data_root for storing docker images / volumes
# @param bridge_subnet sets the subnet used for the custom bridge
# @param bridge_name sets the name of the custom bridge
class docker (
  Hash[String, Hash] $containers = {},
  String $data_root = '/var/lib/docker',
  String $bridge_subnet = '172.17.0.0/16',
  String $bridge_name = 'docker1',
) {
  package { 'docker': }

  -> file { [$data_root, '/etc/docker']:
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
    dst_type    => 'LOCAL',
    table       => 'nat',
  }

  firewall { '100 masquerade for docker containers':
    chain    => 'POSTROUTING',
    jump     => 'MASQUERADE',
    proto    => 'all',
    outiface => "! ${bridge_name}",
    source   => $bridge_subnet,
    table    => 'nat',
  }

  firewall { '100 masquerade for localhost uturn':
    chain    => 'POSTROUTING',
    jump     => 'MASQUERADE',
    src_type => 'LOCAL',
    dst_type => 'UNICAST',
    outiface => $bridge_name,
    table    => 'nat',
  }

  firewall { '100 forward from docker containers':
    chain    => 'FORWARD',
    action   => 'accept',
    proto    => 'all',
    outiface => "! ${bridge_name}",
    iniface  => $bridge_name,
  }

  firewall { '100 forward to docker containers':
    chain    => 'FORWARD',
    action   => 'accept',
    proto    => 'all',
    outiface => $bridge_name,
    iniface  => "! ${bridge_name}",
  }

  exec { 'create docker network':
    command   => "/usr/bin/docker network create --subnet ${bridge_subnet} -o com.docker.network.bridge.name=${bridge_name} ${bridge_name}",
    unless    => "/usr/bin/docker network inspect ${bridge_name}",
    subscribe => Service['docker'],
  }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      *       => $options,
      require => Exec['create docker network'],
    }
  }
}

# @summary Create a Docker container
#
# @param image sets the Docker image to fetch for the container
# @param args sets the arguments for the docker run command
# @param cmd sets the command to launch the container with
# @param container_name (namevar) sets the name of the container
# @param network sets the network to use for the container
define docker::container (
  String $image,
  Array[String] $args,
  String $cmd,
  String $container_name = $title,
  String $network = 'docker1',
) {
  include docker

  file { "/etc/container/${container_name}":
    ensure  => file,
    content => template('docker/container.erb'),
  }

  ~> service { "container@${container_name}":
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/container@.service'],
  }
}

# @summary Configure Docker containers
#
# @param containers to launch
class docker (
  Hash[String, Hash] $containers = {},
) {
  package { 'docker': }

  $docker::containers.each | String $name, Hash $options | {
    docker::container { $name:
      * => $options,
    }
  }
}

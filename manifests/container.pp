# @summary Create a Docker container
#
# @param image sets the Docker image to fetch for the container
# @param container_name (namevar) sets the name of the container
define smb::mount (
  String $image,
  String $container_name = $title,
) {
}

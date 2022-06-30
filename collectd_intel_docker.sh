#!/bin/bash

set -eo pipefail

IFS=$'\n\t'

DOCKER_IMAGE_NAME=''
DOCKER_CONTAINER_NAME=''
COLLECTD_FLAVOR=stable

readonly DOCKER_IMAGE_TAG='0.1'
readonly COLLECTD_DEBUG=${COLLECTD_DEBUG:="n"}
readonly http_proxy=${http_proxy:=""}
readonly https_proxy=${https_proxy:=""}

readonly CONTAINER_MEMORY_LIMIT=200m
readonly CONTAINER_CPU_SHARES=512

readonly YELLOW='\033[1;33m'
readonly GREEN='\033[1;32m'
readonly RED='\033[1;31m'
readonly NO_COLOR='\033[0m'

CUSTOM_VOLUME_MOUNTS=()

# Check docker presents on machine.
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

# Assign second and third argument (if present) to image name and container name
function set_container_image_names() { 
  if [ $# -ge 3 ]; then
    DOCKER_IMAGE_NAME=$2
    DOCKER_CONTAINER_NAME=$3
    return 0
  else
    echo -e "${RED}Please provide image and container name! e.g.: ${YELLOW}$0 $1 <image-name> <container-name>${NO_COLOR}"
    return 1
  fi
}

# Assign second argument to container name if present
function set_container_name() {
  if [ $# -ge 2 ]; then
    DOCKER_CONTAINER_NAME=$2
    return 0
  else
    echo -e "${RED}Please provide container name! e.g.: ${YELLOW}$0 $1 <container-name>${NO_COLOR}"
    return 1
  fi
}

# Assign second argument to image name if present
function set_image_name() {
  if [ $# -ge 2 ]; then
    DOCKER_IMAGE_NAME=$2
    return 0
  else
    echo -e "${RED}Please provide image name! e.g.: ${YELLOW}$0 $1 <image-name>${NO_COLOR}"
    return 1
  fi
}

# Check if provided paths are correct
function check_paths() {
  echo -e "Checking provided paths: $1"
  # Initial test if arg is in correct format /*:/*
  if [[ $1 != "/"*":/"* ]]; then
    echo -e "${RED}Please provide argument in correct format eg. /path/on/host:/path/in/container${NO_COLOR}"
    return 1
  fi
  # Split paths into array (with IFS replacement)
  oldIFS="$IFS"; IFS=:
  read -a PATHS <<< "$1"
  IFS="$oldIFS"; unset oldIFS
  if [[ ! -d ${PATHS[0]} ]] && [[ ! -f ${PATHS[0]} ]]; then
    echo -e "${RED}Provided path is not a file or directory ${PATHS[0]}${NO_COLOR}"
    return 1
  fi
  return 0
}

# Optionally set different collectd flavor or config location
function check_optional_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --flavor)
        if [ -z "$2" ]; then
          echo -e "${RED}Please provide collectd flavor, e.g.: ${YELLOW}$0 build-run img container --flavor stable${NO_COLOR}"
          exit 1
        else
          if [ "$2" != "stable" ] && [ "$2" != "latest" ]; then
            echo -e "${RED}Only allowed values for flavor are stable or latest${NO_COLOR}"
            exit 1
          fi
          COLLECTD_FLAVOR="$2"
          shift 2
          echo "Collectd flavor is set to: $COLLECTD_FLAVOR"
        fi
        ;;
      --config_path)
        if [ -z "$2" ]; then
          echo -e "${RED}Please provide collectd config path, e.g.: ${YELLOW}$0 build-run img container --config_path /opt/collectd/etc/collectd.conf.d${NO_COLOR}"
          exit 1
        else
          if [ ! -d "$2" ]; then
            echo -e "${RED}Given --config_path does not exist: $2 ${NO_COLOR}"
            exit 1
          fi
          CUSTOM_VOLUME_MOUNTS+=(-v "$2":/opt/collectd/etc/collectd.conf.d:ro)
          echo "Collectd config path is set to: $2"
          shift 2
        fi
        ;;
      --mount_dir)
        if [ -z "$2" ]; then
          echo -e "${RED}Please provide paths for mounting, e.g.: /path/on/host:/path/in/container ${NO_COLOR}"
          exit 1
        else
          if check_paths "$2"; then
            CUSTOM_VOLUME_MOUNTS+=(-v "$2":rw)
          else
            # path check failed
            exit 1
          fi
          shift 2
        fi
        ;;
      *)
        shift
    esac
  done
}

# Check if container name exist is listed in docker container list, if so return true.
function check_container_name() {
  if [ "$(docker ps -a -q -f name="^/$DOCKER_CONTAINER_NAME$")" ]; then
    return 0
  else
    return 1
  fi
}

# Build docker image.
function build_docker() {
  docker build -t "$DOCKER_IMAGE_NAME":$DOCKER_IMAGE_TAG \
    --build-arg COLLECTD_FLAVOR="$COLLECTD_FLAVOR" \
    --build-arg COLLECTD_DEBUG="$COLLECTD_DEBUG" \
    --build-arg http_proxy="$http_proxy" \
    --build-arg https_proxy="$https_proxy" \
    --network=host \
    -f docker/collectd-alpine/Dockerfile .
}

# Run docker container.
function run_docker() {
  docker run -d --name "$DOCKER_CONTAINER_NAME" \
    "${CUSTOM_VOLUME_MOUNTS[@]}" \
    -v /sys/fs/resctrl:/sys/fs/resctrl:rw \
    --device /dev/mem:/dev/mem --cap-add SYS_RAWIO \
    --memory="$CONTAINER_MEMORY_LIMIT" \
    --cpu-shares="$CONTAINER_CPU_SHARES" \
    --restart on-failure:5 \
    --security-opt=no-new-privileges \
    --health-cmd='stat /etc/passwd || exit 1' \
    --pids-limit 100 \
    --network=host \
    --privileged \
    -i -t "$DOCKER_IMAGE_NAME":$DOCKER_IMAGE_TAG
}

# Remove docker images
function remove_docker_images() {
  echo -e "${YELLOW}Removing Collectd Docker image...${NO_COLOR}"
  docker rmi "$DOCKER_IMAGE_NAME":$DOCKER_IMAGE_TAG
  echo -e "${YELLOW}Removing dangling images${NO_COLOR}"
  docker images -f "dangling=true" -q | while read -r image; do
    docker rmi "$image"
  done
}

collectd-intel-docker() {
  case $1 in
  build-run)
    if set_container_image_names "$@"; then
      # Check if there is container if same name as user gave in argument
      if ! check_container_name; then
        check_optional_flags "$@"
        echo -e "${GREEN}Spinning up Collectd Docker image...${NO_COLOR}"
        echo "If this is your first time starting docker image this might take a minute..."
        # Build container and run it in background, with mounted files, in privileged mode,
        # shared network with host, and with runtime environment variables.
        build_docker
        run_docker
        echo -e "${GREEN}DONE!${NO_COLOR}"
      else
        echo -e "${RED}Container with name '${DOCKER_CONTAINER_NAME}' already exists. Please provide new one.${NO_COLOR}"
      fi
    fi
    ;;
  build)
    if set_image_name "$@"; then
      check_optional_flags "$@"
      echo -e "${GREEN}Building Collectd Docker image...${NO_COLOR}"
      echo "If this is your first time building image this might take a minute..."
      build_docker
      echo -e "${GREEN}DONE!${NO_COLOR}"
    fi
    ;;
  run)
    if set_container_image_names "$@"; then
      if [ "$(docker images -a -q "$DOCKER_IMAGE_NAME")" ]; then
        check_optional_flags "$@"
        echo -e "${GREEN}Running CollectD Docker container...${NO_COLOR}"
        run_docker
        echo -e "${GREEN}DONE!${NO_COLOR}"
      else
        echo -e "${RED}Image with name '${DOCKER_IMAGE_NAME}' not exists. Please provide correct name.${NO_COLOR}"
      fi
    fi
    ;;
  restart)
    if set_container_name "$@"; then
      # Check if there is container with provided name, to prevent restarting not existing container.
      if check_container_name; then
        echo -e "${YELLOW}Restarting Collectd Docker container...${NO_COLOR}"
        # Restart container, to use latest build image.
        docker restart "$DOCKER_CONTAINER_NAME"
        echo -e "${GREEN}DONE!${NO_COLOR}"
      else
        echo -e "${YELLOW}There's no Collectd Docker CONTAINER/IMAGE with name '${DOCKER_CONTAINER_NAME}'/
        '${DOCKER_IMAGE_NAME}', please build and run image using: ${NO_COLOR}./collectd-intel-docker build-run <image-name> <container-name>"
      fi
    fi
    ;;
  remove)
    if set_container_image_names "$@"; then
      echo -e "${YELLOW}Stopping Collectd Docker container...${NO_COLOR}"
      docker stop "$DOCKER_CONTAINER_NAME"
      echo -e "${YELLOW}Removing Collectd Docker container...${NO_COLOR}"
      docker rm "$DOCKER_CONTAINER_NAME"
      remove_docker_images
    fi
    ;;
  remove-build)
    if set_image_name "$@"; then
      remove_docker_images
    fi
    ;;
  enter)
    if set_container_name "$@"; then
      echo -e "${YELLOW}Entering /bin/bash session in the collectd container...${NO_COLOR}"
      docker exec -it "$DOCKER_CONTAINER_NAME" /bin/bash
    fi
    ;;
  logs)
    if set_container_name "$@"; then
      echo -e "${YELLOW}Following the logs from the collectd container...${NO_COLOR}"
      docker logs -f --since=1s "$DOCKER_CONTAINER_NAME"
    fi
    ;;
  *)
    cat <<-EOF
collectd dockerized commands:

  build-run <image-name> <container-name>                                  -> Build and run Collectd Docker image.

  build <image-name>                                                       -> Build Collectd Docker image.

  run <image-name> <container-name>                                        -> Run Collectd Docker image.

  restart <container-name>                                                 -> Restart Collectd container (equivalent to: docker restart <container-name>).

  remove <image-name> <container-name>                                     -> Stop and remove all Collectd Docker container, and images.

  remove-build <image-name>                                                -> Remove multistage images, and Collectd Docker image.

  enter <container-name>                                                   -> Enter Collectd Docker CONTAINER via bash.

  logs <container-name>                                                    -> Stream logs for the Collectd Docker container.

optional flags:

  --flavor                                                                 -> Choose collectd flavor for image build from one of stable or latest.

  --config_path                                                            -> Set custom path with collectd config for container run.

  --mount_dir                                                             -> Mounts provided host paths to container (e.g. --mount_dir /home/user/collectd/:/tmp/collectd/) 

EOF
    ;;
  esac
}

pushd "$(dirname "$0")" >/dev/null
collectd-intel-docker "$@"
popd >/dev/null

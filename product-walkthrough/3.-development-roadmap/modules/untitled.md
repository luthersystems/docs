---
description: Luther Systems infrastructure management tool.
---

# Copy of Mars: Infra Management

## Setup

Build the container

```
make
```

Make sure ssh-agent has your key private key

```
ssh-add -l
```

If ssh-add doesn't print anything, it doesn't have you key. Run `ssh-add` without arguments or point it to the appropriate key file in special cases.

## Usage

Place a .mars-version file at the root of the repository to ensure that the behavior of mars is the same for all team members.

```
echo $MARS_VERSION > $(git rev-parse --show-toplevel)/.mars-version
```

Ensure all terraform projects have a `.terraform-version` file specifying which terraform version to use (technically optional). See [tfenv](https://github.com/kamatama41/tfenv) for more details.

```
echo 0.11.3 > .terraform-version
```

MacOS users need a method of forwarding the host's ssh-agent to the docker container is necessary (see long discussions spawning from [this thread](https://forums.docker.com/t/can-we-re-use-the-osx-ssh-agent-socket-in-a-container/8152)). It seems like [uber-common/docker-ssh-forward](https://github.com/uber-common/docker-ssh-agent-forward) is the defacto best option as the [avsm/docker-ssh-forward](https://github.com/avsm/docker-ssh-agent-forward) project recommended from the linked thread seems to be unmaintained now (years later).

To ease working with the docker image install a symlink pointing to the shell script in this project to make running the container less painful.

MacOS users should symlink the macOS specific script `mars_macos.sh` which will make use of `pinata-ssh-mount` to forward the host ssh agent (see note above).

```
ln -s $(pwd)/mars_macos.sh ~/bin/mars
mars -h
```

### Technical details

If `$SSH_AUTH_SOCK` is mountable on docker containers (on Linux -- not macOS), general usage has the following form.

```bash
LOCAL_CACHE="$HOME/.mars/tfenv/versions"
END_USER=$(id -u $USER):$(id -g $USER)
DOCKER_WORKDIR=/terraform

PROJECT_PATH=$(pwd)
docker run --rm -it \
    -u $END_USER \
    -v "$LOCAL_CACHE:/opt/tfenv/versions" \
    -v "$PROJECT_PATH:/terraform" \
    -v "$HOME/.aws/:/opt/home/.aws" \
    -v "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK" \
    -e "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" \
    luthersystems/mars COMMAND [FLAGS] ARGS
```

The user (`-u`) is set so that state files in the project's .terraform directory will be owned by the correct user (not root). AWS credentials must be mounted into /opt/home, which is containers value for environment variable `HOME`. Finally, in order for ssh to work the ssh-agent's socket must be mounted into the container from the host and variable `SSH_AUTH_SOCK` has to be set, telling the container where to find the unix socket.

Mounting to path /opt/tfenv/versions is not a requirement but will prevent containers run with `--rm` from continuously needing to download versions of terraform not included in the default installation. The mount, or alternatively running with `--rm`, will bypass this issue. For now, `--rm` and mounting the cache in the docker command fits our workflow better so we typically do that.

### Terraform

If you need to run a raw terraform command using the `terraform` binary installed in the container you may run `mars terraform` but without care python will intercept options/flags intended for terraform. Often you will have to use the special argument `--` to tell python not to try and parse the flags meant for terraform.

```
mars dev terraform -- providers --help
```

### Packer

Running packer currently expects a specific directory structure.

```
/IMAGE/packer.json
/...
```

A packer.json file is expected to be nested under a directory with the name of the output AMI. This structure allows multiple pcaker AMIs to be built using common ansible roles. Run packer commands by specifying the image and then the desired command.

```
mars IMAGE packer-validate
mars IMAGE packer-build
```

### ALB

A utility is provided to locate DNS names for load balancers created by kubernetes ingress objects (via the alb-ingress-controller) using tags.

Create a file that defines environment variables `PROJECT_NAME` and `AWS_REGION`. For example,

```
cat > mars.env
PROJECT_NAME=xyz
AWS_REGION=eu-west-2
^D
```

Then invoke the utility specify an optional component and org.

```
mars ENV alb-dns --component COMPONENT --org ORG
```

The utility will print the DNS name for all matching ALBs. Any number of ALBs may be found if the provided parameters aren't specific enough or if no ALB has tags matching the input values.

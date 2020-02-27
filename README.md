# stardust-docker
Dockerfiles for the STARDUST project

### Configuring the host VM to forward multicast to containers

Before adding any containers, run `prepare-host.sh` on the VM that will be
hosting the containers.

        sudo ./prepare-host.sh

### Creating a new container user

To create and start a user container on the VM, run

	sudo ./create-stardust-user.sh <username> [ <password> ]

If password is not set, a random one will be generated and written to
the terminal once the user has been created.

By default, the user's container will be the caida/stardust-basic:latest
image. If a user requires a different image, this can be specified by
modifying `/etc/dockersh.ini` to add a custom section for that user. The
default image can also be changed by editing this file.

The newly created user will also be assigned a 100GB volume for their
persistent storage. This volume is implemented as a file on disk, which is
configured as an ext4 file system. You can change the default volume size
by setting the `STARDUSTVOLUMESIZE` environment variable to the desired
volume size (in megabytes). Note that you will probably need to pass the
`-E` flag to sudo to ensure this environment variable is passed through to
the root shell that is running the user creation script.

### Accessing containers

Once the user exists, they can reach their container simply by sshing into
the VM that the user was created on, using the username and password from
the ./create-vm-user.sh script. dockersh will automatically put the user
directly into their container, skipping the host VM.

If the container does not exist, it will be created using the latest version
of the base image.

Users can copy files to and from their container by using scp on the limbo
gateway box.

TODO experiment with SSH keys to replace passwords for access

### Using the container
Each user has a volume created for persistent storage -- this will be mounted
at `/storage/` on their container. Any files on the container that the user
wants to keep must be placed in `/storage/`.

Users are automatically given sudo access on their container, without requiring
them to input a password. The actual password is a randomly generated string
that can be accessed by admins using `docker logs` once the container has been
created (i.e. the user has logged in for the first time).

### Upgrading containers

If a user wishes to upgrade to a newer container image (or we wish to force
such an upgrade on to the user), there are a few things to be aware of:

  * the user container must be stopped (using `docker container stop`),
    then removed (using `docker container rm`). Both steps are necessary,
    otherwise dockersh will simply restart the old container rather than
    starting a new one with the current image.
  * Once a container is removed, any files in `/home/` on the container
    will be lost. It's possible that a regular use of the dockersh
    `commit_all.py` might allow us to work around this, but I haven't
    gotten it to work yet so probably better to just push `/storage/` as
    the safe persistent storage.
  * the password set on the container itself (not the access one, the one
    we see in `docker logs`) will be re-generated. The access password used
    to ssh into the container will be unchanged.


### Testing containers

A quick test to make sure that the container is receiving useful nDAG traffic:

        tracepktdump -c 5 ndag:eth1,225.44.0.1,44000

If this hangs and produces no useful output, then the multicast is broken.


### Removing a container user

        sudo ./remove-stardust-user.sh <username>

Note that this script will also purge their container and persistent storage,
so only run this when you are absolutely sure that the user will not be
returning in the future.

Steps to simply remove the user's container (e.g. for force an upgrade or
if the user just wants a fresh start):

        docker container stop <container name>
        docker container rm <container name>

After doing this, the user will receive a clean container (of the latest
build for the base image) when they next log in to the host VM. Persistent
storage will remain as it was, but /home/ will be empty again and all installed
software that was not part of the base image will be gone.

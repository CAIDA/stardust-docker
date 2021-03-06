# stardust-docker
Dockerfiles for the STARDUST project

### Configuring the host VM to forward multicast to containers

Before adding any containers, run `prepare-host.sh` on the VM that will be
hosting the containers.

        sudo ./prepare-host.sh

### Creating a new container user

To create and start a user container on the VM, run

	sudo ./create-stardust-user.sh -u <username> [ -p <password> ]
                [ -k sshpubkeyfile ] [ -V volumesize ]

If password is not set, a random one will be generated and written to
the terminal once the user has been created.

If the path to an SSH public key (e.g. `id_rsa.pub`) is passed in using the
`-k` option, then that public key will be added to the new user's authorized
SSH keys and they will be able to log in to their container using the
corresponding private key. If no key file is provided, then they will be
limited to password auth only.

By default, the user's container will be the caida/stardust-basic:latest
image. If a user requires a different image, this can be specified by
modifying `/etc/dockersh.ini` to add a custom section for that user. The
default image can also be changed by editing this file.

The newly created user will also be assigned a volume for their
persistent storage. This volume is implemented as a file on disk, which is
configured as an ext4 file system. You can change the default volume size
by setting the `-V` argument to the desired volume size (in megabytes).
The default volume size is 100 GB.

To constrain the amount of CPU time and memory for the user's container,
you can set the `cpulimit` and `memhardlimit` configuration options in
`/etc/dockersh.ini`. The cpulimit is specified in terms of number of CPUs
(e.g. a value of 1.5 will limit the user to approximately 1.5 cores of CPU
time) and is a soft limit. The memhardlimit can be specified as a
number followed by a units character ('b', 'k', 'm', or 'g'), e.g. `4g` will
limit the user to 4 GB of memory. The OOM killer will begin halting processes
in their container once the memory limit is exceeded. If the limits are not
specified, then the user will be able to use the full resources of their host
VM.

If your user is going to be running Spark jobs with their container, you
will also need to specify the `sparkblockport`, `sparkdriverport`, and
`sparkuiport` options in `/etc/dockersh.ini`. These options must be specified
within the custom section for that user and must be unique for each user that
is sharing a container host. For instance, if user A is using ports 5001, 5002
and 5003 for their Spark driver, UI and block ports respectively, then user B
should avoid using any ports in the 5001-5030 range for their own Spark ports.

Users that are not using their container for running Spark jobs (e.g. are
using the stardust-basic image) do not need to provide Spark port options and
can safely ignore any warnings about missing Spark port configuration when they
start their container.

### Accessing containers

Once the user exists, they can reach their container simply by sshing into
the VM that the user was created on. dockersh will automatically put the user
directly into their container, skipping the host VM. Key authentication will
be preferred if available, otherwise SSH will fall back to password auth.

If the container does not exist, it will be created using the latest version
of the base image.

Users can copy files to and from their container by using scp on the limbo
gateway box.

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

### Modifying images and uploading to Docker Hub

To build the docker image:
```
# from within a clone of the stardust-docker repo
docker build --no-cache -t caida/stardust-spark spark-user/
```

To upload to docker hub (after running `docker login`):
```
docker push caida/stardust-spark:latest
```

# stardust-docker
Dockerfiles for the STARDUST project

### Configuring the host VM to forward multicast to containers

Before adding any containers, run `prepare-host.sh` on the VM that will be
hosting the containers.


### Starting containers

To create and start a user container on the VM, run

        start-container.sh <baseimage> <container name> [ <password> ]

If password is not set, a random one will be generated and written to
the terminal once the container is running.

The base image should be the image from Docker Hub that the user requires,
e.g. caida/stardust-basic:latest

The container name must be unique for that VM, but can otherwise be anything.
Ideally though, it would be related to the user or the project in some way.


### Accessing containers

When the container has started, an IP address and port for SSH access should
be written to standard output.

SSH into the new container:

        ssh root@172.17.0.1 -p <sshport>

Make sure that the container is receiving useful nDAG traffic:

        tracepktdump -c 5 ndag:eth1,225.44.0.1,44000


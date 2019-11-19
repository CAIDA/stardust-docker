# stardust-docker
Dockerfiles for the STARDUST project

### Configuring the host VM to forward multicast to containers

TODO: turn this into some scripts for easy deployment

1. Run prepare-host.sh on the VM that will be hosting the containers.


2. Create user container (the sysctls mean that the container interfaces won't drop
multicast because it has a source address that doesn't match the interface subnet):

    docker run --sysctl net.ipv4.conf.all.rp_filter=0 --sysctl net.ipv4.conf.default.rp_filter=0 -d -P --rm -it --name <containername> <stardust container image>

3. Grab container root password from logs:

    docker logs <containername>

4. Add container to ndag network:

    docker network connect ndag <containername>

5. Get the port that your container is listening on for SSH:

    docker port <containername>

6. SSH into the new container:

    ssh root@172.17.0.1 -p <sshport>

7. Make sure you get useful nDAG traffic:

    tracepktdump -c 5 ndag:eth1,225.44.0.1,44000

### Starting containers
Environment variables that can be set using '-e' when using "docker run"
to start a container:

 * `FORCEPWD` -- sets the root password for the container to be a specific
                 string, rather than a randomly generated one.

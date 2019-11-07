# stardust-docker
Dockerfiles for the STARDUST project

### Configuring the host VM to forward multicast to containers

TODO: turn this into some scripts for easy deployment

Install docker-ce

Put daemon.json into /etc/docker/ -- this will prevent containers from talking to each other

Restart docker service

Create a network specifically for receiving multicast
(the enable_icc option is probably unnecessary, but I've added it to be safe):

    docker network create -o "com.docker.network.driver.mtu"="9000" -o "com.docker.network.bridge.enable_icc"="false" ndag

Figure out the virtual interface name assigned to your new network.
It'll be something awkward like br-acb9a90e6770.

Install latest release of smcroute (not the packaged version which is
way out of date!). https://github.com/troglobit/smcroute/releases

Put smcroute.conf into /etc/

Replace "docker0" in /etc/smcroute.conf with the virtual interface name for the ndag network

Restart smcroute service

    sudo iptables --policy FORWARD ACCEPT           # (may need to refine this a bit?)

Create user container:

    docker run -d -P --rm -it --name <containername> <stardust container image>

Grab password from logs:

    docker logs <containername>

Add container to ndag network

    docker network connect ndag <containername>

Make sure you get useful nDAG traffic:

    tracepktdump -c 5 ndag:eth1,225.44.0.1,44000

### Starting containers
Environment variables that can be set using '-e' when using "docker run"
to start a container:

 * `FORCEPWD` -- sets the root password for the container to be a specific
                 string, rather than a randomly generated one.

#!/bin/bash

REALUSER=`who am i | awk '{print $1}'`
SMCROUTE_VER=2.4.4
SAVEDPWD=`pwd`

# Install pre-requisites
apt-get update && apt-get install -y apt-transport-https \
    automake autoconf libtool \
    ca-certificates \
    curl \
    pwgen \
    gnupg-agent \
    libcap-dev \
    libsystemd-dev \
    pkg-config \
    python3-pip \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt-get update

# Create directory for storing the "volumes" for our containers
mkdir -p /stardust-volumes/
mkdir -p /mnt/stardust-docker/

# Install docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker ${REALUSER}
echo "${REALUSER} has been added to the docker group.  Before you do any docker"
echo "operations as your user, be sure to re-ssh in to pick up this group."
echo "This is NOT NEEDED to complete this or the subsequent create-stardust-user.sh operations"
echo "as those are done using sudo and this group is not needed for that."

# Enforce no communication between containers on the same host
cp daemon.json /etc/docker/

# Lower container MTU, otherwise pip3 installs will fail regularly
mkdir -p /etc/systemd/system/docker.service.d/
cp fixmtu.conf /etc/systemd/system/docker.service.d/

service docker restart

# Install dockersh
#git clone https://github.com/sleeepyjack/dockersh
git clone https://github.com/salcock/dockersh
cd dockersh && sudo -H ./install.sh

cd ${SAVEDPWD}
cp dockersh.ini /etc/

# pull stardust docker image for use in dockersh
# as this becomes more of a user management issue, with more images
# we might want to pull this out and put in the user mgmt scripts
# to save storage ( i.e. they only pull images they need )
#
# also.. it may be a bug in dockersh that it doesn't pull images.
# in which case this can be removed
docker pull caida/stardust-basic
docker pull caida/stardust-spark

# Create a network specifically for pushing multicast into containers
docker network create -o "com.docker.network.driver.mtu"="9000" \
    -o "com.docker.network.bridge.enable_icc"="false" \
    -o "com.docker.network.bridge.name"="br_ndag" ndag

# Install a recent release of smcroute -- the packaged versions are far too
# out of date
cd ${SAVEDPWD}
wget https://github.com/troglobit/smcroute/releases/download/${SMCROUTE_VER}/smcroute-${SMCROUTE_VER}.tar.gz

tar -xvzf smcroute-${SMCROUTE_VER}.tar.gz && cd smcroute-${SMCROUTE_VER}/

./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make -j4 && make install-strip

# Configure smcroute to forward our multicast onto the br_ndag network
cd ${SAVEDPWD}
cp smcroute.conf /etc/

systemctl enable docker
systemctl enable smcroute
service smcroute start

# Make sure iptables doesn't drop our multicast traffic
iptables -I FORWARD 1 -p udp -s 10.224.226.148/32 -d 224.0.0.0/4 -j ACCEPT


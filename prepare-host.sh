#!/bin/bash

REALUSER=`who am i | awk '{print $1}'`
SMCROUTE_VER=2.4.4
SAVEDPWD=`pwd`

# Install pre-requisites
apt-get update && apt-get install -y apt-transport-https \
    automake autoconf libtool \
    ca-certificates \
    curl \
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

# Install docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker ${REALUSER}

# Enforce no communication between containers on the same host
cp daemon.json /etc/docker/

service docker restart

# Install dockersh
#git clone https://github.com/sleeepyjack/dockersh
git clone https://github.com/salcock/dockersh
cd dockersh && sudo -H ./install.sh

cd ${SAVEDPWD}
cp dockersh.ini /etc/

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


#!/bin/bash

BASEIMAGE=$1
CONTAINERNAME=$2
CHOSENPWD=$3

function usage() {
	echo "Usage: $1 <base image> <container name> [<password>]"
	echo
	echo "  e.g. to create a basic STARDUST VM called 'abasicvm' with a random password:"
	echo "       $1 caida/stardust-basic:latest abasicvm"
	echo
	echo "Add an extra argument to set an explicit password, rather than a random one."
}

if docker container inspect ${CONTAINERNAME} > /dev/null 2>&1; then
	echo "Container ${CONTAINERNAME} already exists!"
	echo "Choose another name or remove the existing container first."
	exit 1
fi

if [ "${BASEIMAGE}" = "" ]; then
	echo "Must specify a base image on the command line!"
	usage $0
	exit 1
fi

if [ "${CONTAINERNAME}" = "" ]; then
	echo "Container name must not be empty!"
	usage $0
	exit 1
fi

if [ "${CHOSENPWD}" = "" ]; then
	PWDSET=""
else
	PWDSET="-e FORCEPWD=${CHOSENPWD}"
fi


# The sysctls ensure that the kernel won't drop any multicast routed into the
# container due to reverse path filtering.
docker run --sysctl net.ipv4.conf.all.rp_filter=0 \
	--sysctl net.ipv4.conf.default.rp_filter=0 \
	${PWDSET} -d -P --rm -it --name ${CONTAINERNAME} ${BASEIMAGE}

SETPWD=`docker logs ${CONTAINERNAME} | grep STARDUST-DOCKER | grep password | rev \
	| cut -d " " -f 1 | rev`

docker network connect ndag ${CONTAINERNAME}

SSHPORT=`docker port ${CONTAINERNAME} | grep "22/tcp" | rev | cut -d ":" -f 1 | rev`

SSHIP=`docker network inspect -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}' bridge`

# TODO save this info to a file or database somewhere
echo "Container ${CONTAINERNAME} has been created..."
echo "Listening for SSH on root@${SSHIP} -p ${SSHPORT}"
echo "Root password has been set to ${SETPWD}"

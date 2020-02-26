#!/bin/bash

if [ "${1}" = "" ]; then
	echo "No username specified on command-line -- exiting"
	exit 1
fi

if [ "${2}" = "" ]; then
	NEWPWD=`pwgen 16 1`
else
	NEWPWD=${2}
fi

useradd -s /usr/local/bin/dockersh --create-home $1
echo "${1}:${NEWPWD}" | chpasswd
echo "STARDUST-VM: Setting VM password for new user ${1} to ${NEWPWD}"

usermod -aG docker ${1}

docker volume create stardust-${1}

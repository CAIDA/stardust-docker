#!/bin/bash

if [ "${STARDUSTVOLUMESIZE}" = "" ]; then
        STARDUSTVOLUMESIZE=102400        # 100GB
fi

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

# Create persistent storage
# We're going to create a file, turn it into a block device and mount
# it as a loop device which can then be mounted as a volume inside the
# container. This allows us to limit the storage size for each user
# (standard docker volumes don't really let you do this).
dd if=/dev/zero of=/stardust-volumes/${1} bs=1M count=${STARDUSTVOLUMESIZE}
mkfs.ext4 /stardust-volumes/${1}
mkdir /mnt/stardust-docker/${1}
mount -t ext4 -o loop /stardust-volumes/${1} /mnt/stardust-docker/${1}

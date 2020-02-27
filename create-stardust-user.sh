#!/bin/bash

usage() {
        echo "Usage: $1 -u username [-p password] [-V volumesize] [-k SSHpubkeyfile]"
}

while getopts "u:p:k:V:h" OPTION; do
        case $OPTION in
        u)
                USERNAME=$OPTARG
                ;;
        p)
                NEWPWD=$OPTARG
                ;;
        k)
                KEYFILE=$OPTARG
                ;;
        V)
                VOLUMESIZE=$OPTARG
                ;;
        h)
                usage ${0}
                exit 1
                ;;
        --)
                usage ${0}
                exit 1
                ;;

        esac
done

if [ "${VOLUMESIZE}" = "" ]; then
        VOLUMESIZE=102400        # 100GB
fi

if [ "${USERNAME}" = "" ]; then
	echo "No username specified on command-line -- exiting"
        usage ${0}
	exit 1
fi

if [ "${NEWPWD}" = "" ]; then
	NEWPWD=`pwgen 16 1`
fi

useradd -s /usr/local/bin/dockersh --create-home ${USERNAME}
echo "${USERNAME}:${NEWPWD}" | chpasswd
echo "STARDUST-VM: Setting VM password for new user ${USERNAME} to ${NEWPWD}"

if [ "${KEYFILE}" != "" ]; then
        mkdir -p /home/${USERNAME}/.ssh
        cat ${KEYFILE} >> /home/${USERNAME}/.ssh/authorized_keys
else
        echo "No pubkey provided on the command-line -- password login only"
fi

usermod -aG docker ${USERNAME}

# Create persistent storage
# We're going to create a file, turn it into a block device and mount
# it as a loop device which can then be mounted as a volume inside the
# container. This allows us to limit the storage size for each user
# (standard docker volumes don't really let you do this).
echo "Creating persistent storage, size ${VOLUMESIZE} MB (may take a while)"
dd if=/dev/zero of=/stardust-volumes/${USERNAME} bs=1M count=${VOLUMESIZE}
echo "Storage file created"
mkfs.ext4 /stardust-volumes/${USERNAME}
mkdir /mnt/stardust-docker/${USERNAME}
mount -t ext4 -o loop /stardust-volumes/${USERNAME} /mnt/stardust-docker/${USERNAME}

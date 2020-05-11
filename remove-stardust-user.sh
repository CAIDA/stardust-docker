#!/bin/bash

if [ "$2" = "" ]; then
        BASEIMAGE=caidastardust-basiclatest
else
        BASEIMAGE="$2"
fi

docker container stop ${BASEIMAGE}_${1}
docker container rm ${BASEIMAGE}_${1}

umount -d /mnt/stardust-docker/${1}
rm /stardust-volumes/${1}
rm -rf /mnt/stardust-docker/${1}

userdel -r ${1}

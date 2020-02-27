#!/bin/bash

docker container stop caidastardust-basiclatest_${1}
docker container rm caidastardust-basiclatest_${1}

umount -d /mnt/stardust-docker/${1}
rm /stardust-volumes/${1}
rm -rf /mnt/stardust-docker/${1}

userdel -r ${1}

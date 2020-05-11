#!/bin/bash

# This software is Copyright © 2019 The Regents of the University of
# California. All Rights Reserved. Permission to copy, modify, and distribute
# this software and its documentation for educational, research and non-profit
# purposes, without fee, and without a written agreement is hereby granted,
# provided that the above copyright notice, this paragraph and the following
# three paragraphs appear in all copies. Permission to make commercial use of
# this software may be obtained by contacting:
#
# Office of Innovation and Commercialization
# 9500 Gilman Drive, Mail Code 0910
# University of California
# La Jolla, CA 92093-0910
# (858) 534-5815
# invent@ucsd.edu
#
# This software program and documentation are copyrighted by The Regents of the
# University of California. The software program and documentation are supplied
# "as is", without any accompanying services from The Regents. The Regents does
# not warrant that the operation of the program will be uninterrupted or
# error-free. The end-user understands that the program was developed for
# research purposes and is advised not to rely exclusively on the program for
# any reason.
#
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
# LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
# EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE. THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
# HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO
# OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.


# Set --env FORCEPWD=foo when running the container to force the
# root password to be 'foo', otherwise a random 16 char password
# will be generated.
#
# Use 'docker logs' to see what the password was set to, or
# capture stdout when running the container.

if test "$FORCEPWD" = ""; then
        NEWPWD=`pwgen 16 1`
else
        NEWPWD=${FORCEPWD}
fi

groupadd --gid "${HOST_USER_GID}" "${HOST_USER_NAME}"
useradd \
      --uid ${HOST_USER_ID} \
      --gid ${HOST_USER_GID} \
      --create-home \
      --shell /bin/bash \
      ${HOST_USER_NAME}
usermod -aG sudo ${HOST_USER_NAME}

sed -i "s/SPARK_DRIVER_HOST=localhost/SPARK_DRIVER_HOST=${HOST_IP_ADDRESS}/" \
        /etc/profile.d/javahome.sh
sed -i "s/SPARK_DRIVER_PORT=5001/SPARK_DRIVER_PORT=${SPARK_DRIVER_PORT}/" \
        /etc/profile.d/javahome.sh
sed -i "s/SPARK_BLOCKMGR_PORT=5003/SPARK_BLOCKMGR_PORT=${SPARK_BLOCK_PORT}/" \
        /etc/profile.d/javahome.sh
sed -i "s/SPARK_UI_PORT=5002/SPARK_UI_PORT=${SPARK_UI_PORT}/" \
        /etc/profile.d/javahome.sh

mkdir /home/${HOST_USER_NAME}/.stardust
mv /root/pyspark.conf /home/${HOST_USER_NAME}/.stardust/

mv /root/README.Stardust /home/${HOST_USER_NAME}/

tail -n +2 /etc/profile.d/javahome.sh >> /home/${HOST_USER_NAME}/.bashrc
chown -R ${HOST_USER_NAME}:${HOST_USER_NAME} /home/${HOST_USER_NAME}
chown -R ${HOST_USER_NAME}:${HOST_USER_NAME} /storage

echo "${HOST_USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-stardust-users

echo "STARDUST-DOCKER: Setting password for ${HOST_USER_NAME} to $NEWPWD"
echo "${HOST_USER_NAME}:${NEWPWD}" | chpasswd

exec su - "${HOST_USER_NAME}"

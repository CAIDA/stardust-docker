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


FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive
ARG userhome="/root"
ARG sshport=22

WORKDIR $userhome

RUN apt-get -y update && apt-get -y install apt-transport-https \
                curl lsb-release gnupg wget

RUN echo "deb https://dl.bintray.com/wand/general $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/wand.list
RUN echo "deb https://dl.bintray.com/wand/libtrace $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/wand.list

RUN curl --silent "https://bintray.com/user/downloadSubjectPublicKey?username=wand" | apt-key add -

RUN echo "deb https://pkg.caida.org/os/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/caida.list

RUN curl -so /etc/apt/trusted.gpg.d/caida.gpg https://pkg.caida.org/os/ubuntu/keyring.gpg

RUN apt-get -y update && apt-get -y install \
        autoconf \
        automake \
        autotools-dev \
        build-essential \
        ca-certificates \
        emacs \
        gdb \
        git \
        grep \
        iproute2 \
        less \
        libavro-dev \
        libgoogle-perftools-dev \
        libjansson-dev \
        libjudy-dev \
        librdkafka-dev \
        libtool \
        libtrace4-tools \
        libtrace4-dev \
        libpacketdump4-dev \
        libwandio1-dev \
        libyaml-dev \
        libzmq3-dev \
        nano \
        openjdk-8-jdk \
        openssh-server \
        passwd \
        pkg-config \
        pwgen \
        python3 \
        python3-pip \
        python-swiftclient \
        screen \
        strace \
        tcpdump \
        unzip \
        uthash-dev \
        valgrind \
        vim \
        wandio1-tools

RUN mkdir /var/run/sshd

RUN pip3 install awscli awscli-plugin-endpoint boto3

COPY spark-2.4.4-bin-without-hadoop.tgz ${userhome}/

RUN tar -xvzf spark-2.4.4-bin-without-hadoop.tgz

COPY hadoop-2.10.0.tar.gz ${userhome}/
RUN tar -xvzf hadoop-2.10.0.tar.gz

RUN cp ./hadoop-2.10.0/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.271.jar spark-2.4.4-bin-without-hadoop/jars/

RUN cp ./hadoop-2.10.0/share/hadoop/tools/lib/hadoop-aws-2.10.0.jar spark-2.4.4-bin-without-hadoop/jars/

RUN mv spark-2.4.4-bin-without-hadoop/ spark-2.4.4

COPY javahome.sh /etc/profile.d/

# Allow user to log in as root
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Prevent user from being kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# If we're using a custom port, put it in the sshd config
RUN sed -i "s/#Port 22/Port ${sshport}/" /etc/ssh/sshd_config

# Not sure what this does, but the guide I'm following has it
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir /root/.aws/
COPY spark-defaults.conf ${userhome}/spark-2.4.4/conf/
COPY spark-env.sh ${userhome}/spark-2.4.4/conf/
COPY awsconfig /root/.aws/config

RUN sed -i "s@/root/@${userhome}/@" ${userhome}/spark-2.4.4/conf/spark-env.sh
RUN rm ${userhome}/hadoop-2.10.0.tar.gz ${userhome}/spark-2.4.4-bin-without-hadoop.tgz

# TODO replace with a wget from a public location?
COPY stardust-user-spark-finish.sh /usr/local/sbin/

EXPOSE $sshport

# This will generate a random root password and start the ssh daemon
CMD ["/usr/local/sbin/stardust-user-spark-finish.sh"]
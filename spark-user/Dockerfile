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

ARG builddir=/opt/docker-install/
ARG sparkver=3.1.2

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p ${builddir}
WORKDIR ${builddir}

RUN apt-get -y update && apt-get -y install apt-transport-https \
                curl lsb-release gnupg sudo wget

RUN wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
RUN apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb

RUN curl -1sLf 'https://dl.cloudsmith.io/public/wand/libwandio/cfg/setup/bash.deb.sh' | bash
RUN curl -1sLf 'https://dl.cloudsmith.io/public/wand/libwandder/cfg/setup/bash.deb.sh' | bash
RUN curl -1sLf 'https://dl.cloudsmith.io/public/wand/libtrace/cfg/setup/bash.deb.sh' | bash
RUN curl -s https://pkg.caida.org/os/ubuntu/bootstrap.sh | bash


RUN apt-get -y update && apt-get -y install \
        autoconf \
        automake \
        autotools-dev \
        build-essential \
        ca-certificates \
        cmake \
        emacs \
        git \
        grep \
        iproute2 \
        less \
        libarrow-dev \
        libtool \
        libtrace4-tools \
        libtrace4-dev \
        libpacketdump4-dev \
        libwandio1-dev \
        nano \
        openjdk-8-jdk \
        openssh-server \
        passwd \
        pkg-config \
        pwgen \
        python3 \
        python3-pip \
        python3-swiftclient \
        screen \
        strace \
        tcpdump \
        unzip \
        vim \
        wandio1-tools \
        && rm -rf /var/lib/apt/lists/*

COPY spark-${sparkver}-bin-hadoop3.2.tgz ${builddir}/
COPY hadoop-aws-3.2.0.jar ${builddir}/
COPY aws-java-sdk-bundle-1.11.375.jar ${builddir}/
COPY javahome.sh /etc/profile.d/
COPY awsconfig /root/.aws/config
COPY stardust-user-spark-finish.sh /usr/local/sbin/
COPY pyspark.conf /root/
COPY submit-pyspark.sh /usr/local/sbin/
COPY README.Stardust /root/

# "Install" Spark, Hadoop and awscli

RUN tar -xvzf ${builddir}/spark-${sparkver}-bin-hadoop3.2.tgz && \
    mv ${builddir}/spark-${sparkver}-bin-hadoop3.2/ ${builddir}/spark-${sparkver} && \
    rm ${builddir}/spark-${sparkver}-bin-hadoop3.2.tgz && \
    rm ${builddir}/*.deb

RUN mv ${builddir}/*.jar ${builddir}/spark-${sparkver}/jars/

RUN python3 -m pip install --upgrade pip
RUN pip3 install Cython
RUN pip3 install --default-timeout=1000 --no-cache-dir -vvv \
    awscli awscli-plugin-endpoint boto3 \
    setuptools pyspark pyarrow

RUN git clone https://github.com/CAIDA/stardust-tools && \
    cd stardust-tools/pyspark && python3 setup.py install

COPY spark-defaults.conf ${builddir}/spark-${sparkver}/conf/
COPY spark-env.sh ${builddir}/spark-${sparkver}/conf/

# Make sure Spark can find our hadoop .jars
RUN sed -i "s@/root/@${builddir}/@" ${builddir}/spark-${sparkver}/conf/spark-env.sh

# This will generate a random root password and start the ssh daemon
CMD ["/usr/local/sbin/stardust-user-spark-finish.sh"]


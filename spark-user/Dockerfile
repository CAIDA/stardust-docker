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
ARG sparkver=2.4.5
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p ${builddir}
WORKDIR ${builddir}

RUN apt-get -y update && apt-get -y install apt-transport-https \
                curl lsb-release gnupg sudo wget

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
        git \
        grep \
        iproute2 \
        less \
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
        python-swiftclient \
        screen \
        strace \
        tcpdump \
        unzip \
        vim \
        wandio1-tools \
        && rm -rf /var/lib/apt/lists/*

COPY spark-${sparkver}-bin-without-hadoop.tgz ${builddir}/
COPY hadoop-2.10.0.tar.gz ${builddir}/
COPY javahome.sh /etc/profile.d/
COPY awsconfig /root/.aws/config
COPY stardust-user-spark-finish.sh /usr/local/sbin/

# "Install" Spark, Hadoop and awscli

RUN tar -xvzf ${builddir}/spark-${sparkver}-bin-without-hadoop.tgz && \
    tar -xvzf ${builddir}/hadoop-2.10.0.tar.gz && \
   cp ${builddir}/hadoop-2.10.0/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.271.jar ${builddir}/spark-${sparkver}-bin-without-hadoop/jars/ && \
    cp ${builddir}/hadoop-2.10.0/share/hadoop/tools/lib/hadoop-aws-2.10.0.jar ${builddir}/spark-${sparkver}-bin-without-hadoop/jars/ && \
    mv ${builddir}/spark-${sparkver}-bin-without-hadoop/ ${builddir}/spark-${sparkver} && \
    rm ${builddir}/hadoop-2.10.0.tar.gz ${builddir}/spark-${sparkver}-bin-without-hadoop.tgz

RUN pip3 install --default-timeout=1000 --no-cache-dir -vvv \
    awscli awscli-plugin-endpoint boto3 \
    setuptools pyspark pyarrow

RUN git clone https://github.com/CAIDA/stardust-tools && \
    cd stardust-tools/pyspark && python3 setup.py install

COPY spark-defaults.conf ${builddir}/spark-${sparkver}/conf/
COPY spark-env.sh ${builddir}/spark-${sparkver}/conf/

# Install corsaro2 tools, just in case
RUN git clone https://github.com/CAIDA/corsaro3 && cd corsaro3 && git checkout v2 && git submodule init && git submodule update
RUN cd corsaro3 && autoreconf -vfi && ./configure --with-slash-eight=44 --enable-debug && make && make install && ldconfig

# Remove 'corsaro' binary, as we don't really want people using this to create
# data files with a legacy format
RUN rm /usr/local/bin/corsaro

# Make sure Spark can find our hadoop .jars
RUN sed -i "s@/root/@${builddir}/@" ${builddir}/spark-${sparkver}/conf/spark-env.sh

# This will generate a random root password and start the ssh daemon
CMD ["/usr/local/sbin/stardust-user-spark-finish.sh"]


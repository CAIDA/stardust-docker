#!/bin/sh
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
export SPARK_HOME=/opt/docker-install/spark-3.1.2/

export SPARK_DRIVER_HOST=localhost
export SPARK_DRIVER_PORT=5001
export SPARK_UI_PORT=5002
export SPARK_BLOCKMGR_PORT=5003

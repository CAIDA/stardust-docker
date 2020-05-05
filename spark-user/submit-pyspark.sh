#!/bin/bash

source ~/.stardust/pyspark.conf

if [ "$#" -ne 2 ]; then
        echo "Usage: $0 spark://<spark master IP>:<spark master port> <your script>"
        exit 1
fi

SPARK_MASTER_URL=$1
JOB_SCRIPT=$2

# Works for our particular container setup, but may need to be more
# flexible if we start doing more complicated networking.
SPARK_LOCAL_BIND_ADDR=`hostname --all-ip-addresses | cut -d " " -f 1`

${SPARK_HOME}/bin/spark-submit \
        --packages org.apache.spark:spark-avro_2.11:2.4.5 \
        --master ${SPARK_MASTER_URL} \
        --deploy-mode client \
        --conf spark.driver.port=${SPARK_DRIVER_PORT} \
        --conf spark.blockManager.port=${SPARK_BLOCKMGR_PORT} \
        --conf spark.driver.host=${SPARK_DRIVER_HOST} \
        --conf spark.driver.bindAddress=${SPARK_LOCAL_BIND_ADDR} \
        --driver-java-options "-XX:+UseG1GC" \
        --executor-memory ${SPARK_EXEC_MEM} \
        --driver-memory ${SPARK_DRIVER_MEM} \
        --executor-cores=1 \
        --num-executors=${SPARK_EXEC_NUM} \
        ${JOB_SCRIPT}


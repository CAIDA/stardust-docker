#!/bin/bash

pip3 install --default-timeout=1000 --no-cache-dir -vvv \
    awscli awscli-plugin-endpoint boto3 \
    setuptools pyspark pyarrow

git clone https://github.com/CAIDA/stardust-tools && \
    cd stardust-tools/pyspark && sudo python3 setup.py install

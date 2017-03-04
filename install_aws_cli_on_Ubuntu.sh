#!/bin/bash

curl -O https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py --user
echo "export PATH=~/.local/bin:$PATH" >> ~/.profile
source ~/.profile
pip_version=`pip --version`
echo "pip --version: ${pip_version}"
pip install awscli --upgrade --user
aws_version=`aws --version`
echo "aws_version is: ${aws_version}"

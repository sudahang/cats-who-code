#!/usr/bin/env bash

# Update System
yum update -y
yum install -y docker git make nano

# Start Docker now that it is installed
service docker start

git clone https://github.com/ryan-blunden/cats-who-code.git
cd cats-who-code
make stack
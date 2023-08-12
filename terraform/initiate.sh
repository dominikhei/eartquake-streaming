#!/bin/bash 

sudo apt-get -y update
sudo apt-get -y install docker.io docker-compose

sudo chmod 666 /var/run/docker.sock

sudo apt-get -y install git

docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

sudo systemctl restart docker

git clone https://github.com/dominikhei/eartquake-streaming.git

cd eartquake-streaming/streaming

docker-compose up -d 
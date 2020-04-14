#!/bin/bash

sleep 30

snap install docker
systemctl enable snap.docker.dockerd
systemctl start snap.docker.dockerd

sleep 30

docker run -d \
    --name graphite \
    --restart=always \
    -p 80:80 \
    -p 2003-2004:2003-2004 \
    -p 2023-2024:2023-2024 \
    -p 8125:8125/udp \
    -p 8126:8126 \
    graphiteapp/graphite-statsd

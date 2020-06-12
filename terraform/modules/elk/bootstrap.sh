#!/bin/bash

sleep 30

snap install docker
systemctl enable snap.docker.dockerd
systemctl start snap.docker.dockerd

sysctl -w vm.max_map_count=262144
ulimit -n 65536

sleep 30

docker run -d \
    --name elk \
    --restart=always \
    --ulimit nofile=65536:65536 \
    -e MAX_MAP_COUNT="262144" \
    -e MAX_OPEN_FILES="65536" \
    -e ES_HEAP_SIZE="2g" \
    -e LS_HEAP_SIZE="1g" \
    -p 5601:5601 \
    -p 9200:9200 \
    -p 5044:5044 \
    boeboe/elk-f5-ts:671

#!/bin/bash

x=1
while [ $x -le 5 ]
do
  make destroy_infra; make deploy_infra; make do; sleep 20
  x=$(( $x + 1 ))
done
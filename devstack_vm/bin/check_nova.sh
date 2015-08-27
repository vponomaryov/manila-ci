#!/bin/bash

source /home/ubuntu/keystonerc

NOVA_COUNT=$(nova service-list | awk '{if (NR > 3) {print $4 " " $12 }}' | grep -c "nova-compute up");

if [ "$NOVA_COUNT" != 1 ]
then
    exit 1
fi

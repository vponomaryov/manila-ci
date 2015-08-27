#!/bin/bash

source /home/ubuntu/keystonerc

MANILA_COUNT=$(manila service-list | grep manila-share | grep -c -w up); 

if [ "$MANILA_COUNT" != 1 ]
then
    exit 1
fi

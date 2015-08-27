#!/bin/bash

echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$DEVSTACK_FLOATING_IP "/home/ubuntu/bin/collect_logs.sh"

echo "Creating logs destination folder"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ ! -d /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

echo "Downloading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$DEVSTACK_FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

echo "Uploading logs"
scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz

echo "Before gzip:"
ls -lia `dirname $CONSOLE_LOG`

echo "GZIP:"
gzip -9 -v $CONSOLE_LOG

echo "After gzip:"
ls -lia `dirname $CONSOLE_LOG`

scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY $CONSOLE_LOG* logs@logs.openstack.tld:/srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/ && rm -f $CONSOLE_LOG*

echo "Extracting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/aggregate-logs.tar.gz -C /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/"
echo "Fixing permissions on all log files"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "chmod a+rx -R /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/"

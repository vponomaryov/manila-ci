#!/bin/bash

echo "Collecting logs"
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$DEVSTACK_FLOATING_IP "/home/ubuntu/bin/collect_logs.sh"

if [ "$IS_DEBUG_JOB" != "yes" ]
  then
    echo "Creating logs destination folder"
    ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET ]; then mkdir -p /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET; else rm -rf /srv/logs/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/*; fi"

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
  else
    TIMESTAMP=$(date +%d-%m-%Y_%H-%M)
    echo "Creating logs destination folder"
    ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "if [ -z '$ZUUL_CHANGE' ] || [ -z '$ZUUL_PATCHSET' ]; then echo 'Missing parameters!'; exit 1; elif [ ! -d /srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP ]; then mkdir -p /srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP; else rm -rf /srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/*; fi"

		echo "Downloading logs"
    scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $DEVSTACK_SSH_KEY ubuntu@$FLOATING_IP:/home/ubuntu/aggregate.tar.gz "aggregate-$NAME.tar.gz"

		echo "Uploading logs"
    scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "aggregate-$NAME.tar.gz" logs@logs.openstack.tld:/srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz
    gzip -9 /home/jenkins-slave/console-$NAME.log
    scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY "/home/jenkins-slave/console-$NAME.log.gz" logs@logs.openstack.tld:/srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/console.log.gz && rm -f /home/jenkins-slave/console-$NAME.log.gz

		echo "Extracting logs"
    ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "tar -xzf /srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/aggregate-logs.tar.gz -C /srv/logs/debug/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP/"

		echo "Fixing permissions on all log files"
    ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -i $LOGS_SSH_KEY logs@logs.openstack.tld "chmod a+rx -R /srv/logs/debug/manila/$ZUUL_CHANGE/$ZUUL_PATCHSET/$TIMESTAMP"    
fi

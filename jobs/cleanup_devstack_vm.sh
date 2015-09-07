#!/bin/bash

source $KEYSTONERC

# Loading OpenStack credentials
source /home/jenkins-slave/tools/keystonerc_admin

# Loading functions
source /usr/local/src/manila-ci/jobs/utils.sh

set +e

if [ "$IS_DEBUG_JOB" != "yes" ]
  then
    echo "Detaching the hyper-v node"
    teardown_hyperv $WIN_USER $WIN_PASS $hyperv_node
    echo "Releasing devstack floating IP"
    nova floating-ip-disassociate "$NAME" "$DEVSTACK_FLOATING_IP"
    echo "Removing devstack VM"
    nova delete "$NAME"
    echo "Deleting devstack floating IP"
    nova floating-ip-delete "$DEVSTACK_FLOATING_IP"
  else
    echo "Not deleting the VMs, cleanup will be done by hand after debug"
fi

set -e

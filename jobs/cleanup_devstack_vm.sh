#!/bin/bash

source $KEYSTONERC

set +e

if [ "$IS_DEBUG_JOB" != "yes" ]
  then
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

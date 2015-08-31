#!/bin/bash
set -e

# Deploy devstack vm
source /usr/local/src/manila-ci/jobs/deploy_devstack_vm.sh

# Update local.conf
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_FLOATING_IP $DEVSTACK_SSH_KEY  \
	"sed -i \"s/\(driver_handles_share_servers\).*/\1 = False/g\" /home/ubuntu/devstack/local.conf"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_FLOATING_IP $DEVSTACK_SSH_KEY  \
	"echo 'iniset /opt/stack/tempest/etc/tempest.conf share multitenancy_enabled False' >> /home/ubuntu/devstack/local.sh"

# Run devstack
source /usr/local/src/manila-ci/jobs/run_devstack.sh

# Create the share server used by manila in this scenario
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_FLOATING_IP $DEVSTACK_SSH_KEY  \
    "source /home/ubuntu/keystonerc && /home/ubuntu/bin/create_share_server.sh" 6

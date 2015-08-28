#!/bin/bash

# Run devstack
echo "Run stack.sh on devstack"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_FLOATING_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/run_devstack.sh" 6
if [ $? -ne 0 ]
    then
    echo "Failed to install devstack on cinder vm!"
    exit 1
fi
# Run post_stack
echo "Run post_stack scripts on devstack"
run_ssh_cmd_with_retry ubuntu@$DEVSTACK_FLOATING_IP $DEVSTACK_SSH_KEY "source /home/ubuntu/keystonerc && /home/ubuntu/bin/post_stack.sh" 6
if [ $? -ne 0 ]
then
    echo "Failed post_stack!"
    exit 1
fi

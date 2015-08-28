#!/bin/bash
set -e

# Deploy devstack vm
source /usr/local/src/manila-ci/jobs/deploy_devstack_vm.sh

# Run devstack
source /usr/local/src/manila-ci/jobs/run_devstack.sh

#!/bin/bash

# TODO(lpetrut): remove hardcoded stuff
MANILA_SERVICE_SECGROUP="manila-service"
NET_ID=$(neutron net-list | grep private | awk '{print $2}')

nova --os-username manila --os-tenant-name service --os-password Passw0rd \
     boot ws2012r2 --image=ws2012r2_kvm \
                   --flavor=100 \
                   --nic net-id=$NET_ID \
                   --user-data=/home/ubuntu/ssl/winrm_client_cert.pem \
                   --security-groups $MANILA_SERVICE_SECGROUP \
                   --poll

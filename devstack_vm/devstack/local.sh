#!/bin/bash

set -e

source /home/ubuntu/devstack/functions
source /home/ubuntu/devstack/functions-common

nova flavor-delete 100
nova flavor-create manila-service-flavor 100 2048 25 2

# Add DNS config to the private network
subnet_id=`neutron net-show private | grep subnets | awk '{print $4}'`
neutron subnet-update $subnet_id --dns_nameservers list=true 8.8.8.8 8.8.4.4

TEMPEST_CONFIG=/opt/stack/tempest/etc/tempest.conf

iniset $TEMPEST_CONFIG identity username demo
iniset $TEMPEST_CONFIG identity password Passw0rd
iniset $TEMPEST_CONFIG identity tenant_name demo
iniset $TEMPEST_CONFIG identity alt_username alt_demo
iniset $TEMPEST_CONFIG identity alt_password Passw0rd
iniset $TEMPEST_CONFIG identity admin_username admin
iniset $TEMPEST_CONFIG identity admin_password Passw0rd
iniset $TEMPEST_CONFIG identity admin_tenant_name admin

iniset $TEMPEST_CONFIG share enable_protocols cifs
iniset $TEMPEST_CONFIG share enable_ip_rules_for_protocols ""
iniset $TEMPEST_CONFIG share enable_user_rules_for_protocols cifs
iniset $TEMPEST_CONFIG share enable_ro_access_level_for_protocols cifs
iniset $TEMPEST_CONFIG share storage_protocol CIFS
iniset $TEMPEST_CONFIG share image_with_share_tools ws2012r2_kvm
iniset $TEMPEST_CONFIG share image_username Admin
iniset $TEMPEST_CONFIG share client_vm_flavor_ref 100
iniset $TEMPEST_CONFIG share build_timeout 1200

public_id=`neutron net-list | grep public | awk '{print $2}'`
iniset $TEMPEST_CONFIG network public_network_id $public_id

# router_id=`neutron router-list | grep router | awk '{print $2}'
# iniset $TEMPEST_CONFIG network public_router_id $router_id

IMAGE_PATH='/home/ubuntu/devstack/files/images/ws2012_r2_kvm_eval.qcow2.gz'
gunzip -cd $IMAGE_PATH | glance image-create --name "ws2012r2_kvm" \
                                             --container-format bare --disk-format qcow2 \
                                             --is-public=True --is-protected=False

set +e

MANILA_SERVICE_SECGROUP="manila-service"
nova secgroup-add-rule $MANILA_SERVICE_SECGROUP tcp 5985 5986 0.0.0.0/0

set -e

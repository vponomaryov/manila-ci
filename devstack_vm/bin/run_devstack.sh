#!/bin/bash

set -x
set -e
sudo ifconfig eth1 promisc up

HOSTNAME=$(hostname)

sudo sed -i '2i127.0.0.1  '$HOSTNAME'' /etc/hosts

# Add pip cache for devstack
mkdir -p $HOME/.pip
echo "[global]" > $HOME/.pip/pip.conf
echo "trusted-host = dl.openstack.tld" >> $HOME/.pip/pip.conf
echo "index-url = http://dl.openstack.tld:8080/root/pypi/+simple/" >> $HOME/.pip/pip.conf
echo "[install]" >> $HOME/.pip/pip.conf
echo "trusted-host = dl.openstack.tld" >> $HOME/.pip/pip.conf
echo "find-links =" >> $HOME/.pip/pip.conf
echo "    http://dl.openstack.tld/wheels" >> $HOME/.pip/pip.conf

sudo mkdir -p /root/.pip
sudo cp $HOME/.pip/pip.conf /root/.pip/
sudo chown -R root:root /root/.pip

# Update pip
sudo easy_install -U pip

# Update six to latest version
sudo pip install -U six
sudo pip install -U kombu

# Install PyWinrm for manila
sudo pip install -U git+https://github.com/petrutlucian94/pywinrm

# Running an extra apt-get update
sudo apt-get update --assume-yes

# Ensure subunit is available
sudo apt-get install subunit -y -o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true -f
set -e

DEVSTACK_LOGS="/opt/stack/logs/screen"
LOCALRC="/home/ubuntu/devstack/localrc"
LOCALCONF="/home/ubuntu/devstack/local.conf"
PBR_LOC="/opt/stack/pbr"
# Clean devstack logs
rm -f "$DEVSTACK_LOGS/*"
rm -rf "$PBR_LOC"

MYIP=$(/sbin/ifconfig eth0 2>/dev/null| grep "inet addr:" 2>/dev/null| sed 's/.*inet addr://g;s/ .*//g' 2>/dev/null)

if [ -e "$LOCALCONF" ]
then
        [ -z "$MYIP" ] && exit 1
        sed -i 's/^HOST_IP=.*/HOST_IP='$MYIP'/g' "$LOCALCONF"
fi

if [ -e "$LOCALRC" ]
then
        [ -z "$MYIP" ] && exit 1
        sed -i 's/^HOST_IP=.*/HOST_IP='$MYIP'/g' "$LOCALRC"
fi

cd /home/ubuntu/devstack
git pull

cd /opt/stack/manila
git config --global user.email "microsoft_manila_ci@microsoft.com"
git config --global user.name "Microsoft Manila CI"

# download the patch to be tested
git pull --no-edit https://review.openstack.org/openstack/manila refs/changes/54/200154/11

cd /home/ubuntu/devstack

./unstack.sh

set -o pipefail
./stack.sh 2>&1 | tee /opt/stack/logs/stack.sh.txt

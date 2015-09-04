#!/bin/bash

function cherry_pick {
    commit=$1
    set +e
    git cherry-pick $commit

    if [ $? -ne 0 ]
    then
        echo "Ignoring failed git cherry-pick $commit"
        git checkout --force
    fi

    set -e
}

sudo sh -c "echo '* * * * * root echo 3 > /proc/sys/vm/drop_caches' >> /etc/crontab"

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
sudo pip install -U networking-hyperv

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

# Apply the patch implementing the Windows SMB driver.
# TODO: remove this after it merges
git fetch https://plucian@review.openstack.org/openstack/manila refs/changes/11/220511/4
cherry_pick FETCH_HEAD

cd /home/ubuntu/devstack

./unstack.sh

# Workaround for the Nova API versions mismatch issue.
git revert 8349aff5abd26c63470b96e99ade0e8292a87e7a --no-edit

set -o pipefail
./stack.sh 2>&1 | tee /opt/stack/logs/stack.sh.txt

source /home/ubuntu/keystonerc

MANILA_SERVICE_SECGROUP="manila-service"
echo "Checking / creating $MANILA_SERVICE_SECGROUP security group"

nova secgroup-list-rules $MANILA_SERVICE_SECGROUP || nova secgroup-create $MANILA_SERVICE_SECGROUP $MANILA_SERVICE_SECGROUP

echo "Adding security rules to the $MANILA_SERVICE_SECGROUP security group"
nova secgroup-add-rule $MANILA_SERVICE_SECGROUP tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule $MANILA_SERVICE_SECGROUP udp 1 65535 0.0.0.0/0
set +e
nova secgroup-add-rule $MANILA_SERVICE_SECGROUP icmp -1 -1 0.0.0.0/0
set -e

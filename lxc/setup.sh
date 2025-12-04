#!/bin/bash

if [ -z "$1" ]
then
    echo "USAGE: NAME"
    exit 1
fi

scriptdir=$(dirname $(realpath $0))
. $scriptdir/utils.sh

setup=$1

# Create a SSH private key if needed
if ! [ -f ssh_key ]
then
    ssh-keygen -q -f ssh_key -N ""
fi

$lxc_cmd launch images:rockylinux/8 ${setup}-maxscale-000 || exit 1

wait_for_network ${setup}-maxscale-000

# Setup the containers for testing. The tests kind of assume a vagrant user.

$lxc_cmd exec ${setup}-maxscale-000 bash <<EOF
dnf -y install openssh-server iptables rsync lsof net-tools
systemctl enable sshd
systemctl start sshd
mkdir /root/.ssh/
echo $(cat ssh_key.pub) > /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/authorized_keys

useradd -m vagrant
usermod -a -G wheel vagrant
mkdir /home/vagrant/.ssh/
echo $(cat ssh_key.pub) > /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

sed -i 's/^%wheel.*/%wheel ALL=(ALL)       NOPASSWD: ALL/' /etc/sudoers
EOF

# Copy the base container, we'll install MariaDB onto it later
$lxc_cmd copy ${setup}-maxscale-000 ${setup}-node-000 || exit 1
$lxc_cmd start ${setup}-node-000 || exit 1

# Build MaxScale, assumes that the source is at ~/MaxScale
$scriptdir/build_maxscale.sh "${setup}-maxscale-000"

# Copy it as the maxscale-001 container
$lxc_cmd copy ${setup}-maxscale-000 ${setup}-maxscale-001 || exit 1
$lxc_cmd start ${setup}-maxscale-001 || exit 1

$lxc_cmd exec ${setup}-node-000 bash <<EOF
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.11
sudo dnf -y install MariaDB-server

# Configure a smaller buffer pool, we don't need a big one for the tests.
# The 20MiB buffer pool should be small enough that the memory usage stays
# reasonable but large enough that things don't grind to a halt.
echo '[mariadb]' > /etc/my.cnf.d/innodb.cnf
echo 'innodb_buffer_pool_size=20971520' >> /etc/my.cnf.d/innodb.cnf
chown mysql:mysql /etc/my.cnf.d/innodb.cnf
EOF

for name in node-00{1..3} galera-00{0..3}
do
    $lxc_cmd copy ${setup}-node-000 ${setup}-$name || exit 1
    $lxc_cmd start ${setup}-$name || exit 1
done

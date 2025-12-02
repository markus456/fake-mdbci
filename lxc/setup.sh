#!/bin/bash

scriptdir=$(dirname $(realpath $0))
. $scriptdir/utils.sh

if ! [ -d "$HOME/vms/" ]
then
    mkdir -p "$HOME/vms/" || exit 1
fi

cd "$HOME/vms/" || exit 1

if [ -z "$1" ]
then
    echo "USAGE: NAME"
    exit 1
fi

if command -v incus > /dev/null
then
    lxc_cmd=incus
else
    lxc_cmd=lxc
fi

setup=$1

# Create a SSH private key if needed
if ! [ -f ssh_key ]
then
    ssh-keygen -q -f ssh_key -N ""
fi

$lxc_cmd launch images:rockylinux/8 ${setup}-maxscale-000

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
$lxc_cmd copy ${setup}-maxscale-000 ${setup}-node-000
$lxc_cmd start ${setup}-node-000

# Build MaxScale, assumes that the source is at ~/MaxScale
$scriptdir/build_maxscale.sh "${setup}-maxscale-000"

# Copy it as the maxscale-001 container
$lxc_cmd copy ${setup}-maxscale-000 ${setup}-maxscale-001
$lxc_cmd start ${setup}-maxscale-001

$lxc_cmd exec ${setup}-node-000 bash <<EOF
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.11
sudo dnf -y install MariaDB-server

# Configure a smaller buffer pool, we don't need a big one for the tests.
# The 20MiB buffer pool should be small enough that the memory usage stays
# reasonable but large enough that things don't grind to a halt.
echo '[mariadb]' > /etc/my.cnf.d/innodb.cnf
echo 'innodb_buffer_pool_size=20971520' >> /etc/my.cnf.d/innodb.cnf
chmod a+rw /etc/my.cnf.d/innodb.cnf
EOF

for name in node-00{1..3} galera-00{0..3}
do
    $lxc_cmd copy ${setup}-node-000 ${setup}-$name
    $lxc_cmd start ${setup}-$name
done

echo "[__anonymous__]" > ${setup}_network_config

for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
do
    wait_for_network ${setup}-$name
    line=$($lxc_cmd ls -f csv ${setup}-$name)
    ip=$(echo $line|cut -f 3 -d ,|sed 's/ .*//')
    confname=$(echo $name|tr '-' '_')
    cat <<EOF >> ${setup}_network_config
${confname}_whoami=vagrant
${confname}_hostname=$name
${confname}_network=$ip
${confname}_keyfile=$PWD/ssh_key
EOF
    cat <<EOF >> ${setup}_ssh_config
Host $confname
  HostName $ip
  User vagrant
  Port 22
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile $PWD/ssh_key
  IdentitiesOnly yes
  LogLevel FATAL

EOF
done

echo "GALERA_BACKEND,MAXSCALE,REPL_BACKEND,SECOND_MAXSCALE" > ${setup}_configured_labels

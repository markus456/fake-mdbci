#!/bin/bash

if [ -z "$1" ]
then
    echo "USAGE: MAXSCALE_CONTAINER"
    exit 1
fi

scriptdir=$(dirname $(realpath $0))
. $scriptdir/utils.sh

# Build MaxScale, assumes that the source is at ~/MaxScale
wait_for_network $1
ip=$($lxc_cmd ls -f csv -c 4 $1|sed 's/ .*//')
rsync -e "ssh -o StrictHostKeyChecking=no -i $HOME/vms/ssh_key" -az $HOME/MaxScale/ root@$ip:/MaxScale/
$lxc_cmd exec $1 bash <<EOF
if ! [ -f /deps-installed.txt ]
then
    /MaxScale/BUILD/install_build_deps.sh
    echo "yes" > /deps-installed.txt
fi

if ! [ -f /maxscale-configured.txt ]
then
    mkdir -p /build
    cd /build

    # Workarounds for some Rocky 8 problems. The testing also requires that Java and
    # the kerberos tools are installed on the MaxScale VM.
    dnf -y install libasan libubsan java-latest-openjdk krb5-workstation
    source /opt/rh/gcc-toolset-11/enable

    git config --global --add safe.directory /MaxScale
    cmake /MaxScale/ -DPACKAGE=Y -DCMAKE_BUILD_TYPE=Debug -DWITH_ASAN=Y -DWITH_UBSAN=Y -DBUILD_TESTS=N
    echo "yes" > /maxscale-configured.txt
fi

cd /build
make -j \$(grep -c processor /proc/cpuinfo) package

# This is some random file that gets created during the build process
# that ends up triggering the core dump detection.
rm -f /tmp/core-js-banners

if rpm -q maxscale
then
    dnf -y reinstall maxscale*.rpm
else
    dnf -y install maxscale*.rpm
fi
EOF

#!/bin/bash

if ! [ -d "$HOME/vms/" ]
then
    mkdir -p "$HOME/vms/" || exit 1
fi

cd "$HOME/vms/" || exit 1


if command -v incus > /dev/null
then
    lxc_cmd=incus
else
    lxc_cmd=lxc
fi

while [ -n "$1" ]
do
    $lxc_cmd delete --force $1-maxscale-00{0,1} $1-node-00{0..3} $1-galera-00{0..3}
    rm  ${1}_network_config ${1}_ssh_config ${1}_configured_labels
    shift
done

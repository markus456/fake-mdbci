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
    for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
    do
        $lxc_cmd delete --force $1-$name
    done

    rm  ${1}_network_config ${1}_ssh_config ${1}_configured_labels
    shift
done

#!/bin/bash
cd $(dirname $(realpath $0)) || exit 1

while [ -n "$1" ]
do
    for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
    do
        incus delete --force $1-$name
    done

    rm  ${1}_network_config ${1}_ssh_config ${1}_configured_labels
    shift
done

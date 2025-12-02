#!/bin/bash

scriptdir=$(dirname $(realpath $0))
. $scriptdir/utils.sh

while [ -n "$1" ]
do
    $lxc_cmd delete --force $1-maxscale-00{0,1} $1-node-00{0..3} $1-galera-00{0..3}
    rm  ${1}_network_config ${1}_ssh_config ${1}_configured_labels
    shift
done

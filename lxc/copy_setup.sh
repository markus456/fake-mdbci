#!/bin/bash

if [ $# -lt 2 ]
then
    echo "USAGE: $0 SRC DST..."
    exit 1
fi

scriptdir=$(dirname $(realpath $0))
. $scriptdir/utils.sh

src=$1
shift

for dst in "$@"
do
    for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
    do
        $lxc_cmd copy $src-$name $dst-$name
        $lxc_cmd start $dst-$name
    done
done

$scriptdir/create_configurations.sh "$@"

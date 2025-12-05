#!/bin/bash

if [ $# -lt 2 ]
then
    echo "This script copies the setup in SRC into DST. The copied setup is"
    echo "a lightweight one which doesn't have Galera servers or the second MaxScale."
    echo
    echo "USAGE: $0 SRC DST..."
    exit 1
fi

scriptdir=$(dirname $(realpath $0))
. $scriptdir/utils.sh

src=$1
shift

for dst in "$@"
do
    for name in maxscale-000 node-00{0..3}
    do
        $lxc_cmd copy $src-$name $dst-$name
        $lxc_cmd start $dst-$name
    done
done

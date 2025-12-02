#!/bin/bash

if [ -z "$1" ]
then
    echo "USAGE: LIST_OF_VMS"
    echo ""
    echo "The first VM in the list is built and the rest are copied from it."
    exit 1
fi

scriptdir=$(dirname $(realpath $0))
$scriptdir/setup.sh $1 || exit 1
$scriptdir/copy_setup.sh $@ || exit 1
$scriptdir/create_configurations.sh $@ || exit 1

#!/bin/bash

scriptdir=$(dirname $(realpath $0))
$scriptdir/setup.sh develop || exit 1
$scriptdir/create_configurations.sh develop || exit 1

#!/bin/bash

if ! [ -d "$HOME/vms/" ]
then
    mkdir -p "$HOME/vms/" || exit 1
fi

cd "$HOME/vms/" || exit 1

function list-envs() {
    for id in $@
    do
        echo "{\"id\":\"$id\"}"
    done
}

cat <<EOF|jq . > resource-spec.json
{
  "version": {
    "major": 1,
    "minor": 0
  },
  "local": [
    {
      "envs": [
        $(list-envs $@|paste -s -d,)
      ]
    }
  ]
}
EOF

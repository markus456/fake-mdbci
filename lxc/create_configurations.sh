#!/bin/bash

. $(dirname $(realpath $0))/utils.sh

for setup in "$@"
do
    echo "[__anonymous__]" > ${setup}_network_config

    for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
    do
        wait_for_network ${setup}-${name}
        line=$($lxc_cmd ls -f csv ${setup}-${name})
        ip=$(echo $line|cut -f 3 -d ,|sed 's/ .*//')
        confname=$(echo ${name}|tr '-' '_')
        cat <<EOF >> ${setup}_network_config
${confname}_whoami=vagrant
${confname}_hostname=${name}
${confname}_network=$ip
${confname}_keyfile=$PWD/ssh_key
EOF
        cat <<EOF >> ${setup}_ssh_config
Host $confname
  HostName $ip
  User vagrant
  Port 22
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile $PWD/ssh_key

EOF
    done

    echo "GALERA_BACKEND,MAXSCALE,REPL_BACKEND,SECOND_MAXSCALE" > ${setup}_configured_labels
done

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
        $(list-envs "$@"|paste -s -d,)
      ]
    }
  ]
}
EOF

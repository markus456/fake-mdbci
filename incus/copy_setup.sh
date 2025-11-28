#!/bin/bash
cd $(dirname $(realpath $0)) || exit 1

src=$1
shift
dst=$1

if [ -z "$src" ] || [ -z "$dst" ]
then
    echo "USAGE: $0 SRC DST..."
    exit 1
fi

while [ -n "$dst" ]
do
    for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
    do
        incus copy $src-$name $dst-$name
        incus start $dst-$name
    done

    setup=$dst
    prefix="$setup-"
    echo "[__anonymous__]" > ${setup}_network_config

    for name in maxscale-00{0,1} node-00{0..3} galera-00{0..3}
    do
        line=$(incus ls -f csv $prefix$name)
        ip=$(echo $line|cut -f 3 -d ,|sed 's/ .*//')

        for ((i=0;i<30;i++))
        do
            if [ -n "$ip" ]
            then
                break
            fi

            echo "Network is not yet up: $line"
            sleep 1
            line=$(incus ls -f csv $prefix$name)
            ip=$(echo $line|cut -f 3 -d ,|sed 's/ .*//')
        done

        confname=$(echo $name|tr '-' '_')
        cat <<EOF >> ${setup}_network_config
${confname}_whoami=vagrant
${confname}_hostname=$name
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
  IdentitiesOnly yes
  LogLevel FATAL

EOF
    done

    echo "GALERA_BACKEND,MAXSCALE,REPL_BACKEND,SECOND_MAXSCALE" > ${setup}_configured_labels
    shift
    dst=$1
done

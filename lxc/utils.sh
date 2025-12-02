if ! [ -d "$HOME/vms/" ]
then
    mkdir -p "$HOME/vms/" || exit 1
fi

cd "$HOME/vms/" || exit 1

if command -v incus > /dev/null
then
    export lxc_cmd=incus
else
    export lxc_cmd=lxc
fi

function wait_for_network() {
    line=$($lxc_cmd ls -f csv $1)
    ip=$(echo $line|cut -f 3 -d ,|sed 's/ .*//')

    for ((i=0;i<30;i++))
    do
        if [ -n "$ip" ]
        then
            break
        fi

        echo "Network for $1 is not yet up"
        sleep 1
        line=$($lxc_cmd ls -f csv $1)
        ip=$(echo $line|cut -f 3 -d ,|sed 's/ .*//')
    done

    echo "Network for $1 is up"
}

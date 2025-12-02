function wait_for_network() {    
    if command -v incus > /dev/null
    then
        lxc_cmd=incus
    else
        lxc_cmd=lxc
    fi

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

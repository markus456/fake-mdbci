# fake-mdbci

Fakes MDBCI with Vagrant and a few scripts.

## Requirements

You need qemu, libvirt, Vagrant and the vagrant-libvirt Vagrant plugin for this to work.

## Usage

- Copy `Vagrantfile` to `~/vms/develop/`.

- Copy `create_network_file.py` to `~/vms/`.

- Run `cd ~/vms/develop/ && vagrant up --provider=libvirt`

- Run `cd ~/vms/ && ./create_network_file.py`

- Run `echo 'GALERA_BACKEND,MAXSCALE,REPL_BACKEND,SECOND_MAXSCALE' > ~/vms/develop_configured_labels`

- Export the config name with `export mdbci_config_name=develop`

- Build tests

- Run a test

**Note:** If you do not have the maxscale_001 VM or the Galera VMs up, do not
  add these into `~/vms/develop_configured_labels`. Otherwise, the test system
  will try to SSH there and it'll fail if they're down.

## Copying Sources From a Local Copy

First, generate the SSH configuration file.

```
cd ~/vms/develop && vagrant ssh-config > ../develop_ssh_config
```

This will produce errors if not all of the VMs are running but these can
be ignored if you don't need them at this moment. When you do need them,
remember to regenerate the config file.

To sync the sources from your local `~/MaxScale/` directory to the first
VMs `~/MaxScale` directory, run the following command.

```
rsync --delete -a --progress -e "ssh -F $HOME/vms/develop_ssh_config" ~/MaxScale/ vagrant@$maxscale_000:~/MaxScale/
```

Here's a bash function that can be called to rsync the source from the
local `~/MaxScale` directory into the `~/MaxScale` directory on an
arbitrary MaxScale VM.

```
function mxs_sync_vm() {
    vm=maxscale_000

    if [ ! -z "$1" ]
    then
        vm=$1
    fi

    rsync --delete -a --progress -e "ssh -F $HOME/vms/develop_ssh_config" ~/MaxScale/ vagrant@${vm}:~/MaxScale/
}
```

# Lightweight Testing with LXD/Incus

LXD and Incus are LXC based systems for creating efficient "VM-like" setups that
can be used for testing MaxScale. These use up less memory than the Vagrant
virtual machines and are a bit faster to start up from scratch. These can also
be used to run tests in parallel if CTest is configured with a resource spec
file.

## Testing with Incus

The `incus/` directory contains scripts that set up a LXC based testing setup using Incus

### Simple Usage

- Copy the contents of the `incus/` directory into `~/vms/`.

- Run `cd ~/vms/ && ./setup.sh develop`.

- Export the config name with `export mdbci_config_name=develop`

- Build tests

- Run a test

### Usage for Parallel Testing

- Copy the contents of the `incus/` directory into `~/vms/`.

- Run `cd ~/vms/ && ./setup.sh vm1` to bring up the first setup.

- Run `./copy_setup.sh vm1 vm2 vm3 vm4` to copy `vm1` into three other setups.

- Run `./create_resource.sh vm1 vm2 vm3 vm4` to create the CTest resource spec file.

- Build tests

- Run tests with `ctest -j --resource-spec-file ~/vms/resource-spec.json`

The parallel testing may consume large amounts of memory due to MariaDB using up a bunch of memory on the system.

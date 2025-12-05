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
rsync --delete -a --progress -e "ssh -F $HOME/vms/develop_ssh_config" ~/MaxScale/ vagrant@maxscale_000:~/MaxScale/
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

The `lxc/` directory contains scripts that set up a LXC based testing setup
using either LXD or Incus.

## Initializing LXD

Follow the instructions for initializing LXD or Incus. The interactive
configuration mode with `sudo lxd init` is a good way to configure the system as
it allows the selection of a `btrfs` storage pool which is a lot faster than the
`dir` storage pool that the `ldx init --minimal` would select. For Ubuntu, LXD
is available via Snap packages. Fedora has Incus in its repositories which is
very similar to LXD with minor differences.

## Simple Usage

- Run `./lxc/setup_for_simple.sh`. This creates the default test
  environment named `develop` for the system tests.

- Build tests

- Run a test

## Usage for Parallel Testing

- Run `./lxc/setup_for_parallel.sh vm1 vm2 vm3 vm4` to bring up four test environments.

- Build tests

- Run tests with `ctest -j 4 --resource-spec-file ~/vms/resource-spec.json --output-on-failure`

The parallel testing may consume large amounts of memory due to MariaDB using up
a bunch of memory on the system. If your system has enough memory and CPU
capacity for tests to not time out, use more test environments.

## Useful LXD commands

```
# Stops a container
lxc stop vm1-maxscale-000

# Starts a stopped container
lxc start vm1-maxscale-000

# Copies a container. Copied containers must be started manually.
lxc copy vm1-maxscale-000 vm1-maxscale-copy
lxc start vm1-maxscale-copy

# Deletes a container. The --force is only needed if the container is running.
lxc delete --force vm1-maxscale-000
```

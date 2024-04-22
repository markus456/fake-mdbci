# fake-mdbci

Fakes MDBCI with Vagrant and a few scripts.

## Usage

- Copy `Vagrantfile` to `~/vms/develop/`.

- Copy `create_network_file.py` to `~/vms/`.

- Run `cd ~/vms/develop/ && vagrant up --no-parallel`

- Run `cd ~/vms/ && ./create_network_file.py`

- Run `echo 'GALERA_BACKEND,MAXSCALE,REPL_BACKEND,SECOND_MAXSCALE' > ~/vms/develop_configured_labels`

- Export the config name with `export mdbci_config_name=develop`

- Build tests

- Run a test

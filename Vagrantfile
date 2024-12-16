# Provisioning script for all nodes
$script = <<-SCRIPT
sudo dnf -y install curl
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.11
sudo dnf -y install MariaDB-server
sudo systemctl disable firewalld
sudo systemctl stop firewalld
SCRIPT

Vagrant.configure(2) do |config|
  #config.vm.network "private_network", type: "dhcp"
  config.vm.boot_timeout = 60

  config.vm.provider :libvirt do |qemu|
    qemu.driver = 'kvm'
    qemu.cpu_mode = 'host-passthrough'
    qemu.cpus = 2
    qemu.memory = 1024
    # Uncomment this if you have a slow disk
    # qemu.disk_driver :cache => 'unsafe'
  end

  config.vm.provision "shell", inline: $script

  config.vm.define 'maxscale_000' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'maxscale'

    box.vm.provider :libvirt do |qemu|
      qemu.driver = 'kvm'
      qemu.cpu_mode = 'host-passthrough'
      qemu.cpus = 8
      qemu.memory = 2048
    end

  end

  config.vm.define 'node_000' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'node-000'
  end

  config.vm.define 'node_001' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'node-001'
  end

  config.vm.define 'node_002' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'node-002'
  end

  config.vm.define 'node_003' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'node-003'
  end

  config.vm.define 'maxscale_001' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'maxscale2'

    box.vm.provider :libvirt do |qemu|
      qemu.driver = 'kvm'
      qemu.cpu_mode = 'host-passthrough'
      qemu.cpus = 8
      qemu.memory = 1536
    end
  end
  
  config.vm.define 'galera_000' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'galera-000'
  end

  config.vm.define 'galera_001' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'galera-001'
  end

  config.vm.define 'galera_002' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'galera-002'
  end

  config.vm.define 'galera_003' do |box|
    box.vm.box = 'generic/rocky8'
    box.vm.hostname = 'galera-003'
  end

end

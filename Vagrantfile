Vagrant.configure("2") do |config|
  
  vm_ips = {
    pem:        "192.168.56.88",
    barman:     "192.168.56.89",
    epas:       "192.168.56.90",
    multiepas:  "192.168.56.92"
  }

  # pem
  config.vm.define "pem" do |pem|
    pem.vm.box               = "bento/almalinux-9.5"
    pem.vm.hostname          = "pem"
    pem.vm.network "private_network", ip: vm_ips[:pem]
    pem.vm.provider :virtualbox do |vb|
      vb.name    = "pem"
      vb.memory  = 2048
      vb.cpus    = 2
    end 
    pem.vm.provision "shell", path: "01-install-pem-db.sh"
    pem.vm.provision "shell", path: "02-install-pem-server.sh"
  end

  # barman
  config.vm.define "barman" do |barman|
    barman.vm.box = "generic/rocky9"
    barman.vm.hostname = "barman"
    barman.vm.network "private_network", ip: vm_ips[:barman]
    barman.vm.provider "virtualbox" do |vb|
      vb.name = "barman"
      vb.cpus = 1
      vb.memory = 1024
    end
    barman.vm.provision "shell", path: "03-install-barman-server.sh"
  end

  # epas
  config.vm.define "epas" do |epas|
    epas.vm.box = "generic/rocky9"
    epas.vm.hostname = "epas"
    epas.vm.network "private_network", ip: vm_ips[:epas]
    epas.vm.provider "virtualbox" do |vb|
      vb.name = "epas"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    instance_port = "5444"

    epas.vm.provision "shell" do |s|
       s.path = "04-install-instances.sh"
       s.args = "--instances #{instance_port}"
    end

    epas.vm.provision "shell" do |s|
       s.path = "05-register-instances-pem.sh"
       s.args = "--instances #{instance_port}"
    end

    epas.vm.provision "shell" do |s|
       s.path = "07-register-instances-barman.sh"
       s.args = "--instances #{instance_port}"
    end

    # epas.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # Host with multiple epas instances
  config.vm.define "multiepas" do |epas|
    epas.vm.box = "generic/rocky9"
    epas.vm.hostname = "multiepas"
    epas.vm.network "private_network", ip: vm_ips[:multiepas]
    epas.vm.provider "virtualbox" do |vb|
      vb.name = "multiepas"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    instance_port = "5432,5436,5440"

    epas.vm.provision "shell" do |s|
       s.path = "04-install-instances.sh"
       s.args = "--instances #{instance_port}"
    end

    epas.vm.provision "shell" do |s|
       s.path = "05-register-instances-pem.sh"
       s.args = "--instances #{instance_port}"
    end

    epas.vm.provision "shell" do |s|
       s.path = "07-register-instances-barman.sh"
       s.args = "--instances #{instance_port}"
    end

    # epas.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # Shared folder
  config.vm.synced_folder ".", "/vagrant"
end

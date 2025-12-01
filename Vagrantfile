Vagrant.configure("2") do |config|
  
  vm_ips = {
    pem:        "192.168.56.88",
    barman:     "192.168.56.89",
    epas:       "192.168.56.90",
    multiepas:  "192.168.56.92",
    efmpg1:     "192.168.56.93",
    efmpg2:     "192.168.56.94",
    efmwit:     "192.168.56.95",
    pgd1pg1:    "192.168.56.97",
    pgd1pg2:    "192.168.56.98",
    pgd1pg3:    "192.168.56.99",
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

  # efmpg1
  config.vm.define "efmpg1" do |efmpg1|
    efmpg1.vm.box = "generic/rocky9"
    efmpg1.vm.hostname = "efmpg1"
    efmpg1.vm.network "private_network", ip: vm_ips[:efmpg1]
    efmpg1.vm.provider "virtualbox" do |vb|
      vb.name = "efmpg1"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    instance_port = "5444"
    vips = "192.168.56.120"

    efmpg1.vm.provision "shell" do |s|
       s.path = "04-install-instances.sh"
       s.args = "--instances #{instance_port}"
    end

    efmpg1.vm.provision "shell" do |s|
       s.path = "05-configure-efm.sh"
       s.args = [ instance_port.to_s, 
                  "primary", 
                  vips.to_s, 
                  "#{vm_ips[:efmpg1]}",
                  "#{vm_ips[:efmpg2]}",
                  "#{vm_ips[:efmwit]}" ]
    end

    efmpg1.vm.provision "shell" do |s|
       s.path = "05-register-instances-pem.sh"
       s.args = "--instances #{instance_port}"
    end

    # efmpg1.vm.provision "shell" do |s|
    #    s.path = "07-register-instances-barman.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # efmpg1.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # efmpg2
  config.vm.define "efmpg2" do |efmpg2|
    efmpg2.vm.box = "generic/rocky9"
    efmpg2.vm.hostname = "efmpg2"
    efmpg2.vm.network "private_network", ip: vm_ips[:efmpg2]
    efmpg2.vm.provider "virtualbox" do |vb|
      vb.name = "efmpg2"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    instance_port = "5444"
    vips = "192.168.56.120"

    efmpg2.vm.provision "shell" do |s|
       s.path = "04-install-instances.sh"
       s.args = "--instances #{instance_port}"
    end

    efmpg2.vm.provision "shell" do |s|
       s.path = "05-configure-efm.sh"
       s.args = [ instance_port.to_s, 
                  "replica", 
                  vips.to_s, 
                  "#{vm_ips[:efmpg1]}",
                  "#{vm_ips[:efmpg2]}",
                  "#{vm_ips[:efmwit]}" ]
    end

    efmpg2.vm.provision "shell" do |s|
       s.path = "05-register-instances-pem.sh"
       s.args = "--instances #{instance_port}"
    end

    # efmpg2.vm.provision "shell" do |s|
    #    s.path = "07-register-instances-barman.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # efmpg2.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # efmwit
  config.vm.define "efmwit" do |efmwit|
    efmwit.vm.box = "generic/rocky9"
    efmwit.vm.hostname = "efmwit"
    efmwit.vm.network "private_network", ip: vm_ips[:efmwit]
    efmwit.vm.provider "virtualbox" do |vb|
      vb.name = "efmwit"
      vb.cpus = 1
      vb.memory = 1024
    end
  
    instance_port = "5444"
    vips = "192.168.56.120"

    efmwit.vm.provision "shell" do |s|
       s.path = "05-configure-efm.sh"
       s.args = [ instance_port.to_s, 
                  "witness", 
                  vips.to_s, 
                  "#{vm_ips[:efmpg1]}",
                  "#{vm_ips[:efmpg2]}",
                  "#{vm_ips[:efmwit]}" ]
    end
  end

  # pgd1pg1
  config.vm.define "pgd1pg1" do |pgd1pg1|
    pgd1pg1.vm.box = "generic/rocky9"
    pgd1pg1.vm.hostname = "pgd1pg1"
    pgd1pg1.vm.network "private_network", ip: vm_ips[:pgd1pg1]
    pgd1pg1.vm.provider "virtualbox" do |vb|
      vb.name = "pgd1pg1"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    pgd1pg1.vm.provision "shell" do |s|
       s.path = "05-install-pgd.sh"
       s.args = [ 5444, 
                  "leader",  
                  "#{vm_ips[:pgd1pg1]}",
                  "#{vm_ips[:pgd1pg2]}",
                  "#{vm_ips[:pgd1pg3]}" ]
    end

    pgd1pg1.vm.provision "shell", inline: <<-SHELL
      sudo -i -u enterprisedb bash /vagrant/05-launch-pgd.sh 5444 leader #{vm_ips[:pgd1pg1]} #{vm_ips[:pgd1pg2]} #{vm_ips[:pgd1pgwit]}
    SHELL

    # pgd1pg1.vm.provision "shell" do |s|
    #    s.path = "05-register-instances-pem.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # pgd1pg1.vm.provision "shell" do |s|
    #    s.path = "07-register-instances-barman.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # pgd1pg1.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # pgd1pg2
  config.vm.define "pgd1pg2" do |pgd1pg2|
    pgd1pg2.vm.box = "generic/rocky9"
    pgd1pg2.vm.hostname = "pgd1pg2"
    pgd1pg2.vm.network "private_network", ip: vm_ips[:pgd1pg2]
    pgd1pg2.vm.provider "virtualbox" do |vb|
      vb.name = "pgd1pg2"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    pgd1pg2.vm.provision "shell" do |s|
    s.path = "05-install-pgd.sh"
    s.args = [ 5444, 
              "follower",  
              "#{vm_ips[:pgd1pg1]}",
              "#{vm_ips[:pgd1pg2]}",
              "#{vm_ips[:pgd1pg3]}" ]
    end

    pgd1pg2.vm.provision "shell", inline: <<-SHELL
      sudo -i -u enterprisedb bash /vagrant/05-launch-pgd.sh 5444 follower #{vm_ips[:pgd1pg1]} #{vm_ips[:pgd1pg2]} #{vm_ips[:pgd1pgwit]}
    SHELL

    # pgd1pg2.vm.provision "shell" do |s|
    #    s.path = "05-register-instances-pem.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # pgd1pg2.vm.provision "shell" do |s|
    #    s.path = "07-register-instances-barman.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # pgd1pg2.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # pgd1pg3
  config.vm.define "pgd1pg3" do |pgd1pg3|
    pgd1pg3.vm.box = "generic/rocky9"
    pgd1pg3.vm.hostname = "pgd1pg3"
    pgd1pg3.vm.network "private_network", ip: vm_ips[:pgd1pg3]
    pgd1pg3.vm.provider "virtualbox" do |vb|
      vb.name = "pgd1pg3"
      vb.cpus = 2
      vb.memory = 2048
    end
    
    pgd1pg3.vm.provision "shell" do |s|
      s.path = "05-install-pgd.sh"
      s.args = [ 5444, 
                "follower",  
                "#{vm_ips[:pgd1pg1]}",
                "#{vm_ips[:pgd1pg2]}",
                "#{vm_ips[:pgd1pg3]}" ]
    end

    pgd1pg3.vm.provision "shell", inline: <<-SHELL
      sudo -i -u enterprisedb bash /vagrant/05-launch-pgd.sh 5444 follower #{vm_ips[:pgd1pg1]} #{vm_ips[:pgd1pg2]} #{vm_ips[:pgd1pgwit]}
    SHELL

    # pgd1pg3.vm.provision "shell" do |s|
    #    s.path = "05-register-instances-pem.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # pgd1pg3.vm.provision "shell" do |s|
    #    s.path = "07-register-instances-barman.sh"
    #    s.args = "--instances #{instance_port}"
    # end

    # pgd1pg3.trigger.before :destroy do |trigger|
    #   trigger.run_remote = { inline: "bash /vagrant/06-unregister-instances-pem.sh --instances #{instance_port}" }
    # end
  end

  # Shared folder
  config.vm.synced_folder ".", "/vagrant"
end

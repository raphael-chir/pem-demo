Vagrant.configure("2") do |config|

  # pem
  config.vm.define "pem10" do |pem|
    pem.vm.box               = "bento/almalinux-9.5"
    pem.vm.hostname          = "pem10"
    pem.vm.network "private_network", ip: "192.168.56.88"
    pem.vm.provider :virtualbox do |vb|
      vb.name    = "pem10"
      vb.memory  = 2048
      vb.cpus    = 2
    end 
    pem.vm.provision "shell", path: "01-install-pem-db.sh"
    pem.vm.provision "shell", path: "02-install-pem-server.sh"
  end

  config.vm.define "epas" do |epas|
    epas.vm.box = "generic/rocky9"
    epas.vm.hostname = "epas"
    epas.vm.network "private_network", ip: "192.168.56.90"
    epas.vm.provider "virtualbox" do |vb|
      vb.cpus = 2
      vb.memory = 2048
    end
    epas.vm.provision "shell", path: "03-install-managed-epas.sh"
    epas.vm.provision "shell", path: "04-install-pem-agent-epas.sh"

    epas.trigger.before :destroy do |trigger|
      trigger.run_remote = { inline: "/vagrant/05-unregister-pem-agent-epas.sh" }
    end
  end

  # Shared folder
  config.vm.synced_folder ".", "/vagrant"
end

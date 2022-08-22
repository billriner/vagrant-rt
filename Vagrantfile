# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Use Oracle Linux 8
  config.vm.box = "oraclelinux/8"

  # Box URL
  config.vm.box_url = "https://oracle.github.io/vagrant-projects/boxes/oraclelinux/8.json"

  # Hostname
  config.vm.hostname = "rt.csb.vanderbilt.edu"

  # Networking -----------------------------------------------------------------

  # Public network (1508 VLAN - MRB3 - 10.2.188.201)
  config.vm.network "public_network"
  #config.vm.network "public_network", :bridge => 'en0: Ethernet', :mac => "525400b4c538"

  # Provider-specific configuration --------------------------------------------
  config.vm.provider "virtualbox" do |vb|

    # Name in the VirtualBox GUI
    vb.name = "Request Tracker"

    # Number of CPUs
    vb.cpus = 1 
  
    # Customize the amount of memory on the VM:
    vb.memory = "1024"

    # NIC type
    vb.default_nic_type = "virtio"

    # VBoxManage customizations

    # CPU execution cap
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    # Description
    vb.customize ["modifyvm", :id, "--description", ""]

  end
 
  # Provisioning with shell scripts --------------------------------------------
  config.vm.provision "shell", path: "provision.sh"
  #config.vm.provision "shell", path: "nis.sh"
  config.vm.provision "shell", path: "rt.sh"

end

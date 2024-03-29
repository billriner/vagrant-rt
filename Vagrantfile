# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Use Oracle Linux 8
  config.vm.box = "oraclelinux/8"

  # Box URL
  config.vm.box_url = "https://oracle.github.io/vagrant-projects/boxes/oraclelinux/8.json"

  # Hostname
  config.vm.hostname = "support.csb.vanderbilt.edu"

  # Networking -----------------------------------------------------------------

  # IP address
  # 52-54-00-b4-c5-38 is assigned to 10.2.188.31
  config.vm.network "public_network", bridge: "br0", ip: "10.2.188.31", mac: "525400b4c538"
  #config.vm.network "public_network", :bridge => 'br0', ip: "10.2.188.31", mac: "525400b4c538"
  
  # Port forwarding
  config.vm.network "forwarded_port", guest: 80, host: 8075

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
    vb.customize ["modifyvm", :id, "--description", "Request Tracker"]

  end
 
  # Provisioning with shell scripts --------------------------------------------

  # Allow logins using passwords
  config.vm.provision "shell",
  run: "always",
  inline: "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
           systemctl restart sshd"

  # Fix default gateway
  config.vm.provision "shell",
  run: "always",
  inline: "ip route del default via 10.0.2.2; \
           ip route add default via 10.2.188.1"

  # General provisioning
  config.vm.provision "shell", path: "provision.sh"

  # Install and configure RT
  #config.vm.provision "shell", path: "rt.sh"

  # Prompt to set the root password
  config.vm.provision "shell",
  run: "always",
  inline: "echo 'Log in and set the root password.'"

end

# vagrant-rt
Vagrantfile and provisioning scripts to set up Request Tracker

Instructions:

Open port 8075/tcp on the virtual host (virt2)
  - ```firewall-cmd --permanent --add-port=8075/tcp```
  - ```firewall-cmd --reload```

Bring up the VM
1. ```git clone https://github.com/billriner/vagrant-rt.git```
2. ```cd vagrant-rt/```
3. ```vagrant up```
4. Set the root password in the VM
  - ```vagrant ssh```
  - ```sudo su -```
  - ```passwd```
5. Add the VUDS resource account password to /opt/rt5/etc/RT_SiteConfig.pm
6. Restart the web server
  - ```systemctl restart nginx```
7. Access the web interface at http://virt2.csb.vanderbilt.edu:8075

Create a Vagrant box from once the VM is configured:

1. Make the image as small as possible.
- Clean the yum or dnf cache
  - ```dnf clean all```
- Clear the bash history
  - ```history -c```
- Remove unnecessary packages
  - Fill the virtual hard drive with zeros and delete the zero-filled file.  Don't do this with a dynamically-sized disk.
  - ```dd if=/dev/zero of=/EMPTY bs=1M && rm -f /EMPTY```
2. ```vagrant package --output new.box```
3. Sign up for a Vagrant Cloud account at https://app.vagrantup.com/account/new.
4. Go to the 'Create a new Vagrant Box' page and follow the steps.

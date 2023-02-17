# vagrant-rt
Vagrantfile and provisioning scripts to set up Request Tracker

Instructions:

1. git clone https://github.com/billriner/vagrant-rt.git
2. cd vagrant-rt/
3. vagrant up

Create a Box from an Existing Vagrant Environment

1. vagrant init original_box
2. vagrant up
3. vagrant ssh
4. Install and configure software including guest extensions.
5. Make the image as small as possible.
- Clean the yum or dnf cache
  - dnf clean all
- Clear the bash history
  - history -c
- Remove unnecessary packages
  - Fill the virtual hard drive with zeros and delete the zero-filled file.  Don't do this with a dynamically-sized disk.
  - dd if=/dev/zero of=/EMPTY bs=1M && rm -f /EMPTY
6. vagrant package --output new.box
7. Upload the new box to Vagrant Cloud (See instructions below)

Make the Box Available on Vagrant Cloud:

1. Sign up for a Vagrant Cloud account at https://app.vagrantup.com/account/new.
2. Go to the 'Create a new Vagrant Box' page and follow the steps.

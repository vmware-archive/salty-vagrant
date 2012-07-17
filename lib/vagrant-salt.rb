require "vagrant"
require "vagrant-salt/provisioner"

Vagrant.provisioners.register(:salt) { VagrantSalt::Provisioner }
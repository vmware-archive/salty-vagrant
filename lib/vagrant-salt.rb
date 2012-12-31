require "vagrant"
require_relative "vagrant-salt/provisioner"

Vagrant.provisioners.register(:salt) { VagrantSalt::Provisioner }

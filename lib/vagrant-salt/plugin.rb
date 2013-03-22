begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Salt plugin must be run within Vagrant."
end

if Vagrant::VERSION < "1.1.0"
  raise "This version of Vagrant Salt is only compatible with Vagrant 1.1+"
end

module VagrantPlugins
  module Salt
    class Plugin < Vagrant.plugin("2")
      name "salt"
      description <<-DESC
      Provisions virtual machines using SaltStack
      DESC

      config(:salt, :provisioner) do
        require_relative "config"
        Config
      end

      provisioner(:salt)   do
        require_relative "provisioner"
        Provisioner
      end

    end
  end
end